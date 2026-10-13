# Progress

## Session: 2026-10-13

### Goal
Build and deliver a real unsigned iOS ARM64 IPA for a Wine-based local Windows application runtime, retaining the stated 64-bit Windows game goal. No Mac is available; heavy compilation must happen in GitHub Actions. Work is confined to this workspace.

### Current milestone
M1 research: done. M2-M7: not started. No IPA or device test exists.

### Workspace and disk baseline
Workspace: `J:\games\wine-ios`.

Start-of-session free space: C: 0.15 GB; J: 91.81 GB. Workspace began with only `_env` present. After creating the required workspace directories, reported free space remained C: 0.15 GB and J: 91.81 GB. No local build or SDK installation has been attempted. Git is not on PATH; an archive/API or portable J: solution will be used rather than installing globally.

Latest after source checkout (2026-10-13): C: 276.5 MB free; J: 88.9 GB free. C: briefly fell to 136 MB during tool startup/download activity; inspection found only small PowerShell startup/temp files written during the session and no large session files. It has since recovered above the session baseline. Local source and portable Git are on J:. The Madeira recursive submodule checkout consumed about 2.9 GB on J:; it is expected source material and no local compilation occurred.

Latest check after source audit and removal of redundant archive downloads (2026-10-13): C: 635,707,392 bytes free (about 607 MiB); J: 95,938,248,704 bytes free (about 89.3 GiB). C: free space is above the session start. The redundant archive extraction/download were removed from `source/` and `downloads/`; the canonical checked-out tree remains under `project/`. No local build was run.

### Research findings
- Madeira is the selected active base after a source and license audit. The previous Juice candidate was rejected: its own license text reserves all rights to the app, launcher and scripts.
- Madeira publishes GPL-3.0-or-later code and integrates iOS Wine, FEX ARM64EC translation, DXMT D3D9/10/11-to-Metal, and an iOS 27 pairing flow. These are upstream project claims; none has yet been reproduced in our build or on the iPhone.
- SideStore's June 2026 documentation predates Madeira's October 2026 iOS 27 integration and warns of limited JIT support. The target JIT path therefore remains unverified on the user's device.
- Box64 is Linux-oriented and not a direct iOS/Wine substitute. MoltenVK alone does not prove DXVK can run with iOS Wine. Madeira's integrated FEX/DXMT path is the most concrete starting point found.

### Decisions
See `DECISIONS.md`. Adapt Madeira and keep FEX/DXMT for an initial D3D9/10/11-capable build. Exclude Microsoft's proprietary Metal Shader Converter and all Madeira D3D12 payloads. Implement import from the Files folder picker by copying the chosen game folder into the sandboxed Wine `drive_c`; the app's existing relative-path library model depends on files being in the prefix. Do not claim the goal is feasible until a real build and device launch test pass.

### M1 evidence / base checkout
- Research report: `RESEARCH.md`.
- Selected base: official `willfaust/Madeira`, current commit `48f976429c189f8396e23d251d8a82f43c705922`.
- Portable MinGit 2.56.0.windows.2 is under `_env/tools/git`; its archive SHA-256 matched the digest in the official GitHub release API.
- `git submodule update --init --recursive --depth 1` succeeded for all pinned Madeira submodules, including the FEX nested dependencies, DXMT, Wine and Madeira Dock. This disproves the September 16 build note's then-current unavailability claim for the current commit.
- Disk check after full recursive checkout: C: 276.5 MB free, J: 88.9 GB free. Latest check after audit/cleanup: C: 639,483,904 bytes free, J: 95,938,781,184 bytes free.
- No IPA, build, JIT test, game test or iPhone test has been performed. The tracked Apple `libmetalirconverter.dylib` has been removed from the current source tree; a clean derived Git history and an IPA scan are still required before publishing.

### Current session changes (2026-10-13)
- Removed the tracked Apple converter dylib and Madeira D3D12 runtime/test binaries from the derived working tree. Removed their Xcode resource/signing references and startup canary link so proprietary converter code and D3D12 payload are not linked or copied into the app. Removed D3D12-only settings/diagnostics from the generated catalogue and game menu. DXMT's open D3D9/10/11 path remains the first graphics target.
- Added a SwiftUI Files folder importer to the library `+` menu. It accesses the selected security-scoped folder while copying it into `drive_c` with a collision-safe name, then opens the imported folder in the existing executable browser. Existing manual browsing from `drive_c` remains available.
- Static source review only so far. No local build or tests have been run. Project source checkout is shallow, but its initial upstream commit contains the now-removed proprietary converter in Git history; before publishing, create a clean derived history so that binary is not reachable from our repository. The macOS Actions workflow and complete generated dependency/toolchain stages remain to be written.

### Next
1. Finish auditing the local EXE import and launch path; keep the existing iOS 27 JIT helper and entitlements.
2. Add reproducible staged macOS GitHub Actions builds for the missing LLVM/llvm-mingw/Wine/FEX/DXMT outputs, then package an unsigned IPA and logs.
3. Verify no proprietary converter or D3D12 payload is reachable from the clean derived Git history or final IPA.
4. Create/push the derived GitHub repository and run the workflow; fix failures until a real IPA exists.
5. Test on the iPhone 17 with JIT, then test free/legal game demos and document measured results.

### Evidence links
- Juice: https://github.com/ExoCore-Kernel/Juice
- Juice build notes: https://github.com/ExoCore-Kernel/Juice/blob/main/docs/BUILDING.md
- SideStore JIT status: https://docs.sidestore.io/docs/advanced/jit
- StikJIT integration protocol: https://github.com/StikDebug/StikJIT/blob/main/INTEGRATION.md
- Box64: https://github.com/ptitSeb/box64
- MoltenVK: https://github.com/KhronosGroup/MoltenVK
