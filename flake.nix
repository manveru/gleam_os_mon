{
  description = "Gleam wrapper for os_mon";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nix-inclusive.url = "github:input-output-hk/nix-inclusive";
    gleam-nix = {
      url = "github:manveru/gleam-nix";
      inputs.gleam.url = "github:gleam-lang/gleam";
    };
  };

  outputs = {
    self,
    nixpkgs,
    gleam-nix,
    nix-inclusive,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (gleam-nix.packages.${system}) gleam;
    inherit (nix-inclusive.lib) inclusive;
  in {
    packages.${system} = {
      erl-format = pkgs.writeShellApplication {
        name = "erl-format";
        runtimeInputs = [pkgs.rebar3];
        text = ''
          for f in "$@"; do
            rebar3 fmt -w "$f"
          done
        '';
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = [
        gleam
        self.packages.${system}.erl-format
        pkgs.erlangR25
        pkgs.rebar3
      ];
    };
  };
}
