{
  description = "ZNet Infra Flake";

  inputs = {
    nixpkgs.url = "github:zolfariot/nixpkgs?ref=znet";
    disko.url = "github:zolfariot/disko?ref=feature/clevisPin";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko }:
  let
    metadata = builtins.fromTOML (builtins.readFile ./hosts.toml);
    hosts = metadata.hosts;
    mkNixosConf = hostName:
      let
        host = hosts."${hostName}";
      in nixpkgs.lib.nixosSystem {
        system = host.aarch;
        modules = [
          { networking.hostName = hostName; }
          disko.nixosModules.disko
          (./disk-config + "/${hostName}.nix")
          (./hardware + "/${host.hardware}.nix")
          ./system/networking.nix
          ./system/common.nix
        ] ++ nixpkgs.lib.lists.optional
          (builtins.pathExists (./service-config + "/${hostName}.nix"))
          (./service-config + "/${hostName}.nix");
      };
  in {
    nixosConfigurations = builtins.listToAttrs (
      map (name: { name = name; value = mkNixosConf name; }) [
        "znet-de-nue1"
        "znet-de-dus1"
        "znet-it-mil1"
      ]
    );
  };
}
