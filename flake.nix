{
  description = "Jarrod's system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;
      username = "jarrodldavis";

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = lib.genAttrs supportedSystems;

      mkDarwinConfiguration =
        module:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs username;
          };

          modules = [
            module

            home-manager.darwinModules.home-manager

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = {
                  inherit inputs username;
                };

                users.${username}.imports = [
                  ./modules/home/base.nix
                ];
              };
            }
          ];
        };

      mkNixosConfiguration =
        {
          system,
          modules,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs username;
          };

          modules = modules ++ [
            home-manager.nixosModules.home-manager

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = {
                  inherit inputs username;
                };

                users.${username}.imports = [
                  ./modules/home/base.nix
                ];
              };
            }
          ];
        };

      mkHomeConfiguration =
        {
          system,
          modules,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          extraSpecialArgs = {
            inherit inputs username;
          };

          modules = [
            ./modules/home/base.nix
          ] ++ modules;
        };

      mkApplyApp =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          apply = pkgs.writeShellApplication {
            name = "dotfiles-apply";

            runtimeInputs = [
              pkgs.coreutils
              pkgs.ncurses
            ]
            ++ lib.optionals pkgs.stdenv.isDarwin [
              nix-darwin.packages.${system}.darwin-rebuild
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              home-manager.packages.${system}.home-manager
            ];

            text = builtins.readFile ./scripts/dotfiles-apply.sh.txt;
          };
        in
        {
          type = "app";
          program = "${apply}/bin/dotfiles-apply";
        };
    in
    {
      darwinConfigurations = {
        "Rods-Mac-Studio" = mkDarwinConfiguration ./hosts/darwin/mac-studio.nix;
      };

      homeConfigurations = {
        "jarrodldavis@rods-linux-pc" = mkHomeConfiguration {
          system = "x86_64-linux";

          modules = [
            ./hosts/home/legion-cachyos.nix
          ];
        };
      };

      # Add these only after each NixOS installation has a real
      # hardware-configuration.nix.
      nixosConfigurations = {
        /*
        legion = mkNixosConfiguration {
          system = "x86_64-linux";

          modules = [
            ./hosts/nixos/legion
          ];
        };

        macbook-pro = mkNixosConfiguration {
          system = "x86_64-linux";

          modules = [
            ./hosts/nixos/macbook-pro
          ];
        };
        */
      };

      apps = forAllSystems (
        system: {
          apply = mkApplyApp system;
        }
      );
    };
}
