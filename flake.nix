{
  description = "remu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (pkgs) lib;

        craneLib = crane.mkLib pkgs;
        src = craneLib.cleanCargoSource ./.;

        commonArgs = {
          inherit src;
          strictDeps = true;

          buildInputs = lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];

          preCheck = ''
            export CI=1
          '';
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        remu = craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });
      in
      {
        apps.default = flake-utils.lib.mkApp { drv = remu; };

        packages = {
          default = remu;
        };

        checks = {
          inherit remu;
        };

        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};
        };
      }
    );
}
