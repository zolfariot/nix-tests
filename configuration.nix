{ config, lib, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Amsterdam";

  systemd.network = {
    enable = true;
    networks."10-lan".matchConfig.Name = "enp1s0";
    networks."10-lan".networkConfig.DHCP = "yes";
  };
  networking.useNetworkd = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  users.users.zolfa = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7sWoCdLb1E+KK8A4Ld6WSuDh+MtDgqytojsUYsvm5D zolfa@nix" ];
  };

  programs.mtr.enable = true;
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    clevis
  ];
  
  system.stateVersion = "24.05";
}