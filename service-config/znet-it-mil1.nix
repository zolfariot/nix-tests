{ config, ... }: {
  imports = [
    ../system/k3s.nix
  ];

  sops.secrets.k3s-token = {
    sopsFile = ../secrets/k3s-eu-south-1.yaml;
  };

  networking.firewall.allowedTCPPorts = [
    10257 # k3s, used for metrics (controller-manager)
    2381  # k3s, used for metrics (etcd)
    10249 # k3s, used for metrics (kube-proxy)
    10259 # k3s, used for metrics (kube-scheduler)
    10250 # k3s, used for metrics
  ];

  services.k3s = {
    clusterInit = true;
    tokenFile = "/run/secrets/k3s-token";
    extraFlags = toString [
      "--tls-san=${config.networking.hostName}.zolfa.nl"
      "--tls-san=eu-south-1.zolfa.nl"
      # k3s metrics
      "--kube-controller-manager-arg=bind-address=0.0.0.0"
      "--kube-proxy-arg=metrics-bind-address=0.0.0.0"
      "--kube-scheduler-arg=bind-address=0.0.0.0"
      "--etcd-expose-metrics"
    ];
  };
}