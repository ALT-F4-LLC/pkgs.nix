{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    types;

  cfg = config.services.alloy;
in
{
  options.services.alloy = {
    enable = mkEnableOption "alloy";
    package = mkPackageOption { } null { };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open the default port in the firewall for the administrative web UI. The
        port can be changed in configuration, so this option should only be used
        if that port is unchanged.
      '';
    };

    storagePath = mkOption {
      type = types.path;
      default = "/var/lib/alloy";
      description = "The data directory for alloy.";
    };

    configPath = mkOption {
      type = types.path;
      default = "/etc/alloy/config.alloy";
      description = "The config file (or directory) containing configuration for alloy.";
    };

    user = mkOption {
      type = types.str;
      default = "alloy";
      description = "The user as which to run alloy.";
    };

    group = mkOption {
      type = types.str;
      default = "alloy";
      description = "The group as which to run alloy.";
    };

    extraEnvironment = mkOption {
      type = types.attrs;
      default = { };
      example = {
        GRAFANA_CLOUD_TOKEN = "gct-...";
      };
      description = "Extra environment variables to load the service with.";
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Paths to load as environment files.";
    };

    extraArgs = mkOption {
      type = types.str;
      default = "";
      example = "--disable-reporting";
      description = "Extra arguments to load the service with.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups = lib.mkIf (cfg.group == "alloy") {
      alloy = { };
    };

    users.users = lib.mkIf (cfg.user == "alloy") {
      alloy = {
        inherit (cfg) group;
        extraGroups = [ "adm" "systemd-journal" ];
        isSystemUser = true;
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ 12345 ];
    };

    systemd.packages = [ cfg.package ];
    systemd.services.alloy = {
      description = "Vendor-agnostic OpenTelemetry Collector distribution with programmable pipelines";

      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HOSTNAME = "%H";
        ALLOY_DEPLOY_MODE = "nixos";
      } // cfg.extraEnvironment;

      serviceConfig = {
        Restart = "always";
        ExecStart = "${lib.getExe cfg.package} run ${cfg.extraArgs} --storage.path=${cfg.storagePath} ${cfg.configPath}";
        ExecReload = "/usr/bin/env kill -HUP $MAINPID";
        EnvironmentFile = cfg.environmentFiles;
        StateDirectory = "alloy";
        WorkingDirectory = "%S/alloy";
        TimeoutStopSec = "20s";
        User = cfg.user;
      };
    };
  };
}
