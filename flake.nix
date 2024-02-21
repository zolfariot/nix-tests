{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:zolfariot/nixpkgs?ref=zolfa-test";
    disko.url = "github:zolfariot/disko?ref=feature/clevisPin";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko }: {
    nixosConfigurations.fr-par2 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        disko.nixosModules.disko
        ./raspi-fde/disk-config.nix
        ./raspi-fde/hardware-configuration.nix
        ./configuration.nix
      ];
    };
  };
}
