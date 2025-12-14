use std::env;

fn main() {
    let project_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

    let skip_swift_build = env::var("SKIP_SWIFT_BUILD").is_ok();

    if !skip_swift_build {
        // Build the Swift library
        let swift_build_command = format!(
            "swift build -c release --package-path {}/azookey-swift",
            project_dir
        );
        if cfg!(target_os = "windows") {
            let output = std::process::Command::new("cmd")
                .args(&["/C", &swift_build_command])
                .output()
                .expect("Failed to execute command");
            if !output.status.success() {
                panic!(
                    "Swift build failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                );
            }

            // move azookey-swift.dll to the target directory
            let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
            let profile = env::var("PROFILE").unwrap();
            let target_dir = format!("{}/target/{}", crate_dir, profile);
            let swift_lib_path = format!(
                "{}/azookey-swift/.build/release/azookey-swift.dll",
                project_dir
            );
            let target_lib_path = format!("{}/azookey-swift.dll", target_dir);
            std::fs::copy(&swift_lib_path, &target_lib_path).unwrap_or_else(|_| {
                panic!(
                    "Failed to copy azookey-swift.dll to target directory: {}",
                    target_lib_path
                )
            });
        } else {
            // non-windows
            let output = std::process::Command::new("sh")
                .arg("-c")
                .arg(&swift_build_command)
                .output()
                .expect("Failed to execute command");
            if !output.status.success() {
                panic!(
                    "Swift build failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                );
            }
        }
        // Set the Swift library path
        println!(
            "cargo:rustc-link-search={}/azookey-swift/.build/release/",
            project_dir
        );
        println!(
            "cargo:rustc-link-search={}",
            env::var("SWIFT_LIB_DIR").unwrap()
        );
    }

    println!("cargo:rustc-link-search={}/libs/", project_dir);
    println!("cargo:rustc-link-lib=azookey-swift");
}
