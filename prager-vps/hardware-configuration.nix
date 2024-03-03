{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.enable = true;

  swapDevices = [{
    device = "/var/cache/swapfile";
    size = 4096;
  }];
}