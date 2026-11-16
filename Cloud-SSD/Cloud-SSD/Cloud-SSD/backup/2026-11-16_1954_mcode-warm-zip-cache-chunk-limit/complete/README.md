# 2026-11-16_1954_mcode-warm-zip-cache-chunk-limit — Kaam ka summary

- **Agent:** MiniMax Code
- **TaskId:** TASK-MCODE-009
- **Status:** Validation Status: APPROVED (build 0 warning / 0 error, C# test **473/473**)
- **Complete hua:** 16-11-2026 20:02

## Trigger (user ka sawaal)

*"koi bhi zip file open karke test karo or check karo ki open ho raha hai ki nahi"*

## Asli gadda (2 layers)

### Layer 1 — `--vfs-cache-mode writes` me read **cache hote hi nahi**

rclone ke apne docs (v1.75.2, `rclone mount` → *VFS File Caching*):

> **writes** — In this mode files opened for **read only** are still read directly from the remote,
> write only and read/write files are buffered to disk first.

Matlab `writes` mode me jo bhi padha gaya, wo disk par **save hi nahi hota**. Isi liye:

- `ArchiveWarmer` ("Archive ready to open … 1.1 MiB fetched ahead") ka kaam **poora bekaar** tha — data
  aata tha aur turant fenk diya jaata tha. rclone log me: `vfs cache RemoveNotInUse … item
  Google AI Studio/Jarvis.zip not removed, freed 0 bytes`.
- Har naya open = naya network download = Google ke shared quota ki line me khadi.

### Layer 2 — `--vfs-read-chunk-size-limit 256Mi` chunk ko badhata raha

rclone har read par chunk size **double** karta hai (4 MiB → 8 → 16 → … → limit). Isi liye `full` mode
"zip kholte hi poora file utar deta tha" (TASK-MCODE-005 ka measurement: 460 MB, 38.8 s) — isliye us waqt
`writes` par switch kiya gaya tha.

## Asli gadda ka proof (aaj, isi machine par, 3 alag mount ke saath)

Har mount naya tha, cache khaali, same remote, same quota:

| Mount | 1 MB zip COLD | 460 MB zip COLD | 7 GB zip COLD | WARM (re-open) | Cache me data |
|---|---|---|---|---|---|
| `writes` (app ka purana setting) | 22,387 ms | 4,706 ms | 4,036 ms | 3,279 / 5,307 / 5,027 ms | **0 MB** |
| `full` + limit `256Mi` (app ka purana limit) | 4,596 ms | **38,383 ms** | 3,544 ms | 16 / 23 / 14 ms | 0.7 MB |
| **`full` + limit `4Mi` (ye fix)** | 13,038 ms | **4,328 ms** | 4,330 ms | **14 / 10 / 11 ms** | 0.8 MB |

Control run (`full` + 256 MiB) ne dikhaya ki **limit hi deciding factor hai**: wahi 460 MB zip ka end
padhna 38.4 s vs 4.3 s — 9 guna. Data dono cases me ~0.8 MB hi aaya (sparse file, is liye disk par
sirf wahi pada).

## Kya badla

1. `src/CloudSSD.Mount/MountPlanning.cs`
   - `--vfs-read-chunk-size-limit` ab **chunk size ke barabar** hai (4 MiB), 256 MiB nahi.
     Ab chunk kabhi double nahi hota → ek chhoti probe chhoti hi rehti hai.
   - chunk size ek hi variable se aata hai (`chunkSize`), taaki limit aur size kabhi alag na ho.
2. `src/CloudSSD.Desktop/ViewModels/CloudDrivesViewModel.cs`
   - Naya static helper `CacheModeFor(bool fastBrowsing)`.
   - **Toggle ka mapping palat diya gaya:** pehle "Fast browsing" ON = `writes` (kuch nahi rakhna —
     yaani **har** open dubara download = slow browsing). Ab ON = `full` (jo padha wo rakhna → dobara
     kholna instant), OFF = `writes` (kuch nahi rakhna).
   - Toggle ki initial state ab setting se aati hai (`FastBrowsing = mode != "writes"`).
3. `src/CloudSSD.Desktop/Views/CloudDrivesView.xaml`
   - Card ka text ab sach bolta hai: "On: the parts you open are kept on this PC, so opening the same
     archive or installer again is instant."
4. `tests/CloudSSD.Tests/CoreTests.cs`
   - Naya test `Fast_browsing_keeps_the_file_locally_and_switching_it_off_keeps_nothing`.
   - `The_mount_reads_in_big_chunks_and_refreshes_the_listing` me ab `--vfs-read-chunk-size-limit 4Mi`
     ka bhi assertion hai.
   - `The_drive_mode_chooses_how_a_file_is_cached` ka comment naya sach ke mutabiq likha gaya.
   - **473/473** (pehle 472).

## Runtime

`%LOCALAPPDATA%\Cloud-SSD\settings.json` → `Cache.VfsCacheMode = "full"`.

## Proof (naya install, asli Z: drive par)

Live flags: `--vfs-cache-mode full --vfs-read-chunk-size 4Mi --vfs-read-chunk-size-limit 4Mi`

Teen **fresh** zips (cache me pehle se nahi):

| Zip | COLD (pehli baar) | WARM (dobara) | WARM2 (teesri baar) |
|---|---|---|---|
| Jarvis.zip (0.06 MB) | 25,421 ms | **116 ms** | 106 ms |
| MYRA_Android16_Updated_Project.zip (5 MB) | 3,884 ms | **48 ms** | 19 ms |
| MYRAA MOBLIE (2).zip (25 MB) | 40,140 ms | **20 ms** | 20 ms |

Dobara kholna ab **local disk jaisa** (20–116 ms). Pehli baar ka wait abhi bhi Google ke **shared
quota** ki wajah se hai (log me `403 … RATE_LIMIT_EXCEEDED`, `pacer: Rate limited, increasing sleep to
16.9s`) — wo code se nahi, apni OAuth key se khatam hota hai.

Cache ka real disk usage poore drive ka: **67.4 MB** (sparse files — sirf jo padha wo).

## Release

`dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB),
SHA256 `05741b5931b4b826d0f0343cd2abd7b2e7bbdd92794a2124561d148e764d6919` — install ho chuka hai.

## Wapas kaise jayein (revert)

Run:
  tools\backup\backup.ps1 restore -Folder "2026-11-16_1954_mcode-warm-zip-cache-chunk-limit"
