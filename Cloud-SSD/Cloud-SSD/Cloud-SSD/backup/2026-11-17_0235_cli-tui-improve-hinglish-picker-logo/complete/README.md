# CMD shell aur behtar: Hinglish samajhna, Yes/No sawaal, drive chunna, logo

## Yeh kya hai?
`cloudssd` / `cpx` ka Claude Code jaisa shell (pichhla kaam: `backup\2026-11-17_0153_cli-tui-claude-codex-look`).
User ne kaha "isko improve karo". User Hinglish likhte hain aur command ke naam yaad rakhna mushkil hai, isliye yeh badlaav kiye.

## Kya kaam hua?
1. **Seedha bolo (English / Hinglish / Hindi):**

   | Likho | Chalta hai |
   |---|---|
   | z drive kholo · y drive open karo | /open Z: · /open Y: |
   | drive kholo | sawaal: kaunsi drive? (Y: / Z:) |
   | phone dikhao · फोन दिखाओ | /phone |
   | kitni jagah bachi hai | /cache |
   | google account dikhao | /accounts |
   | kya haal hai | /status |
   | app band karo · safai karo | /stop · /clean (pehle Yes/No) |

   Shell neeche `→ /cache` dikhata hai, taaki chhota naam bhi yaad ho jaye. Yeh AI nahi hai, sirf shabdon ki shuruaat milata hai,
   isliye turant aur hamesha ek jaisa chalta hai. "drive band karo" se app band **nahi** hota.
2. **Yes / No sawaal** (Claude ke permission box jaisa) `/stop` aur `/clean` se pehle. **"No" pehle se chuna** hota hai, isliye
   galti se Enter dabne par kuch nahi badalta. ↑↓ ya 1 / 2 se chuno, Esc = cancel.
3. **`/open ` likhte hi drives ki list**: Y: Each Account, Z: All Accounts. Jo drive judi nahi hai, uske saath "not connected now" likha aata hai.
4. **Bada rangeen CLOUD-SSD logo** (teal se blue) swagat box mein.
5. Chhoti cheezein: 1 second se lambe jawab ki heading mein samay; heading mein faltu shabd nahi ("Phones dikhao" nahi, sirf "Phones");
   cache mein "30 days" / "5 s" ("30.00:00:00" ki jagah).
6. Command line se bhi: `cloudssd drive kholo` chalta hai. Par band / delete karne wale vaakya wahan **kabhi nahi** chalte
   (script mein Yes/No ka jawab dene wala koi nahi). Saaf sandesh aata hai: "type it exactly: cloudssd stop".

## Kaise use hota hai?
CMD kholo → `cloudssd` → Enter. Phir `/` dabao, ya seedha likho: `phone dikhao`.

## Andar se kaise chalta hai
```
likha: "z drive kholo"
   │
   ├─ CommandCatalog.Find("z")       → koi command nahi
   └─ CommandCatalog.Understand(...) → "khol" mila = open, "z" = drive letter → /open Z:
          │
          ├─ Confirm wala command (stop / clean)? → Shell.Choose: Yes/No box ("No" pehle se) → No / Esc = kuch nahi
          ├─ /open bina letter? → Shell.Choose: kaunsi drive
          └─ chalao → spinner → "● Open Z:" + "└ ..."
```
Files: `src\CloudSSD.Cli\Logo.cs` (naya), `Commands.cs` (`Understand`, `Confirm`, `ArgMenu`), `Shell.cs` (`Menu`, `Choose`,
`BuildChoice`, `ConfirmFor`, `Choices`, `Draw`), `Views.cs` (`Span`, help), `Program.cs` (command line par Hinglish), `Ansi.cs`.

## Jaanch
- Build 0 warning / 0 error; C# **547/547**; `backup.ps1 validate` APPROVED. CLI tests 39 → 70.
- Naya `cpx.*` installed app (`%LOCALAPPDATA%\Programs\Cloud-SSD`) mein. `cpx secret emit-config-pass` (rclone isi se login kholta hai)
  ka output purane jaisa hi hai: 43 bytes, same hash.
- Asli conhost window mein installed `cloudssd` ki photo: `C:\Users\Roshan\Downloads\Cloud-Drive\cli-tui-photos\` (git ke bahar,
  kyunki unme e-mail dikhte hain). `/stop` ke sawaal par Esc → "Nothing was changed"; app ka PID pehle aur baad mein same (13768).

## Wapas kaise jaayein
- Source: is backup ke `before\src\CloudSSD.Cli\` aur `before\tests\CloudSSD.Tests\CliTuiTests.cs` wapas copy karo, `src\CloudSSD.Cli\Logo.cs`
  mitao. README ka CLI hissa `before\README.md` se.
- Installed app: pichhle kaam ka `cpx` chahiye to Cli ko us source se publish karke `cpx.*` copy karo (cpx band ho tab).
