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

Latest check after CI pipeline draft and source audit (2026-10-13): C: 638,234,624 bytes free (about 609 MiB); J: 95,947,321,344 bytes free (about 89.3 GiB). C: free space is above the session start. The redundant archive extraction/download were removed from `source/` and `downloads/`; the canonical checked-out tree remains under `project/`. No local build was run.

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
- Added a GitHub Actions draft for cloud builds, later split into toolchain, runtime, and Xcode packaging jobs. The staged outputs and logs transfer as short-retention artifacts. It defaults to `xcode-27-arm64` and offers `macos-26` as a manual runner fallback. This workflow has not been pushed or run; upstream's clean macOS build steps are partly unverified.
- Removed the absent Microsoft VC++ runtime folder from Xcode resources. No Microsoft runtime binaries are included; games depending on those DLLs may require user-supplied official files or a Wine builtin.
- Static source review only so far. No local build or tests have been run. The derivative is a clean history rooted at `c0e4ea5`, with the four pinned submodules. The original upstream remote/ref and stash were removed and unreachable objects pruned; `git rev-list --objects --all` found no `libmetalirconverter.dylib`. No IPA, workflow run, device test, JIT test or game test exists.

### Next
1. Audit the draft macOS build script against every stage's input/output and refine the unverified Wine/LLVM/DXMT configuration.
2. Create/push the derived GitHub repository and run the three-stage workflow; fix failures until a real IPA exists.
3. Scan the successful IPA for proprietary Apple converter/GPTK/D3DMetal/D3D12 payloads and record its SHA-256.
4. Test on the iPhone 17 with JIT and the Files importer, then run the x86-64 and x86 hello-world EXEs.
5. Test free/legal game demos and document measured results; address runtime dependencies and polish.

### Evidence links
- Juice: https://github.com/ExoCore-Kernel/Juice
- Juice build notes: https://github.com/ExoCore-Kernel/Juice/blob/main/docs/BUILDING.md
- SideStore JIT status: https://docs.sidestore.io/docs/advanced/jit
- StikJIT integration protocol: https://github.com/StikDebug/StikJIT/blob/main/INTEGRATION.md
- Box64: https://github.com/ptitSeb/box64
- MoltenVK: https://github.com/KhronosGroup/MoltenVK

### CI refactor and disk check (2026-10-13)
- Split cloud build into three independent runner stages: pinned LLVM/llvm-mingw toolchains, Wine/FEX/DXMT runtime, then Xcode unsigned packaging. Toolchain/runtime payloads and logs transfer through short-lived Actions artifacts; each heavy stage has its own cache key. Default runner remains `xcode-27-arm64`, with `macos-26` dispatch fallback.
- The tar payload uses repository-relative paths and includes llvm-mingw, the iOS LLVM build (headers and static libraries), and LLVM headers required by later runtime steps.
- Current disk check: C: 632,098,816 bytes free; J: 95,845,990,400 bytes free. C: had a small free-space fluctuation; two recent multi-megabyte temporary files were observed under Windows Temp, one disappeared while inspecting and another was locked by an active process. TEMP/TMP for this work remain redirected to `_env/temp`; no local build/toolchain install occurred. J: free space is unchanged.
- Workflow has not been pushed or run. Portable Git is at `_env/tools/git/cmd/git.exe`; source branch remains `main`, with the three-stage workflow commit in `6abeb4d`.
- Next: complete GitHub device authorization, create/push the repo, then debug cloud run.

### Latest check (2026-10-13)
- Three-stage cloud build refactor committed as `6abeb4d` (`Split cloud build into cached stages`). `git diff --cached --check` passed before commit; repository working tree is clean.
- Latest disk check after commit: C: 629,772,288 bytes free; J: 95,845,965,824 bytes free. The Windows Temp fluctuation continues and contains an active locked temporary file; the process creating it has not been identified. All project-specific TEMP/TMP and tool caches remain redirected to J:. No local build ran.
- GitHub CLI device sign-in is still waiting. `gh auth status` reports no logged-in hosts, so repo creation, push, and cloud execution cannot start yet. The existing pending device approval uses code `E549-6897` at https://github.com/login/device.
- Latest disk check after documentation refresh: C: 628,133,888 bytes free; J: 95,845,941,248 bytes free. Free space fluctuates with Windows-managed temporary files; all project tool temp/cache variables remain on J:.
- Next: complete that device approval, then create/push `wine-ios` and run the workflow.

### Authorization poll (2026-10-13)
- GitHub CLI login process 19568 remains live and waiting for device approval; both configured GH_CONFIG_DIR locations report no signed-in host. No repo exists remotely and no workflow can run until authorization completes.
- Latest disk check: C: 626,769,920 bytes free; J: 95,845,920,768 bytes free. `project` working tree was clean after commits `6abeb4d` and `b9c3254`; no local build ran.

### GitHub repository and first cloud workflow (2026-10-13)
- Device sign-in completed; verified GitHub account `itsnomore26-wq`. Created public repository https://github.com/itsnomore26-wq/wine-ios and pushed local `main` at `aff8c7ad301ffe236aebe0ff2c4155214cc0c7f0`. The branch exists remotely.
- Push triggered Actions run 38445151315: https://github.com/itsnomore26-wq/wine-ios/actions/runs/38445151315. At latest poll the toolchains job was queued. No cloud build result or IPA exists yet.
- Latest disk check after repository creation/push: C: 612,814,848 bytes free; J: 95,845,900,288 bytes free. Both remain within workspace constraints overall; no local compilation or SDK install occurred.

### Runner fallback attempt (2026-10-13)
- Primary Actions run 38445151315 on `xcode-27-arm64` remained queued for over five minutes. GitHub's runner-images public-preview announcement documents known queueing issues for the Xcode 27 image. Cancelled the queued run and dispatched the same workflow on its `macos-26` fallback.
- Fallback run 38445942774 now has a macOS runner. The toolchains job setup completed and recursive checkout is in progress. No build step has started and there is still no IPA.
- Disk check: C: 625,090,560 bytes free; J: 95,845,900,288 bytes free. No local build occurred.
- Evidence: https://github.com/actions/runner-images/issues/14404 and https://github.com/itsnomore26-wq/wine-ios/actions/runs/38445942774.
- Latest observed C: free space after starting the runner: 621,588,480 bytes; J: 95,845,900,288 bytes. The small C: fluctuation is Windows-managed temp churn; project temp variables still point to J:.
- Current action state: checkout and cache restore succeeded; `Build compiler toolchains` is actively running on macOS 26.

### First cloud build failure and source pin fix (2026-10-13)
- Fallback Actions run 38445942774 started on macOS 26, completed checkout/cache setup, then failed in `Build compiler toolchains` with exit code 128. Saved the complete job log to `artifacts/run-38445942774-toolchains.log`.
- Root cause: LLVM commit was pinned using abbreviated SHA `8dfdcc7b7`; `git fetch` rejected it as a remote ref. GitHub API resolved the exact commit to `8dfdcc7b7bf66834a761bd8de445840ef68e4d1a`. Updated the build pin to the full SHA.
- Updated workflow concurrency keys to include runner choice so Xcode 27 preview queueing cannot prevent a macOS 26 retry from starting.
- This fix is not yet pushed or cloud-verified. No IPA exists.

### Latest cloud retry status (2026-10-13)
- Commit `576ef9c` containing the full LLVM SHA and runner-specific concurrency was pushed to `main`. GitHub started fallback workflow run 38446897517; its `macos-26` toolchains job has a runner and recursive checkout is still active. The automatic Xcode 27 run 38446889997 remains separate/queued.
- Latest disk check: C: 621,002,752 bytes free; J: 95,845,662,720 bytes free. All job logs and downloaded materials are stored under `artifacts/`; no local build was run.
- No IPA exists yet. Check whether the compiler-stage cache was restored after the first failed run, then continue from toolchains to runtime and package.

### Second cloud build failure and LLVM patch correction (2026-10-13)
- Run 38446897517 failed in the toolchain job after successfully fetching/checking out the full LLVM commit. The next guard failed: pinned `AddLLVM.cmake` contains two `MATCHES "Darwin"` branches (Apple exported-symbol handling and Apple dead-strip handling), while the script expected one.
- Saved full log to `artifacts/run-38446897517-toolchains.log`. Updated the patch to verify both expected matches and apply `Darwin|iOS` to each.
- Latest disk check: C: 616,284,160 bytes free; J: 95,845,445,632 bytes free. No local build ran.
- Next: push this patch and retry the macOS 26 toolchain stage; continue into runtime and packaging after it passes.
