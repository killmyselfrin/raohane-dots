{
  description = "Raohane desktop shell for Hyprland, packaged for NixOS and Home Manager";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = function: lib.genAttrs systems (system: function nixpkgs.legacyPackages.${system});
      nixosModule = import ./nix/nixos-module.nix { inherit self; };
      homeModule = import ./nix/home-module.nix { inherit self; };
    in
    {
      packages = forAllSystems (pkgs:
        let package = pkgs.callPackage ./nix/package.nix { };
        in {
          default = package;
          raohane = package;
        });

      nixosModules = {
        default = nixosModule;
        raohane = nixosModule;
      };

      homeModules = {
        default = homeModule;
        raohane = homeModule;
      };

      homeManagerModules = {
        default = homeModule;
        raohane = homeModule;
      };
      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
