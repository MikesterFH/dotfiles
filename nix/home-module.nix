# home-manager module: these dotfiles the Nix way, see docs/adr/0021-nix-home-manager-module.md.
# Applications come from home/.chezmoidata/applications.toml (their `nix` field,
# ADR 0023), packages from nixpkgs instead of mise/apt/brew; static configs are
# linked from home/, templates (*.tmpl) are rendered at build time by
# `chezmoi execute-template` with the data `chezmoi init` would produce for the
# Profile. chezmoi never runs on the host.
{ self, hunk, yazi-plugins, nixpkgs-unstable }:
{ config, lib, pkgs, ... }:
let
  cfg  = config.dotfiles;
  home = "${self}/home";
  set  = cfg.packageSet;
  host = set.stdenv.hostPlatform;

  # nixpkgs has no LTS marker. Node's LTS lines are the even majors, so take the
  # highest even `nodejs_NN` the package set ships (mise's `node = "lts"`).
  # Between an even major's April release and its LTS promotion in October this
  # picks a not-yet-LTS release; set `dotfiles.nodejs` to override.
  nodeLtsAttr = lib.last (lib.sort (a: b: a < b) (map (n: lib.toInt (lib.removePrefix "nodejs_" n))
    (lib.filter (n: builtins.match "nodejs_[0-9]*[02468]" n != null) (builtins.attrNames set))));
  newestNodeLts = set."nodejs_${toString nodeLtsAttr}";

  # The Profile's Applications with a `nix` field, mapped to packages. A wrong
  # attribute, flake input or module option fails evaluation; a package whose
  # platforms exclude the host (aerospace off macOS) is skipped.
  applications = lib.filter (a: a ? nix && lib.elem cfg.profile a.profiles)
    (builtins.fromTOML (builtins.readFile "${home}/.chezmoidata/applications.toml")).application;

  flakeInputs = { inherit hunk; };
  # Options that install an Application themselves; the package list adds nothing for them.
  moduleOptions = {
    "dotfiles.nodejs" = [ cfg.nodejs ];
    "programs.neovim" = [ ];
  };

  attrPackage = name: attr:
    lib.attrByPath (lib.splitString "." attr)
      (throw "applications.toml: ${name}: nix attribute `${attr}` not in the package set")
      set;
  packagesOf = a:
    if builtins.isString a.nix then [ (attrPackage a.name a.nix) ]
    else if builtins.isList a.nix then map (attrPackage a.name) a.nix
    else if a.nix ? flake then
      let input = flakeInputs.${a.nix.flake} or (throw "applications.toml: ${a.name}: no flake input `${a.nix.flake}`");
      in lib.optional (input.packages ? ${host.system}) input.packages.${host.system}.default
    else if a.nix ? module then
      moduleOptions.${a.nix.module} or (throw "applications.toml: ${a.name}: no module option `${a.nix.module}`")
    else throw "applications.toml: ${a.name}: unknown nix value";

  installs = name: lib.any (a: a.name == name) applications;

  identity = lib.types.submodule {
    options = {
      name  = lib.mkOption { type = lib.types.str; description = "git user.name"; };
      email = lib.mkOption { type = lib.types.str; description = "git user.email"; };
    };
  };

  # Mirrors .chezmoi.toml.tmpl. The Application list is not part of it: it
  # lives in home/.chezmoidata/applications.toml, which chezmoi reads itself.
  chezmoiConfig = pkgs.writeText "chezmoi.json" (builtins.toJSON {
    data = {
      inherit (cfg) profile;
      devpod = false;
      git = { inherit (cfg.git) work personal; };
    };
  });

  render = name: tmpl: pkgs.runCommand name { nativeBuildInputs = [ pkgs.chezmoi ]; } ''
    export HOME="$TMPDIR"
    chezmoi execute-template --source ${self} --config ${chezmoiConfig} \
      < ${home}/${tmpl} > $out
  '';

  # Global git hooks: chezmoi strips the `executable_` prefix and sets +x.
  gitHooks = pkgs.runCommand "dotfiles-git-hooks" { } ''
    mkdir -p $out
    for f in ${home}/dot_config/git/hooks/executable_*; do
      install -m 0755 "$f" "$out/$(basename "$f" | sed 's/^executable_//')"
    done
  '';
in {
  options.dotfiles = {
    enable  = lib.mkEnableOption "these dotfiles, installed the Nix way";
    profile = lib.mkOption {
      type        = lib.types.enum [ "personal" "dev-server" ];
      default     = "dev-server";
      description = "Machine Profile as in .chezmoi.toml.tmpl; decides which git identities exist.";
    };
    packageSet = lib.mkOption {
      type        = lib.types.pkgs;
      default     = import nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; inherit (pkgs) config; };
      defaultText = lib.literalExpression "the flake's nixpkgs-unstable input, with the consumer's nixpkgs config";
      example     = lib.literalExpression "pkgs";
      description = ''
        Package set every Application comes from. Defaults to nixpkgs-unstable (close to
        the upstream releases mise installs elsewhere, ADR 0023); pass `pkgs` to use the
        system's nixpkgs instead. The consumer's nixpkgs config (allowUnfree for vscode)
        carries over to the default.
      '';
    };
    nodejs  = lib.mkOption {
      type        = lib.types.package;
      default     = newestNodeLts;
      defaultText = lib.literalExpression "highest even-numbered nodejs_NN in dotfiles.packageSet";
      description = "Node runtime; defaults to the newest LTS line nixpkgs ships, like mise's `node = \"lts\"`.";
    };
    git.work     = lib.mkOption { type = identity; description = "Work identity (every Profile)."; };
    git.personal = lib.mkOption { type = identity; description = "Personal identity."; };
  };

  config = lib.mkIf cfg.enable {
    # git is a Bootstrap Package, not an Application.
    home.packages = lib.filter (lib.meta.availableOn host) (lib.concatMap packagesOf applications)
      ++ [ set.git ];

    programs.neovim = {
      enable      = installs "neovim";
      package     = set.neovim-unwrapped;
      # Pre-26.05 defaults kept explicitly: plugins use the Ruby/Python providers.
      withRuby    = true;
      withPython3 = true;
    };

    # The bashrc inits starship/zoxide/mise itself.
    programs.bash = {
      enable    = true;
      initExtra = builtins.readFile "${home}/dot_bashrc";
    };

    home.file = {
      ".bash_aliases".source                       = "${home}/dot_bash_aliases";
      ".config/starship.toml".source               = "${home}/dot_config/starship.toml";
      ".config/nvim".source                        = "${home}/dot_config/nvim";
      # File only: tpm installs plugins/ next to it.
      ".config/tmux/tmux.conf".source              = "${home}/dot_config/tmux/tmux.conf";
      ".config/yazi/init.lua".source               = "${home}/dot_config/yazi/init.lua";
      ".config/yazi/yazi.toml".source              = "${home}/dot_config/yazi/yazi.toml";
      ".config/yazi/package.toml".source           = "${home}/dot_config/yazi/package.toml";
      ".config/yazi/plugins/gitbranch.yazi".source = "${home}/dot_config/yazi/plugins/gitbranch.yazi";
      # package.toml's plugin.deps, pinned via the yazi-plugins flake input instead of `ya pkg install`
      ".config/yazi/plugins/git.yazi".source       = "${yazi-plugins}/git.yazi";
      ".config/yazi/plugins/piper.yazi".source     = "${yazi-plugins}/piper.yazi";
      ".config/hunk/config.toml".source            = "${home}/dot_config/hunk/config.toml";
      ".config/helix/config.toml".source           = render "helix-config.toml" "dot_config/helix/config.toml.tmpl";
      ".config/helix/languages.toml".source        = render "helix-languages.toml" "dot_config/helix/languages.toml.tmpl";
      ".config/git/config".source                  = render "git-config" "dot_config/git/config.tmpl";
      ".config/git/config.local.work".source       = render "git-config-work" "dot_config/git/config.local.work.tmpl";
      ".config/git/config.local.personal".source   = render "git-config-personal" "dot_config/git/config.local.personal.tmpl";
      ".config/git/hooks".source                   = gitHooks;
    };
  };
}
