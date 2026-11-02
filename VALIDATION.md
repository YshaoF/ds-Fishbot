# Verification status

Local checks on Windows, 2026-11-02:

- 6 core tests pass: supervisor/deletion/context, safe API addressing, explicit summaries, real Office ZIP parsing, distinct member APIs/file followups and cancellation.
- Playwright WebKit passes 8 workflow checks: naming, own Key/IME/Enter, local document worker/followups, actual saved memory graph, concurrent group responses, context clearing, day/night layouts across 320/375/390/430/844/768 pixel widths, and persistent reload.
- All API calls in these tests use synthetic responses and fake test keys. No real user keys or chat data were copied or used.
- Plist files and generated Xcode project references are validated locally. Native compilation requires Xcode on a Mac runner; cloud build and real-device installation status are reported separately.

WebKit viewport testing is not a physical iPhone test. iOS version-specific file picker, secure storage, signing and installation still require simulator/device verification. An unsigned IPA requires personal signing before installation.
