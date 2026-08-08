{
  lib,
  stdenv,
  buildPackages,
  fetchFromGitHub,
  thead-opensbi,
  bc,
  bison,
  dtc,
  flex,
  installShellFiles,
  ncurses,
  swig,
  which,
  python3,
  perl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "uboot-light_lpi4a_16g_defconfig";
  version = "2026.05.04";

  src = fetchFromGitHub {
    owner = "revyos";
    repo = "th1520-vendor-uboot";
    tag = "20260504";
    hash = "sha256-TivIrlwieZ6RZXNGyITTxxaURVReBhqul5Z+toCvfBg=";
  };

  patches = [
    ./patches/0001-feat-use-mmcbootpart-1-for-nixos.patch
  ];

  postPatch = ''
    patchShebangs tools
    patchShebangs scripts
  '';

  nativeBuildInputs = [
    ncurses
    bc
    bison
    flex
    installShellFiles
    (buildPackages.python3.withPackages (p: [
      p.libfdt
      p.setuptools
      p.pyelftools
    ]))
    swig
    which
    perl
  ];

  depsBuildBuild = [ buildPackages.gccStdenv.cc ];

  hardeningDisable = [ "all" ];

  enableParallelBuilding = true;

  makeFlags = [
    "DTC=${lib.getExe buildPackages.dtc}"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "HOSTCFLAGS=-fcommon"
    "OPENSBI=${thead-opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
  ];

  configurePhase = ''
    runHook preConfigure
    make -j$NIX_BUILD_CORES light_lpi4a_16g_defconfig
    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp u-boot-with-spl.bin $out/
    mkdir -p $out/nix-support
    echo "file binary-dist $out/u-boot-with-spl.bin" >> $out/nix-support/hydra-build-products
    runHook postInstall
  '';

  dontStrip = true;

  __structuredAttrs = true;

  meta = with lib; {
    homepage = "https://www.denx.de/wiki/U-Boot/";
    description = "Boot loader for embedded systems";
    license = licenses.gpl2Plus;
    platforms = [ "riscv64-linux" ];
  };
})
