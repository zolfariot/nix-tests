{ config, ... }: {
  imports = [
    ../system/k3s.nix
  ];

  sops.secrets.k3s-token = {
    sopsFile = ../secrets/k3s-eu-south-1.yaml;
  };

  services.k3s = {
    clusterInit = true;
    tokenFile = "/run/secrets/k3s-token";
    extraFlags = toString [
      "--tls-san=${config.networking.hostName}.zolfa.nl"
      "--tls-san=eu-south-1.zolfa.nl"
    ];
  };
}