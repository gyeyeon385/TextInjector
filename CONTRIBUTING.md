# Contributing

Use Xcode 16+ and Swift 6 on macOS. Run `swift test` and `bash scripts/build.sh` before proposing changes. The native app target and Swift Package share their source files. After adding Swift files, run `python3 scripts/generate_project.py` and include the regenerated project.

Keep injection scoped to Safari, validate text before activation, preserve Unicode scalar boundaries, and check cancellation, permissions and foreground state before posting. Never record input or clipboard contents in logs, analytics or persistent files. The test fixture may observe input events but must not implement the product by modifying a page's DOM.

Describe actual validation separately from simulated tests. Use the local fixture for integration work; do not test against real forms containing private data. Report issues with macOS/Safari versions and synthetic sample strings only.

To create local universal release assets, run `bash scripts/package.sh`. Developer ID signing and notarization require the maintainer's own distribution credentials and are not configured in this repository.
