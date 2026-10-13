# Third-party license inventory

This source tree is being adapted for an unsigned iOS build. No IPA has been produced yet.

Selected base: [Madeira](https://github.com/willfaust/Madeira), pinned locally at commit `48f976429c189f8396e23d251d8a82f43c705922`, GPL-3.0-or-later. The app build excludes Apple's proprietary Metal Shader Converter and all D3D12 runtime/test binaries. GPTK and D3DMetal are excluded. Verify the final IPA and corresponding source archive before distribution.

Known components from Madeira's current notices (versions and exact fork revisions must be pinned in the build manifest before release):
- Wine: LGPL-2.1-or-later.
- FEX-Emu: upstream MIT; Madeira fork changes separately marked GPL-3.0-or-later.
- DXMT: upstream MIT; Madeira fork changes separately marked GPL-3.0-or-later; its imported D3D9 frontend includes LGPL-2.1-or-later code.
- rpmalloc: upstream 0BSD; fork changes separately marked GPL-3.0-or-later.
- GMP, Nettle/Hogweed, GnuTLS, FFmpeg and other linked components: preserve Madeira's complete `THIRD-PARTY-NOTICES.md` and license texts; verify the build configuration does not include GPL-incompatible or proprietary components.
- StikJIT / idevice pairing code: MPL-2.0 / MIT per Madeira's JIT and notices documentation.
- Apple Metal Shader Converter: proprietary and excluded. GPTK/D3DMetal are excluded.
- Microsoft VC++ redistributables: not included; obtain only from Microsoft if needed and keep optional/legal. Wine Mono may be fetched from WineHQ under its license and with source notices as required.
- Game files: none downloaded or bundled. Only user-owned games are to be tested.

The repository's `LICENSES/` directory and `THIRD-PARTY-NOTICES.md` contain upstream license texts and notices. Preserve them with the exact submodule revisions and source/build scripts. The app package must not include unlicensed redistributables or proprietary Apple binaries. No third-party game files are included.
