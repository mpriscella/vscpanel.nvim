{
  description = "Flake for developing the Neovim plugin vscpanel.nvim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.act
            pkgs.just
            pkgs.luajitPackages.luacheck
            (pkgs.writeShellScriptBin "nvim-dev" ''
              #!/usr/bin/env bash
              set -euo pipefail

              # Start a sanitized Neovim: no user init, no shada, no user packages
              # Add current repo to runtimepath so plugin/ and lua/ are discovered
              nvim \
                -u $(pwd)/tests/minimal_init.lua \
                -i NONE \
                --cmd "set rtp+=$(pwd)" \
                -c "lua pcall(require, 'vscpanel')"
            '')
          ];
        };
        formatter = pkgs.alejandra;
      }
    );
}
