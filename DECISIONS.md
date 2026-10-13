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

## 2026-10-13 — Split the unsigned build into runtime and package jobs
**Decision:** Build native dependencies on a cached macOS runtime job, transfer only the generated app runtime payload as an Actions artifact, and package the unsigned IPA in a second Xcode job. Use the Xcode 27 runner by default with macOS 26 as a manual fallback.

**Reason:** LLVM, Wine, FEX and DXMT stages can take hours and should reuse cloud caches. Keeping Xcode packaging separate preserves the heavy stage outputs across runner boundaries and makes its logs/artifact easier to inspect. The workflow has not yet been run.

## 2026-10-13 — Do not bundle Microsoft VC++ runtime files
**Decision:** Remove the missing `x86_64-vcruntime` resource reference and leave Microsoft's runtime DLLs out of the derivative package.

**Reason:** Microsoft's redistribution terms limit distribution to licensed Visual Studio users and require eligible files to remain unmodified. No Visual Studio license or user-supplied runtime files are available in this workspace. Games that require those DLLs may need the user to provide official files or work with Wine builtins.

## 2026-10-13 — Split build into three cloud stages
**Decision:** Separate pinned compiler toolchains, Wine/FEX/DXMT runtime, and unsigned Xcode packaging into three GitHub Actions jobs. Transfer toolchain/runtime outputs as short-retention artifacts and maintain stage-specific caches.

**Reason:** LLVM static libraries and llvm-mingw setup add substantial time to the Wine/runtime build. Three separately cached jobs make runner timeouts more manageable and keep packaging failures diagnosable. The workflow remains unverified until the first cloud run.

## 2026-10-13 — Use macOS 26 after Xcode 27 runner queue stall
**Decision:** Cancel the Xcode 27 preview run after it remained queued for more than five minutes and dispatch the same workflow on the configured macOS 26 fallback. Keep Xcode 27 as the primary target for a later run.

**Reason:** GitHub's Xcode 27 preview announcement documents runner queueing issues during capacity balancing. The fallback runner can establish whether the cloud build stages otherwise execute and may compile the app with the available SDK. Workflow run: https://github.com/itsnomore26-wq/wine-ios/actions/runs/38445942774.

## 2026-10-13 — Pin LLVM by full commit SHA
**Decision:** Replace the abbreviated LLVM pin with full commit `8dfdcc7b7bf66834a761bd8de445840ef68e4d1a` and include the runner selection in each workflow concurrency group.

**Reason:** First cloud toolchain attempt failed because GitHub did not accept the abbreviated hash as a fetchable remote ref. The official GitHub API resolves the full SHA and title. Runner-specific concurrency allows the macOS 26 fallback to run while the Xcode 27 preview lane is queued.
