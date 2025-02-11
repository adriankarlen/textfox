{
  description = "Firefox theme for the tui enthusiast";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, nur } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    pkgsForEach = nixpkgs.legacyPackages;
  in {
    packages = forAllSystems (system: {
      default = pkgsForEach.${system}.callPackage ./nix/pkgs/default.nix {};
      wrapTextfox = pkgsForEach.${system}.callPackage ./nix/pkgs/wrapTextfox.nix {};
    });

    nixosModules.default = self.nixosModules.textfox; # convention
    nixosModules.textfox = import ./nix/modules/nixos.nix inputs;

    homeManagerModules.default = self.homeManagerModules.textfox; 
    homeManagerModules.textfox = import ./nix/modules/home-manager.nix inputs;
  };
}
