{pkgs, ...}: {
  programs.texlive = {
    enable = true;
    packageSet = pkgs.texlive;
    extraPackages = tpkgs:
      with tpkgs; {
        inherit
          scheme-medium
          llncs
          newtx
          fontaxes
          kastrup
          xstring
          boondox
          latexmk
          wrapfig
          amsmath
          ulem
          hyperref
          capt-of
          csquotes
          graphics
          isodate
          fira
          beamertheme-metropolis
          pgfplots
          doublestroke
          substr
          ;
      };
  };

  xdg.configFile."latexmk/latexmkrc".text = ''
    $pdf_mode = 1;
    set_tex_cmds('-interaction=nonstopmode -synctex=1 %O %S');
    $aux_dir = ".build";
    $out_dir = ".";
    $bibtex_use = 2;
    $clean_ext = "bbl synctex.gz run.xml %R-blx.bib";
  '';
}
