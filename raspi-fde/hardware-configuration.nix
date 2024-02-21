{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    # Optimized non-hardware cryptography
    "adiantum"
    "nhpoly1305_neon"
    "chacha_neon"
  ];

  boot.initrd.systemd = {
    enable = true;
    emergencyAccess = true; # TODO: remove in production
    network.enable = true;
    network.networks."10-lan".matchConfig.Name = "enp1s0";
    network.networks."10-lan".networkConfig.DHCP = "yes";
  };

  boot.initrd.services.resolved.enable = true;
}