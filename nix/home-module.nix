{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.raohane;
  defaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
  runtime = "${cfg.package}/share/raohane";
  nativeConfig = "${config.xdg.configHome}/raohane/native.json";
in
{
  options.programs.raohane = {
    enable = lib.mkEnableOption "the Raohane Hyprland desktop shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "raohane.packages.<system>.default";
      description = "Raohane package to install.";
    };

    systemd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run Raohane as a systemd user service.";
      };

      target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        description = "User target that owns the Raohane service.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."quickshell/raohane".source = runtime;

    # Keep mutable Raohane settings outside the immutable Nix store.
    home.activation.raohaneNativeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg (builtins.dirOf nativeConfig)}
      if [ ! -e ${lib.escapeShellArg nativeConfig} ]; then
        run install -m 0644 ${runtime}/defaults/native.json ${lib.escapeShellArg nativeConfig}
      fi
    '';

    systemd.user.services.raohane = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Raohane shell for Hyprland";
        After = [ cfg.systemd.target ];
        PartOf = [ cfg.systemd.target ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/raohane run";
        Restart = "on-failure";
        RestartSec = 2;
        Environment = [ "QT_QPA_PLATFORM=wayland" ];
      };
      Install.WantedBy = [ cfg.systemd.target ];
    };
  };
}
