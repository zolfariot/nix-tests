{ writeTextFile, lib, ... }:

let
  metadata = lib.importTOML ../hosts.toml;
in {
  inherit metadata;
  hosts = metadata.hosts;
}