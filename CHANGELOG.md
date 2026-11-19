# Changelog

## 0.3.1 — Hotfix Candidate

- Preserve uncommitted pinyin / IME marked text in the source editor so SwiftUI updates do not replace the composition.
- Keep the editor's committed text when SwiftUI briefly delivers an older binding snapshot after IME commit.
- Refresh permission state on app activation and publish updates only when Accessibility or keyboard-event access actually changes.
- Show Accessibility and keyboard-event access separately, and request missing permissions from the grant button.

## 0.3.0 — Development Preview

- Add a browser selector for Safari and Google Chrome.
- Activate the selected browser, verify its frontmost process and scope keyboard events to its PID.
- Open the no-paste input fixture in the selected browser and use browser-specific status and error messages.
- Keep the existing whitespace, multiline, Return and Tab behavior.
- Add automated coverage for Chrome target selection, process verification and focus loss.

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
