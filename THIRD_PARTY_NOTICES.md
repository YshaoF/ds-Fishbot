# Third-party notices

- fflate 0.8.2, MIT, copyright Arjun Barrett. Included license: `dist/vendor/fflate-LICENSE.txt`.
- PDF.js / pdfjs-dist 6.5.438, Apache-2.0, Mozilla Foundation and contributors. Included license: `dist/vendor/pdfjs-LICENSE.txt`. Only legacy parser and worker files are bundled; no remote CDN request at runtime. Eval-based PDF features are disabled.
- Playwright 1.64.1, Apache-2.0, Microsoft Corporation. Used only as local development QA; test browser binaries are excluded from delivery and GitHub source.
- Whale SVG and original app icon are Fishbot project assets, based on the user's earlier provided silhouette.

Registry package versions and SHA-512 integrity are recorded in `DEPENDENCIES.json`. Exact bundled parser SHA-256 values are recorded in `VENDOR.json`. This independent mobile implementation follows the existing Fishbot behavior but does not claim to include the complete Cumora server or embedded Hindsight runtime.
