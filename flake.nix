{
  description = "A terminal workspace with batteries included";

  inputs = {
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.follows = "rust-overlay/flake-utils";
    nixpkgs.follows = "rust-overlay/nixpkgs";
    crane.url = "github:ipetkov/crane";
  };

  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        code = pkgs.callPackage ./. { inherit nixpkgs crane system rust-overlay; };
      in rec {
        packages = rec {
          zellij = code.zellij;
          default = zellij;
        };
      }
    );
}
