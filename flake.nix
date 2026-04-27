{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    yesod-middleware-csp = {
      url = "github:SupercedeTech/yesod-middleware-csp";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, yesod-middleware-csp }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(_: prev: {
            haskellPackages = prev.haskellPackages.override {
              overrides = _: hprev: {
                yesod-middleware-csp = prev.haskell.lib.doJailbreak
                  (hprev.callCabal2nix "supercede-yesod-middleware-csp"
                    yesod-middleware-csp
                    { });
              };
            };
          })];
        };

        t = pkgs.lib.trivial;
        hl = pkgs.haskell.lib;

        project = devTools:
          let addBuildTools = (t.flip hl.addBuildTools) devTools;
          in pkgs.haskellPackages.developPackage {
            root = pkgs.lib.sourceFilesBySuffices ./. [ ".cabal" ".hs" ];
            name = "yesod-pendo";
            returnShellEnv = !(devTools == [ ]);

            modifier = (t.flip t.pipe) [
              addBuildTools
              hl.dontHaddock
              hl.enableStaticLibraries
              hl.justStaticExecutables
              hl.disableLibraryProfiling
              hl.disableExecutableProfiling
            ];
          };

      in {
        packages.pkg = project [ ];

        defaultPackage = self.packages.${system}.pkg;

        devShell = project (with pkgs.haskellPackages; [
          cabal-fmt
          cabal-install
          hlint
        ]);

        shellHook = ''
          echo $DEV
        '';
      });
}
