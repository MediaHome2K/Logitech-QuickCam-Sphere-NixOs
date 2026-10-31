{
  description = "Suivi de visage PTZ pour Logitech QuickCam Sphere";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      overlay = final: prev:
        let
          pythonEnv = final.python3.withPackages (ps: [
            (ps.opencv4.override { enableGtk3 = true; })
            ps.numpy
            ps.pystray
            ps.pillow
            ps.tkinter
            ps.pygobject3
          ]);
        in {
          follow-me = final.stdenvNoCC.mkDerivation {
            pname = "follow-me";
            version = "0.7.0";
            src = self;
            dontUnpack = true;
            nativeBuildInputs = [ final.makeWrapper ];

            installPhase = ''
              mkdir -p "$out/share/follow-me" "$out/bin"

              install -m 0444 \
                "$src/follow-me-QuickCam-Sphere-NixOs.py" \
                "$out/share/follow-me/follow-me-QuickCam-Sphere-NixOs.py"

              makeWrapper ${pythonEnv}/bin/python "$out/bin/follow-me" \
                --add-flags "$out/share/follow-me/follow-me-QuickCam-Sphere-NixOs.py" \
                --prefix PATH : ${final.lib.makeBinPath [ final.v4l-utils ]}
            '';
          };
        };

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          }));
    in {
      overlays.default = overlay;

      packages = forAllSystems (pkgs: {
        default = pkgs.follow-me;
        follow-me = pkgs.follow-me;
      });
    };
}