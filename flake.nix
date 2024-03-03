{
  description = "ZNet Infra Flake";

  inputs = {
    nixpkgs.url = "github:zolfariot/nixpkgs?ref=znet";
    disko.url = "github:zolfariot/disko?ref=feature/clevisPin";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko }: {
    # Raspberry Pi 4
    nixosConfigurations.znet-fr-par2 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        disko.nixosModules.disko
        ./raspi-fde
        ./common-configuration.nix
        {
          networking.hostName = "znet-fr-par2";
          systemd.network.networks."10-lan" = {
            matchConfig.Name = "enp1s0";
            networkConfig.DHCP = "yes";
          };
        }
      ];
    };
    # VPS || Nurnberg (Germany) || Prager-IT
    nixosConfigurations.znet-de-nue1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./prager-vps
        ./common-configuration.nix
        {
          networking.hostName = "znet-de-nue1";
          systemd.network.networks."10-lan" = {
            matchConfig.Name = "ens18";
            networkConfig.Gateway = "212.46.59.1";
            networkConfig.DNS = [ "212.46.59.1" "1.1.1.1" ];
            addresses = [
              { addressConfig.Address = "212.46.59.59/32"; addressConfig.Peer = "212.46.59.1/32"; }
            ];
          };
        }
      ];
    };
  };
}
