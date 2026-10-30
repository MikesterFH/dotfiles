{
  description = "Dotfiles: chezmoi source repo, plus a home-manager module that installs the same tools and configs the Nix way";

  # The module takes `pkgs` from the consuming home-manager config; the inputs are hunk
  # (not in nixpkgs), the yazi plugins and a newer yazi. Nothing outside home/ is deployed by chezmoi, so
  # this file and nix/ never reach $HOME.
  inputs.hunk.url = "github:modem-dev/hunk";
  # yazi plugins from package.toml (`ya pkg install` never runs on Nix). Keep the rev
  # equal to the one in home/dot_config/yazi/package.toml.
  inputs.yazi-plugins = {
    url   = "github:yazi-rs/plugins/9166202cc1694c98bac3a639874d6f4c0eaa2dab";
    flake = false;
  };

  # yazi only: the plugins above need a newer yazi than a stable nixpkgs release ships
  # (mise installs the latest). Drop this once the consumer's stable nixpkgs catches up.
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, hunk, yazi-plugins, nixpkgs-unstable }: {
    homeManagerModules.default = import ./nix/home-module.nix { inherit self hunk yazi-plugins nixpkgs-unstable; };
  };
}
