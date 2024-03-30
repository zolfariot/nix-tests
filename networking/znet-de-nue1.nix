{
  networking.hostName = "znet-de-nue1";
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

  networking.firewall.allowedTCPPorts = [
    22  # ssh
  ];
  networking.firewall.allowedUDPPorts = [
    14142  # wireguard znet-fr-par1 ipv4
    14150  # wireguard lilik-it-flr1a ipv4
    14140  # wireguard lilik-it-flr1b ipv4
  ];

  networking.firewall.interfaces."znet-*".allowedUDPPorts = [
    6696  # babel
  ];
  networking.firewall.interfaces."lilik-*".allowedUDPPorts = [
    6696  # babel
  ];


  systemd.network.networks."10-lan" = {
    matchConfig.Name = "ens18";
    networkConfig.Gateway = "212.46.59.1";
    networkConfig.DNS = [ "212.46.59.1" "1.1.1.1" ];
    addresses = [
      {
        addressConfig.Address = "212.46.59.59/32";
        addressConfig.Peer = "212.46.59.1";  
      }
    ];
  };

  systemd.network.netdevs."20-znet" = {
    netdevConfig.Name = "znet";
    netdevConfig.Kind = "dummy";
  };
  systemd.network.networks."20-znet" = {
    matchConfig.Name = "znet";
    networkConfig.Address = "2a0e:8f02:2144:f::1/128";
    networkConfig.LinkLocalAddressing = false;
  };

  services.frr.babel = {
    enable = true;
    config = ''
      router babel
        network znet-fr-par1
        network lilik-it-flr1a
        network lilik-it-flr1b
        redistribute ipv6 connected

      interface znet-fr-par1
        babel wired
        babel enable-timestamps

      interface lilik-it-flr1a
        babel wired
        babel enable-timestamps

      interface lilik-it-flr1b
        babel wired
        babel enable-timestamps
    '';
  };

  services.frr.zebra = {
    config = ''
      ipv6 prefix-list znet-128 permit 2a0e:8f02:2140::/44 ge 128
    
      route-map babel-kernel-export permit 10
        match ipv6 address prefix-list znet-128
        set src 2a0e:8f02:2144:f::1

      ip protocol babel route-map babel-kernel-export
    '';
  };

  networking.wireguard.interfaces."znet-fr-par1" = {
    ips = [ "fe80::4:1/64" ];
    listenPort = 14142;
    privateKeyFile = "/etc/wireguard/wg-znet.key";
    generatePrivateKeyFile = true;
    allowedIPsAsRoutes = false;
    peers = [
      {
        publicKey = "6nomFb2YigoDJgDcshAYZ9sClKjgooPjE7nmXOv6lzw=";
        endpoint = "185.10.17.55:14144";
        allowedIPs = [ "::/0" ];
      }
    ];
  };

  networking.wireguard.interfaces."lilik-it-flr1a" = {
    ips = [ "fe80::4:1/64" ];
    listenPort = 14150;
    privateKeyFile = "/etc/wireguard/wg-znet.key";
    generatePrivateKeyFile = true;
    allowedIPsAsRoutes = false;
    peers = [
      {
        publicKey = "kSFbEkjlSFOnVEKUt2ufcR+KDzWFRc98neg30if/gBc=";
        endpoint = "150.217.18.45:14154";
        allowedIPs = [ "::/0" ];
      }
    ];
  };

  networking.wireguard.interfaces."lilik-it-flr1b" = {
    ips = [ "fe80::4:1/64" ];
    listenPort = 14140;
    privateKeyFile = "/etc/wireguard/wg-znet.key";
    generatePrivateKeyFile = true;
    allowedIPsAsRoutes = false;
    peers = [
      {
        publicKey = "ukAjkPVuaVKbzVm+zTUAI6zqY4+dbsVvLONOqHRRJQU=";
        endpoint = "150.217.18.45:14144";
        allowedIPs = [ "::/0" ];
      }
    ];
  };
} 