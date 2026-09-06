# NixOS and Home Manager

Raohane exposes both NixOS and Home Manager modules. The NixOS module enables the system services and package set; Home Manager installs the immutable runtime, seeds mutable native settings and owns the user service.

```nix
{
  inputs.raohane.url = "github:killmyselfrin/raohane-dots";

  outputs = { nixpkgs, home-manager, raohane, ... }: {
    nixosConfigurations.yourHost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        raohane.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          programs.raohane.enable = true;
          home-manager.users.yourName = {
            imports = [ raohane.homeModules.default ];
            programs.raohane.enable = true;
          };
        }
      ];
    };
  };
}
```

Merge this fragment into an existing flake with `nixpkgs` and `home-manager` inputs. Replace the example host and user names. See the [module definitions](../nix/) for available options.
