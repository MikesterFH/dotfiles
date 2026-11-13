# Minimal home-manager consumer of the module, one configuration per supported
# Profile. CI builds both against the checkout (`--override-input dotfiles
# path:$PWD`), so a wrong `nix` attribute in applications.toml or a broken
# template fails here before it reaches a NixOS host.
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

  outputs = { dotfiles, nixpkgs, home-manager, ... }:
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
    };
}
