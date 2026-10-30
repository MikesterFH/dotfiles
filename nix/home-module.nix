# home-manager module: these dotfiles the Nix way, see docs/adr/0021-nix-home-manager-module.md.
# Tools come from nixpkgs instead of mise/apt/brew; static configs are linked from
# home/, templates (*.tmpl) are rendered at build time by `chezmoi execute-template`
# with the data `chezmoi init` would produce for the Profile. chezmoi never runs on
# the host.
#
# Keep the package list below in sync with `$cliTools` in home/.chezmoi.toml.tmpl
# and the node/python runtimes in home/dot_config/mise/config.toml.tmpl.
{ self, hunk, yazi-plugins, nixpkgs-unstable }:
{ config, lib, pkgs, ... }:
let
  cfg  = config.dotfiles;
  home = "${self}/home";

  # nixpkgs has no LTS marker. Node's LTS lines are the even majors, so take the
  # highest even `nodejs_NN` the consumer's nixpkgs ships (mise's `node = "lts"`).
  # Between an even major's April release and its LTS promotion in October this
  # picks a not-yet-LTS release; set `dotfiles.nodejs` to override.
  nodeLtsAttr = lib.last (lib.sort (a: b: a < b) (map (n: lib.toInt (lib.removePrefix "nodejs_" n))
    (lib.filter (n: builtins.match "nodejs_[0-9]*[02468]" n != null) (builtins.attrNames pkgs))));
  newestNodeLts = pkgs."nodejs_${toString nodeLtsAttr}";

  identity = lib.types.submodule {
    options = {
      name  = lib.mkOption { type = lib.types.str; description = "git user.name"; };
      email = lib.mkOption { type = lib.types.str; description = "git user.email"; };
    };
  };

  # Mirrors .chezmoi.toml.tmpl. `applications` is only read by templates this
  # module does not render, so it stays empty.
  chezmoiConfig = pkgs.writeText "chezmoi.json" (builtins.toJSON {
    data = {
      inherit (cfg) profile;
      devpod       = false;
      applications = [ ];
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
    nodejs  = lib.mkOption {
      type        = lib.types.package;
      default     = newestNodeLts;
      defaultText = lib.literalExpression "highest even-numbered pkgs.nodejs_NN";
      description = "Node runtime; defaults to the newest LTS line nixpkgs ships, like mise's `node = \"lts\"`.";
    };
    git.work     = lib.mkOption { type = identity; description = "Work identity (every Profile)."; };
    git.personal = lib.mkOption { type = identity; description = "Personal identity."; };
  };

  config = lib.mkIf cfg.enable {
    # CLI-tool Applications plus mise's node/python runtimes. neovim comes from
    # programs.neovim below. hunk is not in nixpkgs, it comes from its own flake.
    home.packages = with pkgs; [
      delta starship tmux fzf zoxide glow bat lazygit tree-sitter ripgrep fd
      unzip cmake gnumake gcc eza zsh file p7zip imagemagick poppler-utils resvg
      jq ffmpeg uv helix mermaid-cli git
      python313
    ] ++ [
      cfg.nodejs
      hunk.packages.${pkgs.stdenv.hostPlatform.system}.default
      # package.toml's plugins require a newer yazi than stable nixpkgs has
      nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.yazi
    ];

    programs.neovim = {
      enable      = true;
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
