{ config, pkgs, lib, ... }:
let
  metadata = pkgs.callPackage ../utils/metadata.nix {};
  clusterFather = metadata.hosts."znet-it-mil1".ipv4.addr;
  clusterFatherIP = lib.head (lib.strings.splitString "/" clusterFather);
in
{
  imports = [
    ../system/k3s.nix
  ];

  sops.secrets.k3s-token = {
    sopsFile = ../secrets/k3s-eu-south-1.yaml;
  };

  services.k3s = {
    tokenFile = "/run/secrets/k3s-token";
    serverAddr = "https://${clusterFatherIP}:6443";
    extraFlags = toString [
      "--tls-san=${config.networking.hostName}.zolfa.nl"
      "--tls-san=eu-south-1.zolfa.nl"
    ];
  };
}