{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.raohane;
  defaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.programs.raohane = {
    enable = lib.mkEnableOption "system support for the Raohane desktop shell";
    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "raohane.packages.<system>.default";
      description = "Raohane package exposed system-wide.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    programs.hyprland.enable = lib.mkDefault true;
    networking.networkmanager.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    hardware.i2c.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
    security.polkit.enable = lib.mkDefault true;
    security.rtkit.enable = lib.mkDefault true;

    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };

    fonts.packages = with pkgs; [
      material-symbols
      noto-fonts
      noto-fonts-cjk-sans
      nerd-fonts.jetbrains-mono
    ];
  };
}
