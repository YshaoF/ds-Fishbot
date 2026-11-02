# Verification status

Local checks on Windows, 2026-11-02:

- 6 core tests pass: supervisor/deletion/context, safe API addressing, explicit summaries, real Office ZIP parsing, distinct member APIs/file followups and cancellation.
- Playwright WebKit passes 8 workflow checks: naming, own Key/IME/Enter, local document worker/followups, actual saved memory graph, concurrent group responses, context clearing, day/night layouts across 320/375/390/430/844/768 pixel widths, and persistent reload.
- All API calls in these tests use synthetic responses and fake test keys. No real user keys or chat data were copied or used.
- Plist files and generated Xcode project references are validated locally. Native compilation requires Xcode on a Mac runner; cloud build and real-device installation status are reported separately.

WebKit viewport testing is not a physical iPhone test. iOS version-specific file picker, secure storage, signing and installation still require simulator/device verification. An unsigned IPA requires personal signing before installation.

## Cloud Xcode verification

2026-11-02, commit `f0abd4a7439a543ba42add4d2148f51d6bd2a84e`: https://github.com/YshaoF/ds-Fishbot/actions/runs/41397304518 completed successfully. Xcode compiled the simulator and ARM64 device app. Simulator self-checks report `uiReady=true`, `keychain=true`, `storage=true`; the actual first-screen screenshot shows the naming card.

The downloaded artifact ZIP digest and IPA digest were verified, every bundled web asset matches the tested source, and the IPA contains no user state or Key files. The IPA remains unsigned and requires personal signing. Physical-device installation and live model calls have not been tested.


## 0.2.0 companion checks

2026-11-02 local checks: 8 Node tests passed. iPhone WebKit interaction/regression checks passed with synthetic data only, including pet tap and drag, resizing, standby, reduced motion, persisted focus start/stop, companion deep-link handling, and cancellation of animation frames after leaving the page. No API request is triggered by companion interactions. Chat, files, group replies and shared memory regressions passed.

Cloud Xcode compilation and native ActivityKit start/stop tests for this version are pending until the new workflow completes. Real iPhone widget registration, personal signing of the extension and Live Activity appearance still require device validation. The WebKit image is an in-app rendering, not a Home Screen widget or Lock Screen screenshot.
