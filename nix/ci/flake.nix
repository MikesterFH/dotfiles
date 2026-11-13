# Minimal home-manager consumer of the module, one configuration per supported
# Profile. CI builds both against the checkout (`--override-input dotfiles
# path:$PWD`), so a wrong `nix` attribute in applications.toml or a broken
# template fails here before it reaches a NixOS host. `versions` feeds the
# drift report (.github/scripts/drift-report.sh).
{
  inputs = {
    dotfiles.url = "github:MikesterFH/dotfiles";
    # The module's default package set is nixpkgs-unstable; home-manager follows it.
    nixpkgs.follows = "dotfiles/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, dotfiles, nixpkgs, home-manager, ... }:
    let
      consumer = profile: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
        modules = [
          dotfiles.homeManagerModules.default
          {
            home = { username = "ci"; homeDirectory = "/home/ci"; stateVersion = "26.05"; };
            dotfiles = {
              enable = true;
              inherit profile;
              git.work     = { name = "CI Work"; email = "work@example.com"; };
              git.personal = { name = "CI Personal"; email = "personal@example.com"; };
            };
          }
        ];
      };
    in {
      homeConfigurations = {
        personal     = consumer "personal";
        dev-server   = consumer "dev-server";
      };

      # Application name → version the module installs (null: no version to
      # compare). personal has every Application dev-server has.
      versions =
        let
          inherit (nixpkgs) lib;
          cfg    = self.homeConfigurations.personal.config;
          set    = cfg.dotfiles.packageSet;
          system = set.stdenv.hostPlatform.system;
          moduleVersions = {
            "dotfiles.nodejs" = cfg.dotfiles.nodejs.version;
            "programs.neovim" = cfg.programs.neovim.package.version;
          };
          versionOf = a:
            if builtins.isString a.nix then (lib.attrByPath (lib.splitString "." a.nix) { } set).version or null
            else if builtins.isAttrs a.nix && a.nix ? flake then dotfiles.inputs.${a.nix.flake}.packages.${system}.default.version or null
            else if builtins.isAttrs a.nix && a.nix ? module then moduleVersions.${a.nix.module} or null
            else null;
          apps = (builtins.fromTOML (builtins.readFile "${dotfiles}/home/.chezmoidata/applications.toml")).application;
        in lib.listToAttrs (map (a: lib.nameValuePair a.name (versionOf a)) (lib.filter (a: a ? nix) apps));
    };
}
