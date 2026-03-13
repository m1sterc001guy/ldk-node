{
  description = "ldk-node development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        rustToolchain = pkgs.rust-bin.stable."1.85.0".default.override {
          extensions = [ "rust-src" "rustfmt" "clippy" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rustToolchain
            pkgs.pkg-config
            pkgs.openssl
            pkgs.protobuf
            pkgs.cmake

            # Needed by scripts/download_bitcoind_electrs.sh
            pkgs.curl
            pkgs.unzip
          ];

          shellHook = ''
            # Download bitcoind/electrs if not already cached
            if [ ! -x bin/bitcoind ] || [ ! -x bin/electrs ]; then
              echo "Downloading bitcoind and electrs binaries..."
              source ./scripts/download_bitcoind_electrs.sh
              mkdir -p bin
              cp "$BITCOIND_EXE" bin/bitcoind
              cp "$ELECTRS_EXE" bin/electrs
            fi
            export BITCOIND_EXE="$(pwd)/bin/bitcoind"
            export ELECTRS_EXE="$(pwd)/bin/electrs"
          '';
        };
      }
    );
}
