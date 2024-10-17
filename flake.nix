{
  description = "A flake that exposes a home-manager module for textfox";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nur.url = github:nix-community/NUR;
  };

  outputs = { self, nixpkgs, nur } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "x86_64-darwin"];
    pkgsForEach = nixpkgs.legacyPackages;
  in {
    packages = forAllSystems (system: {
      default = pkgsForEach.${system}.callPackage ./nix/default.nix {};
    });

    homeManagerModules.default = import ./nix/hm-module.nix inputs;
  };
}
