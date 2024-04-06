{ ... }:
{
  disko.devices.disk = {
    ssd = {
      type = "disk";
      device = "/dev/sda";
      imageSize = "2G";
      content = {
        type = "gpt";
        partitions.BOOT = {
          size = "1M";
          type = "EF02";
        };
        partitions.ESP = {
          size = "512M";
          type = "EF00";
          content.type = "filesystem";
          content.format = "vfat";
          content.mountpoint = "/boot";
        };
        partitions.ROOT = {
          size = "100%";
          content.type = "luks";
          content.name = "crypted-root";
          content.clevisPin = "tang";
          content.clevisPinConfig = ''{"url": "http://tang.zolfa.nl"}'';
          content.content.type = "btrfs";
          content.content.extraArgs = [ "-f" ];
          content.content.subvolumes."/root".mountpoint = "/";
          content.content.subvolumes."/root".mountOptions = [ "noatime" ];
          content.content.subvolumes."/nix".mountpoint = "/nix";
          content.content.subvolumes."/nix".mountOptions = [ "noatime" ];
          content.content.subvolumes."/home".mountpoint = "/home";
          content.content.subvolumes."/home".mountOptions = [ "noatime" ];
        };
      };
    };
  };
}