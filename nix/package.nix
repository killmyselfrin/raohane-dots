{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  gawk,
  procps,
  util-linux,
  systemd,
  quickshell,
  qt6,
  hyprland,
  networkmanager,
  networkmanagerapplet,
  wireplumber,
  pipewire,
  bluez,
  blueman,
  upower,
  polkit,
  xdg-desktop-portal-hyprland,
  brightnessctl,
  ddcutil,
  grim,
  slurp,
  cliphist,
  ffmpeg,
  imagemagick,
  hyprsunset,
  wf-recorder,
  ydotool,
  easyeffects,
  fprintd,
  libqalculate,
  pciutils,
  tesseract,
  translate-shell,
  ripgrep,
  jq,
  libnotify,
  wl-clipboard,
  xdg-utils,
  xdg-user-dirs,
  rsync,
  git,
  python3,
}:

let
  pname = "raohane";
  version = lib.strings.trim (builtins.readFile ../VERSION);
  pythonEnv = python3.withPackages (packages: [ packages.pillow ]);
  qtDependencies = [ quickshell qt6.qt5compat qt6.qtmultimedia qt6.qtwayland ];
  qmlImportPath = lib.concatMapStringsSep ":" (package: "${package}/lib/qt-6/qml") qtDependencies;
  qtPluginPath = lib.concatMapStringsSep ":" (package: "${package}/lib/qt-6/plugins") qtDependencies;
  runtimeDependencies = [
    bash coreutils findutils gnugrep gnused gawk procps util-linux systemd
    quickshell hyprland networkmanager networkmanagerapplet wireplumber pipewire
    bluez blueman upower polkit xdg-desktop-portal-hyprland brightnessctl ddcutil
    grim slurp cliphist ffmpeg imagemagick hyprsunset wf-recorder ydotool
    easyeffects fprintd libqalculate pciutils tesseract translate-shell ripgrep
    jq libnotify wl-clipboard xdg-utils xdg-user-dirs rsync git pythonEnv
  ];
in
stdenvNoCC.mkDerivation {
  inherit pname version;
  src = lib.cleanSource ../.;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    runtime="$out/share/raohane"
    mkdir -p "$runtime/modules" "$runtime/panelFamilies" "$runtime/defaults" "$runtime/install" "$out/bin" "$out/libexec"
    cp shell.qml qmldir VERSION "$runtime/"
    cp -r modules/raohane "$runtime/modules/"
    cp panelFamilies/RaohaneFamily.qml "$runtime/panelFamilies/"
    cp -r defaults/native.json defaults/themes "$runtime/defaults/"
    cp -r install/arch "$runtime/install/"
    cp -r assets translations scripts "$runtime/"
    find "$runtime/scripts" -type f \( -name '*.sh' -o -name '*.py' -o -name raohane \) -exec chmod +x {} +
    install -m 0755 scripts/raohane "$out/libexec/raohane-cli"
    bash scripts/prune-runtime.sh "$runtime"
    bash scripts/validate-runtime-payload.sh "$runtime"

    makeWrapper ${bash}/bin/bash "$out/bin/raohane" \
      --add-flags "$out/libexec/raohane-cli" \
      --set RAOHANE_RUNTIME "$runtime" \
      --prefix QML2_IMPORT_PATH : "${qmlImportPath}" \
      --prefix QT_PLUGIN_PATH : "${qtPluginPath}" \
      --prefix PATH : ${lib.makeBinPath runtimeDependencies}

    runHook postInstall
  '';

  passthru = { inherit runtimeDependencies qtDependencies pythonEnv; };

  meta = {
    description = "Japanese-minimal Quickshell desktop shell for Hyprland";
    homepage = "https://github.com/snuskidau/raohane-dots";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "raohane";
  };
}
