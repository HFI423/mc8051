{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
  in {
    devShells."x86_64-linux".default = pkgs.mkShell {
        packages = with pkgs; [
            ghdl # https://github.com/ghdl/ghdl
            gtkwave # https://github.com/gtkwave/gtkwave/
        ];
        shellHook = ''
    	   # Define some colors
    	   BOLD='\033[1m'
    	   CYAN='\033[0;36m'
    	   RESET='\033[0m'

    	   echo ""
    	   echo -e "''${BOLD}''${CYAN}VHDL development environment activated with GHDL and GTKwave''${RESET}"
    	   echo ""
        '';
    };
  };
}
