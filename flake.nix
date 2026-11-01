{
  description = "A pure Nix flake for Rust development using the Oxalica overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      ...
    }:
    let
      # Systems supported for the dev environment
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper function to generate attributes for each system
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f rec {
            inherit system;

            # Apply the rust-overlay to nixpkgs
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ (import rust-overlay) ];
            };

            # Configure your toolchain here:
            # Options: .stable.latest, .beta.latest, .nightly.latest, or specific versions like .stable."1.75.0"
            rustToolchain = pkgs.rust-bin.stable.latest.default.override {
              extensions = [
                "rust-src"
                "rust-analyzer"
                "clippy"
              ];
            };
          }
        );
    in
    {
      devShells = forEachSystem (
        { pkgs, rustToolchain, ... }: {
          default = pkgs.mkShell {
            # Tools required to build the project, but not part of the final artifact
            nativeBuildInputs = with pkgs; [
              rustToolchain
              pkg-config
            ];

            # Libraries that your Rust project might link against at runtime
            buildInputs = with pkgs; [
              openssl
              # Add other system dependencies here (e.g., libiconv, glib, etc.)
            ];

            # Environment variables
            env = {
              RUST_BACKTRACE = "1";
              # Tells rust-analyzer where to find the standard library source
              RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
            };
          };
        }
      );
    };
}
