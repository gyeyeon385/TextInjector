# Changelog

## 0.2.0 — 2026-09-23 (Preview)

- Preserve leading, repeated and trailing spaces, blank lines and Unicode text.
- Normalize CRLF, CR, LF, NEL and Unicode line/paragraph separators into real Return key events.
- Send physical Tab keys by default, with an optional four-space expansion mode.
- Preserve literal tabs in the plain text editor and add a multiline sample.
- Validate the complete input before posting; keep cancellation and focus checks for every special key and expanded space.
- Add a 100 ms pause around special keys to prevent the Safari Tab/text ordering race observed during integration testing.
- Add whitespace, key-code, mixed-sequence and cancellation coverage (24 tests total).
- Expand the local Safari fixture with native Tab navigation and a Tab-aware indentation editor.

Return and Tab follow the target website behavior, including submission or focus changes. No automatic trailing Return is added. Packages remain ad-hoc signed and not notarized.

## 0.1.0 — 2026-09-22 (Preview)

- Native SwiftUI editor and Safari-only Unicode keyboard event injection.
- Accessibility permission checks and explicit user-triggered permission requests.
- Fixed character pacing, Safari activation delay, progress and cancellation.
- Foreground and permission checks before each event; PID-scoped event delivery.
- Local Safari compatibility fixture and 12 core tests.
- New TextInjector icon, MIT license and universal macOS DMG / ZIP packages.

This preview accepts single-line text only. Safari end-to-end compatibility has not yet been verified. Clipboard quick injection, special keys, menu bar and global shortcuts are planned. Packages are ad-hoc signed and not notarized.
