# v0.3.1 hotfix candidate validation

## Completed

- Xcode Debug build passed on macOS arm64.
- Native key-by-key input of `abc` remained in the editor.
- `git diff --check` passed.

## Not verified in this environment

- Chinese pinyin composition could not be exercised because the active input source was English. Computer Use approval blocked opening System Settings to select a Chinese Pinyin input source.
- Accessibility and keyboard-event permission changes were not toggled during the UI run. The Debug build is a separate app bundle from the installed release and correctly shows its own permission status.
- The existing Swift package test run had 26/28 passing tests; two event-construction tests could not create `CGEvent` in this environment (`eventCreationFailed`).

This candidate is not yet published as a GitHub release. The v0.3.0 public release remains the current download until the pinyin path can be verified.
