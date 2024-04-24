{ config, lib, pkgs, ... }:
{
  imports = [
    ./nixos-upgrade-push.nix
  ];

  time.timeZone = "UTC";

  boot.initrd.systemd = {
    enable = true;
    emergencyAccess = true; # TODO: remove in production
    network.enable = true;
    network.networks."10-lan" = config.systemd.network.networks."10-lan";
  };
  boot.initrd.services.resolved.enable = true;

  systemd.network.enable = true;
  networking.useNetworkd = true;
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };
  services.resolved.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Authentication
  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;
  users.defaultUserShell = pkgs.zsh;
  users.users.zolfa = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7sWoCdLb1E+KK8A4Ld6WSuDh+MtDgqytojsUYsvm5D zolfa@nix"
    ];
  };

  # System packages
  programs.mtr.enable = true;
  programs.zsh = {
    histSize = 1000000000;
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh.enable = true;
    ohMyZsh.theme = "robbyrussell";
    ohMyZsh.plugins = ["sudo"];
  };
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    clevis
    tmux
    byobu
    git
    htop
    parted
    gptfdisk
  ];
  environment.etc."zprofile.local".text = ''
    # Autostart byobu multiplexer for all users
    ${pkgs.byobu}/bin/byobu
  '';
  
  system.stateVersion = "24.05";
}