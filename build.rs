use std::env;

fn main() {
    // Try vcpkg first (optional, Windows-friendly)
    // This helps find FFmpeg when installed via: vcpkg install ffmpeg:x64-windows-static-md
    #[cfg(target_os = "windows")]
    {
        // Only try vcpkg if FFMPEG_DIR is not explicitly set
        if env::var("FFMPEG_DIR").is_err() {
            if let Ok(lib) = vcpkg::find_package("ffmpeg") {
                println!("cargo:warning=Found FFmpeg via vcpkg");

                // Emit include paths for ffmpeg-sys-next
                for path in &lib.include_paths {
                    println!("cargo:include={}", path.display());
                }

                println!("cargo:rerun-if-env-changed=VCPKG_ROOT");
            } else {
                println!("cargo:warning=vcpkg FFmpeg not found, using system FFmpeg or FFMPEG_DIR");
            }
        }
    }

    // Process FFmpeg feature flags from ffmpeg-sys-next
    for (name, value) in env::vars() {
        if name.starts_with("DEP_FFMPEG_") {
            if value == "true" {
                println!(
                    r#"cargo:rustc-cfg=feature="{}""#,
                    name["DEP_FFMPEG_".len()..name.len()].to_lowercase()
                );
            }
            println!(
                r#"cargo:rustc-check-cfg=cfg(feature, values("{}"))"#,
                name["DEP_FFMPEG_".len()..name.len()].to_lowercase()
            );
        }
    }
}
