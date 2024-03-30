{
  networking.hostName = "znet-de-nue1";

  systemd.network.networks."10-lan" = {
    matchConfig.Name = "ens18";
    networkConfig.Gateway = "212.46.59.1";
    networkConfig.DNS = [ "212.46.59.1" "1.1.1.1" ];
    addresses = [
      {
        addressConfig.Address = "212.46.59.59/32";
        addressConfig.Peer = "212.46.59.1/32";
      }
    ];
  };

  networking.wireguard.interfaces."znet-fr-par1" = {
    table = "off";
    ips = [ "fe80::2/64" ];
    listenPort = 41420;
    privateKeyFile = "/etc/wireguard/priv.key";
    generatePrivateKeyFile = true;
    peers = [
      {
        publicKey = "6nomFb2YigoDJgDcshAYZ9sClKjgooPjE7nmXOv6lzw=";
        endpoint = "185.10.17.55";
        allowedIPs = [ "::/0" ];
      }
    ];
  };

  networking.wireguard.interfaces."lilik-it-flr1a" = {
    table = "off";
    ips = [ "fe80::2/64" ];
    listenPort = 41410;
    peers = [
      {
        publicKey = "";
        endpoint = "";
        allowedIPs = [ "::/0" ]'
      }
    ]
  }
}