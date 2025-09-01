finalPkgs: prevPkgs: {
  custom = rec {
    nix-output-monitor = import ./nix-output-monitor { pkgs = prevPkgs; };
    rebuild = finalPkgs.callPackage ./rebuild { inherit nix-output-monitor; };
    rebuild-remote = finalPkgs.callPackage ./rebuild-remote { inherit nix-output-monitor; };
  };
}
