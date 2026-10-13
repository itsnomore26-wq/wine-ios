# Decisions

## 2026-10-13 — Reject Juice after license audit
**Decision:** Do not reuse Juice source or binaries.

**Reason:** Its in-tree `LICENSES/README.md` states that Juice-original app, launcher, scripts, toolchain, config and related code are all rights reserved and lack an open-source grant. Publishing source on GitHub does not grant reuse rights. This fails the user's open-source-only requirement.

## 2026-10-13 — Use Madeira as the first base
**Decision:** Evaluate willfaust/Madeira as the base for the implementation.

**Reason:** Its published GPL-3.0-or-later project and component licensing, Wine/ARM64EC + FEX + DXMT architecture, non-jailbroken iOS app, and iOS 27 in-app JIT path align with the fixed goal. Its latest release claims games reach gameplay and iOS 27 pairing works.

**Risks to resolve:** The upstream clean-build audit (2026-09-16) reports missing/unverified inputs and unavailable pinned submodule commits; local EXE launch has an open bug report; iOS 27 support is only an upstream claim until we test on iPhone 17. These are implementation work, not verified results.

## 2026-10-13 — Exclude Apple proprietary D3D12 converter path
**Decision:** Ship only the open-source Wine/FEX/DXMT D3D9/10/11 path in our first IPA. Omit Madeira D3D12, `libmetalirconverter.dylib`, GPTK, and D3DMetal.

**Reason:** Madeira's license/build notes identify Apple's Metal Shader Converter as proprietary and bundled into its D3D12 path. The user requires open-source components only and explicitly bars Apple's proprietary game-porting graphics stack.

## 2026-10-13 — Retain FEX; defer Box64/MoltenVK
**Decision:** Retain Madeira's FEX/ARM64EC translator and DXMT-to-Metal graphics layer for first bring-up. Defer Box64, MoltenVK, DXVK and VKD3D-Proton.

**Reason:** Madeira already couples the translator to iOS Wine in one process and uses an iOS-native D3D-to-Metal layer. Box64 is a Linux-user-space translator, and MoltenVK does not by itself prove DXVK works with iOS Wine.

## 2026-10-13 — Cloud builds only
**Decision:** No local compilation or SDK/toolchain installation. Use the project’s staged build chain on GitHub Actions macOS runners, placing local source, caches, downloads and artifacts on J:.

**Reason:** C: has 0.15 GB free. The user requires cloud builds and macOS is the host platform for `xcodebuild` and Apple frameworks.

## 2026-10-13 — Import games through the Files folder picker
**Decision:** Copy a selected game folder into the app's `drive_c` using the iOS security-scoped folder URL, then open that folder in Madeira's existing executable browser.

**Reason:** The existing library stores relative paths inside `drive_c` and resolves them against its Wine prefix. Persisting a bookmark to external files would require rewriting that path and launch model. Copying provides a working sandbox-compatible import and makes launch behavior consistent with the existing library.

## 2026-10-13 — Remove converter payloads from derived source and target
**Decision:** Stage deletion of the Apple Metal Shader Converter dylib and the Madeira D3D12 runtime/test binaries; remove their Xcode resource/signing phase. D3D12 is excluded from the first target. Build the derivative on a clean root Git commit with no upstream history.

**Reason:** Excluding the runtime only at packaging time would still leave the proprietary binary in the derived repository history. A clean root commit allows reuse of the open-source source state without making that binary reachable from the published repo.

**Result:** Created `c0e4ea5` as the single root commit, removed the upstream remote and stale local refs/stash, and pruned unreachable objects. `git rev-list --objects --all` contains no `libmetalirconverter.dylib`.

## 2026-10-13 — Remove D3D12-only app hooks from the first build
**Decision:** Remove the in-app shader converter canary call and declarations, and omit D3D12-only configuration entries from the generated Settings catalog and library session menu.

**Reason:** The canary was a hard link dependency on an object compiled only when the proprietary converter is available, which could prevent the allowed D3D9/10/11 build from linking. D3D12-only controls would also advertise functionality absent from this target.
