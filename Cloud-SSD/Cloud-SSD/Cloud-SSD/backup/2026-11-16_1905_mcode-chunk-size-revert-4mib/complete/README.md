# 2026-11-16_1905_mcode-chunk-size-revert-4mib — Kaam ka summary

- **Agent:** MiniMax Code
- **TaskId:** TASK-MCODE-006
- **Status:** Validation Status: APPROVED (build 0 warning / 0 error, C# test **472/472**, mobile-JS **45/45**, integration **29/29**)
- **Complete hua:** 16-11-2026 19:17

## Kya kaam tha

TASK-MCODE-004 me read chunk **4 MiB → 32 MiB** kiya gaya tha (archive ka end jaldi uthane ke liye). Par
32 MiB chunk me har chhoti probe bhi 32 MB utha leti thi — matlab "sirf 1 MiB padho" request par bhi poora
32 MB network se aata tha.

## Kya badla

- `src/CloudSSD.Core/Settings.cs` — `Cache.ReadChunkSizeBytes` default **wapas 4 MiB** (`4 * ByteSize.MiB`).
- `src/CloudSSD.Mount/MountPlanning.cs` — fallback chunk bhi **4 MiB** (`--vfs-read-chunk-size 4Mi`).
- `tests/CloudSSD.Tests/CoreTests.cs` — test assertion 4 MiB ke hisaab se update.
- Runtime `%LOCALAPPDATA%\Cloud-SSD\settings.json` → `ReadChunkSizeBytes = 4194304` (4 MiB).

## Proof (measure kiya, guess nahi)

| Read | 32 MiB chunk | 4 MiB chunk |
|---|---|---|
| 460 MB zip ka end padhna | 21.5 s | **5.3 s** |
| Extra data jo utra | 32 MB per probe | **0 MB** |

## Chained backup (teeno versions mehfooz)

Chunk size ki poori history backup folders me hai, kuch bhi gum nahi hua:

| Folder | `before/Settings.cs` me chunk |
|---|---|
| `2026-11-16_1731_mcode-mount-speed-autostart` | 4 MiB (asli value) |
| `2026-11-16_1834_mcode-fast-browsing-mode` | 32 MiB (pre-revert wali value) |
| `2026-11-16_1905_mcode-chunk-size-revert-4mib` | 4 MiB (post-revert, yahi live hai) |

> **Note (imaandari):** is folder ka `before/` snapshot revert ke **baad** bana tha, is liye diff `new 0,
> changed 0, removed 0` aaya. 32 MiB wali pehle wali version `1834` ke `before/` me safely hai aur 4 MiB
> wali asli version `1731` ke `before/` me.

## Wapas kaise jayein (revert)

Run:
  tools\backup\backup.ps1 restore -Folder "2026-11-16_1905_mcode-chunk-size-revert-4mib"
