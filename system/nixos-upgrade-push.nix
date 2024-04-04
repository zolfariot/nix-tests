  { config, lib, pkgs, ... }: {
  # Auto GitOps upgrade
  systemd.services.nixos-upgrade-push = {
    description = "Trigger NixOS rebuild at every push on the Flake Repo.";
    restartIfChanged = true;
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
      bashInteractive
      ntfy-sh
    ];
    
    script = let
      nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
      ntfy-sh = "${pkgs.ntfy-sh}/bin/ntfy";
    in ''
      ${ntfy-sh} sub e243cf52-5b05-4668-90f9-85854a9d665d '${nixos-rebuild} --flake github:zolfariot/nix-tests switch --refresh'
    '';

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}