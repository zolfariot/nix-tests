{ pkgs, config, lib, ... }:
  let
    metadata = pkgs.callPackage ../utils/metadata.nix {};
    hosts = metadata.hosts;
    host = metadata.hosts."${config.networking.hostName}";

    peerHostnames = lib.attrsets.attrNames (lib.attrsets.filterAttrs (key: value: key != config.networking.hostName) hosts);
    mkWgConfV4 = targetHostName:
      let
        target = metadata.hosts."${targetHostName}";
        endpointHost = if (builtins.hasAttr "ext" target.ipv4)
          then target.ipv4.ext
          else (lib.head (lib.strings.splitString "/" target.ipv4.addr));
        endpointPort = if (builtins.hasAttr "wg_altlocalport" target)
          then (host.wg_remoteport + 10*target.wg_altlocalport)
          else host.wg_remoteport;
      in {
        ips = [ host.wg_linklocal ];
        listenPort = target.wg_remoteport;
        privateKeyFile = "/etc/wireguard/wg-znet.key";
        generatePrivateKeyFile = true;
        allowedIPsAsRoutes = false;
        peers = [
          {
            publicKey = target.wg_pubkey;
            endpoint = endpointHost + ":" + builtins.toString(endpointPort);
            allowedIPs = [ "::/0"];
          }
        ];
     };
  in 
  {
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
      matchConfig.Name = host.ifname_ext;
      gateway = [ ]
        ++ lib.lists.optional (builtins.hasAttr "ipv4" host) host.ipv4.gateway
        ++ lib.lists.optional (builtins.hasAttr "ipv6" host) host.ipv6.gateway;
      dns = host.dns;
      addresses = [ ] 
        ++ lib.lists.optional (builtins.hasAttr "ipv4" host) {
          addressConfig.Address = host.ipv4.addr;
          addressConfig.Peer = lib.mkIf (lib.strings.hasSuffix "/32" host.ipv4.addr) host.ipv4.gateway;  
        }
        ++ lib.lists.optional (builtins.hasAttr "ipv6" host) {
          addressConfig.Address = host.ipv6.addr;
          addressConfig.Peer = lib.mkIf (lib.strings.hasSuffix "/128" host.ipv6.addr) host.ipv6.gateway;  
        };
    };

    systemd.network.netdevs."20-znet" = {
      netdevConfig.Name = "znet";
      netdevConfig.Kind = "dummy";
    };
    systemd.network.networks."20-znet" = {
      matchConfig.Name = "znet";
      networkConfig.Address = host.znet_loopback;
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

    networking.wireguard.interfaces = builtins.listToAttrs (
      map (name: { name = name; value = mkWgConfV4 name; }) peerHostnames
    );
  } 