use std::env;
use std::process::Command;

fn main() {
    // Try vcpkg on all platforms (not just Windows)
    // Only try vcpkg if FFMPEG_DIR is not explicitly set
    if env::var("FFMPEG_DIR").is_err() {
        // First, try to find existing FFmpeg installation via vcpkg
        match vcpkg::find_package("ffmpeg") {
            Ok(lib) => {
                println!("cargo:warning=Found FFmpeg via vcpkg");

                // Emit include paths for ffmpeg-sys-next
                for path in &lib.include_paths {
                    println!("cargo:include={}", path.display());
                }

                println!("cargo:rerun-if-env-changed=VCPKG_ROOT");
            }
            Err(_) => {
                // If not found, try to install it automatically
                if let Ok(vcpkg_root) = env::var("VCPKG_ROOT") {
                    println!("cargo:warning=FFmpeg not found in vcpkg, attempting automatic installation...");

                    let triplet = get_vcpkg_triplet();
                    let vcpkg_exe = if cfg!(target_os = "windows") {
                        format!("{}/vcpkg.exe", vcpkg_root)
                    } else {
                        format!("{}/vcpkg", vcpkg_root)
                    };

                    // Install FFmpeg via vcpkg
                    let status = Command::new(&vcpkg_exe)
                        .args(&["install", &format!("ffmpeg:{}", triplet)])
                        .status();

                    match status {
                        Ok(s) if s.success() => {
                            println!("cargo:warning=Successfully installed FFmpeg via vcpkg");
                            // Try to find it again after installation
                            if let Ok(lib) = vcpkg::find_package("ffmpeg") {
                                for path in &lib.include_paths {
                                    println!("cargo:include={}", path.display());
                                }
                            }
                        }
                        Ok(s) => {
                            println!("cargo:warning=vcpkg install failed with status: {}", s);
                            println!("cargo:warning=Falling back to system FFmpeg or pkg-config");
                        }
                        Err(e) => {
                            println!("cargo:warning=Failed to run vcpkg: {}", e);
                            println!("cargo:warning=Falling back to system FFmpeg or pkg-config");
                        }
                    }
                } else {
                    println!("cargo:warning=VCPKG_ROOT not set, falling back to system FFmpeg or pkg-config");
                }

                println!("cargo:rerun-if-env-changed=VCPKG_ROOT");
            }
        }
    }

    // Process FFmpeg feature flags from ffmpeg-sys-next
    for (name, value) in env::vars() {
        if name.starts_with("DEP_FFMPEG_") {
            if value == "true" {
                println!(r#"cargo:rustc-cfg=feature="{}""#, name["DEP_FFMPEG_".len()..name.len()].to_lowercase());
            }
            println!(r#"cargo:rustc-check-cfg=cfg(feature, values("{}"))"#, name["DEP_FFMPEG_".len()..name.len()].to_lowercase());
        }
    }

    // Link Windows system libraries required by FFmpeg
    #[cfg(target_os = "windows")]
    {
        println!("cargo:rustc-link-lib=strmiids");
        println!("cargo:rustc-link-lib=uuid");
        println!("cargo:rustc-link-lib=ole32");
        println!("cargo:rustc-link-lib=oleaut32");
        println!("cargo:rustc-link-lib=mfuuid");
        println!("cargo:rustc-link-lib=mfplat");
    }
}

fn get_vcpkg_triplet() -> String {
    if cfg!(target_os = "windows") {
        if cfg!(target_env = "msvc") {
            // Use static-md for static linking with dynamic CRT
            "x64-windows-static-md".to_string()
        } else {
            "x64-mingw-static".to_string()
        }
    } else if cfg!(target_os = "macos") {
        if cfg!(target_arch = "aarch64") {
            "arm64-osx-release".to_string()
        } else {
            "x64-osx-release".to_string()
        }
    } else {
        // Linux - static linking
        "x64-linux-release".to_string()
    }
}
