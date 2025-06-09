{
  description = "Tauri Dev Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    utils,
    ...
  }:
    utils.lib.eachDefaultSystem (system: let
      androidPlatformVersion = "34";
      buildToolsVersion = "34.0.0";

      overlays = [(import rust-overlay)];

      pkgs = import nixpkgs {
        inherit overlays system;

        config.android_sdk.accept_license = true;
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "android-studio-stable"
            "android-sdk-build-tools"
            "android-sdk-cmdline-tools"
            "android-sdk-platform-tools"
            "android-sdk-emulator"
            "android-sdk-ndk"
            "android-sdk-platforms"
            "android-sdk-tools"
            "android-sdk-system-image-${androidPlatformVersion}-default-x86_64"
          ];
      };

      androidComposition = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [androidPlatformVersion];
        buildToolsVersions = [buildToolsVersion];
        includeNDK = true;
        includeEmulator = true;
        includeSystemImages = true;
        systemImageTypes = ["default"];
        abiVersions = ["x86_64"];
      };

      androidSdk = androidComposition.androidsdk;
      androidHome = "${androidSdk}/libexec/android-sdk";
    in {
      devShells.default = pkgs.mkShell {
        name = "Tauri Dev Environment";

        nativeBuildInputs = with pkgs; [
          # Android
          androidSdk

          # Java
          jdk21

          # Rust
          (rust-bin.fromRustupToolchainFile ./rust-toolchain)

          # Tauri
          pkg-config
          gobject-introspection
          cargo
          cargo-tauri
          bun
        ];

        buildInputs = with pkgs; [
          at-spi2-atk
          atkmm
          cairo
          gdk-pixbuf
          glib
          gtk3
          harfbuzz
          librsvg
          libsoup_3
          pango
          webkitgtk_4_1
          openssl
        ];

        # Environment variables
        ANDROID_HOME = androidHome;
        NDK_HOME = "${androidHome}/ndk-bundle";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidHome}/build-tools/${buildToolsVersion}/aapt2";

        shellHook = ''
          avdmanager create avd -n tauri_avd -k "system-images;android-34;default;x86_64" --device "pixel_9"
        '';
      };
    });
}
