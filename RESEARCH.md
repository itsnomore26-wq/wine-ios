# M1 Research Report — iOS Wine and Windows Games

Date checked: 2026-10-13

## Conclusion and base strategy

Use [Madeira](https://github.com/willfaust/Madeira) as the initial base. It is the only project found in this pass that combines an iOS-hosted Wine fork, x86-64 translation, Windows guest applications, Direct3D-to-Metal rendering, a non-jailbroken sideload path, and an iOS 27 in-app JIT setup in one maintained project. Its repository is GPL-3.0-or-later with component notices, so redistribution can be done under its stated copyleft terms. Keep the combined project open source.

Build a reduced, license-clean target first: Wine/ARM64EC + FEX + DXMT for D3D9/10/11 + iOS app/JIT. Do not package Apple's Metal Shader Converter or Madeira's D3D12 path. Madeira's docs identify the converter as Apple proprietary software; the user explicitly requires open-source components and forbids bundling GPTK/D3DMetal. D3D12 remains deferred unless an all-open-source route is proven.

This is a base selection, not proof that our build or iPhone 17 run works. The upstream repository's clean-build record reports missing or unverified inputs and unreachable submodule commits as of its 2026-09-16 audit. We must reconcile those and run the pipeline from a clean GitHub checkout before treating any IPA as our deliverable.

## Candidates

### Madeira — selected for evaluation

- Official repository: https://github.com/willfaust/Madeira
- Current project README describes Wine 11.4 ARM64EC, FEX x86/x86-64 translation, DXMT D3D9/10/11-to-Metal, wineserver as a thread, game library, local game launch, touch/gamepad/controller support, and audio/video integration.
- Repository license is GPL-3.0-or-later plus a converter exception. Its notices list Wine LGPL-2.1-or-later, FEX/DXMT MIT upstream with separately identified modifications, rpmalloc 0BSD, and other bundled dependencies. We will preserve all notices and offer modified source as required.
- Project README says iOS 26+, and describes an iOS 27 self-pairing path for its bundled StikJIT helper. Release 0.1.3 (2026-10-03) documents iOS 27 in-app pairing and sideloading with a user Apple ID. SideStore's JIT page separately cautions that iOS 26.6/27 JIT works only with a limited app set; therefore Madeira's project-specific claim needs a real device check on this target.
- The release reports several games reaching gameplay, with broad compatibility/performance variance. Those are upstream author claims, not our device results. A GitHub issue also reported local EXE launch errors on an earlier release; local Files import/launch must be validated and fixed for our use case.
- Build risk: upstream's `docs/BUILDING.md` explicitly says a clean recursive clone did not build as of 2026-09-16; custom FEX/Wine/DXMT forks and some build inputs were unavailable/unverified. The current branches and current release need re-auditing. Build the native chains in stages on macOS Actions, cache by pinned inputs, and never claim success until an IPA is present and smoke checks pass.

### Juice — rejected for licensing

- Official repository: https://github.com/ExoCore-Kernel/Juice
- Technically close: iOS Wine, native ARM64 Windows and experimental FEX x86-64/WoW64 work, app/UI, and device proof.
- Its `LICENSES/README.md` says Juice-original app, launchers, scripts and related code are all rights reserved with no open-source license granted. Do not use, redistribute, or build our product from that code.

### Box64 iOS experiments — not the base

- Upstream Box64: https://github.com/ptitSeb/box64 (MIT).
- The Box64 iOS static-library adaptation: https://github.com/cloverfield11/box64-ios-library (MIT according to its GitHub license). Its own README describes rendering a Linux x86-64 Powder Toy test at about 4.5–5 FPS through a MetalGL bridge.
- Box64 translates Linux user-space programs and expects Linux host libraries. That project does not supply an iOS Wine runtime or demonstrate Windows `.exe` compatibility. Madeira already has the Wine-specific FEX/ARM64EC route, so Box64 is not added alongside it without a concrete build/runtime advantage.

### Wine and graphics layers

- Wine upstream: https://gitlab.winehq.org/wine/wine (LGPL; preserve source and notices). Wine alone does not translate x86-64 game machine code to ARM64; this requires FEX or another supported translator.
- FEX-Emu: https://github.com/FEX-Emu/FEX; Madeira uses its iOS-focused fork and ARM64EC integration.
- MoltenVK: https://github.com/KhronosGroup/MoltenVK, Vulkan-to-Metal portability layer. Its existence does not prove that DXVK works in an iOS Wine process. Madeira's DXMT directly maps D3D9/10/11 to Metal, which is a better fit to validate first.
- VKD3D-Proton/D3D12 adds another translation and API surface. Madeira's current D3D12 route depends on Apple's proprietary Metal Shader Converter; it is omitted from our open-source-only package.

## iOS 27 JIT and sideload findings

- [Madeira JIT documentation](https://github.com/willfaust/Madeira/blob/main/docs/JIT.md) says its iOS 27 route pairs the phone with the app itself through Developer Mode and uses a helper extension; LocalDevVPN is still used to reach the device debug service. It also states that the app must be signed as debuggable and that sideloaders must retain the helper extension.
- [Madeira 0.1.3 release](https://github.com/willfaust/Madeira/releases/tag/v0.1.3) says the IPA is ad-hoc signed with entitlements and a sideloader signs it for the user's device. Free Apple ID signing expires after seven days according to the project README.
- [StikJIT integration guide](https://github.com/StikDebug/StikJIT/blob/main/INTEGRATION.md) says modern TXM/SPTM systems require the JIT allocator to prepare executable regions through its debugger protocol; debugger attachment alone is insufficient for an arbitrary JIT.
- [SideStore JIT status](https://docs.sidestore.io/docs/advanced/jit) (updated 2026-06-17) says iOS 26.6 and 27 work with only a limited list of apps. It predates Madeira 0.1.3 and is a reason to test Madeira specifically, not a reason to claim all JIT apps work.
- iPhone 17/iOS 27 has not been physically tested by us. No install, JIT, game, performance, or compatibility result is claimed in this report.

## Milestone evidence and status

M1 is complete as a research/strategy milestone, based on the linked primary repositories, build notes, JIT guide, release notes, and issue tracker. M2–M7 remain in progress/not started. The next concrete work is to fetch Madeira with all Git submodules, resolve its clean-clone build gaps, remove all D3D12/Apple converter packaging, and prepare an unsigned IPA workflow on macOS runners. No IPA has been created in this workspace.
