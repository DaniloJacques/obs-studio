# OBS Studio — Performance-Optimized Build

> **Based on:** OBS Studio 32.0.x (`release/32.0`)
> **Built with:** Custom-compiled dependencies ([obs-deps fork](https://github.com/DaniloJacques/obs-deps))

---

## 🎯 Choose Your Build

| Build | Best For | CPU Requirement |
|-------|----------|-----------------|
| **`x64`** *(baseline)* | Maximum compatibility | Any x86-64 CPU with AVX2 (2013+) |
| **`x64-zen3`** | AMD Ryzen 5000+ / EPYC 7003+ | Zen 3 microarchitecture |
| **`x64-tigerlake`** | Intel 11th Gen+ (Tiger Lake) | AVX-512 + VNNI support |
| **`arm64`** | Windows on ARM devices | ARM64 / Snapdragon |

> [!TIP]
> **Not sure which one to pick?** Use the **`x64` baseline** — it runs on virtually all modern PCs.
> Pick `zen3` or `tigerlake` only if you know your CPU matches and want peak encoding performance.

---

## ⚡ What's Optimized

### OBS Studio Core
- Compiled with `-march=x86-64-v3` (AVX2 baseline) and `-mtune=generic`
- LTCG / Link-Time Optimization enabled for Release builds
- Dynamic dependency profile routing via `OBS_DEPS_PROFILE`

### Dependencies (the performance-critical part)
| Library | Optimization |
|---------|-------------|
| **x264** | ClangCL (x64) + `--enable-lto` + profile-specific `-march` |
| **SVT-AV1** | ClangCL + LTO + AVX-512 tuning (tigerlake) or Zen3-native |
| **FFmpeg** | Linked against the above optimized encoders |
| **Qt6** | Standard build (no arch-specific flags — UI doesn't need them) |

---

## 📦 Assets

### Installers
- `OBS-Studio-32.0.x-Windows-x64-Installer.exe` — Standard x64 baseline installer
- `OBS-Studio-32.0.x-Windows-x64-zen3-Installer.exe` — Zen3-optimized installer
- `OBS-Studio-32.0.x-Windows-x64-tigerlake-Installer.exe` — TigerLake-optimized installer

### Portable ZIPs
- `OBS-Studio-32.0.x-Windows-x64.zip`
- `OBS-Studio-32.0.x-Windows-x64-zen3.zip`
- `OBS-Studio-32.0.x-Windows-x64-tigerlake.zip`
- `OBS-Studio-32.0.x-Windows-arm64.zip`

---

## 📝 Changelog

<!-- Run: git log --oneline PREVIOUS_TAG..HEAD --no-merges -->
<!-- Only include commits since the LAST release, not the full history -->

```
<commits_placeholder>
```

---

## 🔧 Build It Yourself

```bash
# Clone
git clone https://github.com/DaniloJacques/obs-studio.git
cd obs-studio && git checkout release/32.0

# Configure (pick your profile)
cmake -B build -S . -DOBS_DEPS_PROFILE="zen3"    # For Zen3
cmake -B build -S . -DOBS_DEPS_PROFILE="tigerlake" # For TigerLake
cmake -B build -S .                                # For baseline x86-64-v3

# Build
cmake --build build --config Release
```

---

## ⚠️ Disclaimer

This is an **unofficial, performance-optimized fork**. It is not affiliated with the OBS Project.
For the official OBS Studio, visit [obsproject.com](https://obsproject.com).
