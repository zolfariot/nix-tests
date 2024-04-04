{ config, lib, pkgs, ... }:
{
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

  # Auto GitOps upgrade
  systemd.services.nixos-upgrade-push = {
    description = "NixOS Upgrade on Push";
    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;
    serviceConfig.Type = "simple";
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    } // config.networking.proxy.envVars;

    path = with pkgs; [
      coreutils
      gnutar
      xz.bin
      gzip
      gitMinimal
      config.nix.package.out
      config.programs.ssh.package
      ntfy-sh
    ];
    
    script = let
      nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
      ntfy-sh = "${pkgs.ntfy-sh}/bin/ntfy";
    in ''
      ${ntfy-sh} sub e243cf52-5b05-4668-90f9-85854a9d665d '${nixos-rebuild} --flake github:zolfariot/nix-tests switch --refresh'
    '';
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
  ];
  
  system.stateVersion = "24.05";
}