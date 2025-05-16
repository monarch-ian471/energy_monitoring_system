nix
{
  description = "A development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    devShells.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # Or your system's architecture
      modules = [
        {
          imports = [
            ./.idx/dev.nix
          ];
        }
      ];
    };
  };
}