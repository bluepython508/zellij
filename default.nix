{ pkgs, nixpkgs, system, crane, rust-overlay }: 
let
  rustPkgs = import nixpkgs {
    inherit system;
    overlays = [ (import rust-overlay) ];
  };

  wasmTarget = "wasm32-wasi";
  rustVersion = "1.63.0";
  rustWithWasmTarget = rustPkgs.rust-bin.stable.${rustVersion}.default.override {
    targets = [ wasmTarget ];
  };

  craneLib = crane.mkLib pkgs;
  craneLibWasm = craneLib.overrideToolchain rustWithWasmTarget;
  plugin = path: craneLibWasm.buildPackage {
    name = path;
    src = ./.;
    cargoExtraArgs = "-p ${path} --target ${wasmTarget}";

    # Override crane's use of --workspace, which tries to build everything.
    cargoCheckCommand = "cargo check --release";
    cargoBuildCommand = "cargo build --release";

    # Tests currently need to be run via `cargo wasi` which
    # isn't packaged in nixpkgs yet...
    doCheck = false;
  };
  compact_bar = plugin "compact-bar";
  status_bar = plugin "status-bar";
  strider = plugin "strider";
  tab_bar = plugin "tab-bar";
in
{
  zellij = craneLib.buildPackage {
    src = ./.;
    nativeBuildInputs = [ pkgs.pkg-config ];
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    inherit compact_bar status_bar strider tab_bar;
    preBuild = ''
      mkdir -p zellij-utils/assets/plugins/
      cp {$compact_bar,$status_bar,$strider,$tab_bar}/bin/*.wasm zellij-utils/assets/plugins/
    '';
  };
}
