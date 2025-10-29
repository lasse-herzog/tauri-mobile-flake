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
      androidPlatformVersion = "35";
      buildToolsVersion = "35.0.0";

      overlays = [(import rust-overlay)];

      pkgs = import nixpkgs {
        inherit overlays system;

        config.android_sdk.accept_license = true;
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "android-studio-stable"

            "android-sdk-build-tools"
            "android-sdk-cmdline-tools"
            "android-sdk-emulator"
            "android-sdk-ndk"
            "android-sdk-platforms"
            "android-sdk-platform-tools"
            "android-sdk-system-image-${androidPlatformVersion}-default-x86_64"
            "android-sdk-tools"

            "build-tools"
            "cmake"
            "cmdline-tools"
            "emulator"
            "ndk"
            "platforms"
            "platform-tools"
            "system-image-${androidPlatformVersion}-default-x86_64"
            "tools"
          ];
      };

      androidComposition = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [androidPlatformVersion "36"];
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
          (rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)

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
        ANDROID_SDK_ROOT = androidHome;

        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidHome}/build-tools/${buildToolsVersion}/aapt2";

        XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";

        # This fixes https://github.com/tauri-apps/tauri/issues/10702
        __GL_THREADED_OPTIMIZATIONS = 0;
        __NV_DISABLE_EXPLICIT_SYNC = 1;

        shellHook = ''
          export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"

          avdmanager create avd -n tauri_avd -k "system-images;android-${androidPlatformVersion};default;x86_64" --device "pixel_9"
        '';
      };
    });
}
