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

    networking.firewall.allowedUDPPorts = []
      ++ map (name: (mkWgConfV4 name).listenPort) peerHostnames;

    networking.firewall.interfaces = builtins.listToAttrs (
      map (name: { name = name; value = { allowedUDPPorts = [ 6696 ]; }; }) peerHostnames
    );

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

    networking.wireguard.interfaces = builtins.listToAttrs (
      map (name: { name = name; value = mkWgConfV4 name; }) peerHostnames
    );

    services.frr.babel = {
      enable = true;
      config = lib.strings.concatLines [
        "router babel"
        (lib.strings.concatLines (map (hostName: "  network ${hostName}") peerHostnames))
        "  redistribute ipv6 connected"
        (lib.strings.concatLines (map (hostName: ''
          interface ${hostName}
            babel wired
            babel enable-timestamps
        '') peerHostnames))
      ];
    };
  } 