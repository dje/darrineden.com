{
  description = "darrineden-flake";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*.tar.gz";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    let
      utils = flake-utils;
    in
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixpkgs-fmt;

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            terraform
          ];
        };
      }
    );
}
