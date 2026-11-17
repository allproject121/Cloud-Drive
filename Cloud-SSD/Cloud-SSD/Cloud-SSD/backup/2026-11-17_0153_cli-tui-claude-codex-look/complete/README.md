# CMD ka naya look: Claude Code / Codex jaisa terminal shell

## Yeh kya hai?
`cloudssd` (ya `cpx`) CMD / PowerShell / Windows Terminal mein Cloud-SSD ka shell hai. 14 Nov ko pehla version bana tha
(sirf `cloudssd >` likh ke text). User ne kaha: "dhang se nahi bana, UI banao, Claude/Codex jaisa". Ab yeh unhi ki tarah dikhta
aur chalta hai.

## Kya kaam hua?
- **Swagat box** (gol kone): app chal raha hai ya nahi, kaun si drive (Y: Z:) judi hai, phone kab dikha, data folder.
- **Neeche input box** `> ` aur uske neeche ek line: chhote tips, daayein `● app on · Y: Z:`.
- **`/` dabao to commands ki list** khulti hai. Aage likho to chhoti hoti hai (`/st` → status, start, stop). ↑ ↓ se chuno,
  Tab se bharo, Enter se chalao, Esc se band.
- **Jawab Claude ki tarah:** `● Status` aur uske neeche `└` ke saath saaf line. Galti laal, chetavni peeli.
- **Spinner** jab command time le: `⠋ Reading the accounts… (3s · esc to stop)`. Esc se intezaar band.
- **Purane command** ↑ ↓ se wapas (band karke kholne par bhi yaad: `%LOCALAPPDATA%\Cloud-SSD\cli-history.txt`).
- **Galat likha** to: `I don't know "stauts"` → *Did you mean /status?*
- Ctrl+C line khaali karta hai, khaali line par do baar = bahar. Ctrl+L screen saaf.
- Purane shabd (`status`, `mounts`, `remotes`, `devices` …) aur ek-baar wale `cloudssd status` waise hi chalte hain.
- Pipe / file mein output saada ASCII (bina rang): `cloudssd status > a.txt`. `NO_COLOR=1` par rang band, frame rehta hai.
- Purane bug theek: PowerShell pipe ka BOM ("Unknown command: ﻿help"), `--home` sirf pehle nahi chalta tha,
  `accounts` poora AppHost chala deta tha (phone bridge port 8090 ka ERR, Z:/Y: dobara jodna, kabhi atak jaana) → ab sirf
  `rclone listremotes`.

## Kaise use hota hai?
CMD kholo → `cloudssd` likho → Enter. Phir `/` dabao.

## Andar se kaise chalta hai
```
cloudssd.cmd ─► cpx.exe ─► Program.Main
                            ├─ "secret ..." ───────────► bina kisi badlaav ke (rclone isse login kholta hai)
                            ├─ koi command ("status") ─► Views.* ─► saada / rangeen text ─► wapas
                            └─ kuch nahi ──► Shell (Claude jaisa)
                                   ├─ swagat box (2.5 s se zyada intezaar nahi)
                                   ├─ input box: har key par neeche ka hissa dobara banta hai
                                   │   (cursor upar → saaf → naya; Claude Code ka Ink bhi aise hi karta hai)
                                   ├─ "/" → CommandCatalog.Suggest → list
                                   └─ Enter → command alag thread par, spinner, phir "● Heading / └ jawab"
```
Files: `src\CloudSSD.Cli\Ansi.cs` (rang, chinh, chaudai), `Commands.cs` (commands ki list, `/` menu, "did you mean"),
`Views.cs` (har command ka jawab), `Shell.cs` (box, input, menu, spinner, history), `Program.cs` (shuru).

## Jaanch
- Build 0 warning / 0 error. C# tests poore pass (naye `tests\CloudSSD.Tests\CliTuiTests.cs`).
- Asli `conhost` (purani cmd window) mein chala ke photo: `C:\Users\Roshan\Downloads\Cloud-Drive\cli-tui-photos\` (git ke bahar,
  kyunki unme e-mail dikhte hain).
- `cpx secret emit-config-pass`: purane aur naye cpx ka output same (43 bytes, same SHA-256; secret dikhaya nahi gaya).
- `cpx deps` exit 0 (release script ka smoke test isi par chalta hai).

## Wapas kaise jaayein
- Installed app: `.work\cli-tui\old-cpx\cpx.*` ko `%LOCALAPPDATA%\Programs\Cloud-SSD\` mein copy karo
  (cpx band ho tab).
- Source: is backup ke `before\src\CloudSSD.Cli\` se `Program.cs` + `CloudSSD.Cli.csproj` wapas, naye
  `Ansi.cs`, `Commands.cs`, `Views.cs`, `Shell.cs` mitao; `tests\CloudSSD.Tests\CliTuiTests.cs` mitao aur test csproj se Cli ka
  reference hatao.
