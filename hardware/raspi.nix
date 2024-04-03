{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Optimized non-hardware cryptography
  boot.initrd.availableKernelModules = [
    "adiantum"
    "nhpoly1305_neon"
    "chacha_neon"
  ];
}