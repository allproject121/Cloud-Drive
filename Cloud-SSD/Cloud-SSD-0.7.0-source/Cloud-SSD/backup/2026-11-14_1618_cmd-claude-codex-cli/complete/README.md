# Cloud-SSD Interactive Terminal & CLI (Claude & Codex Style)

## Yeh kya hai?
Yeh kaam Cloud-SSD ko Windows CMD (Command Prompt) aur PowerShell mein bilkul **Claude Code (`claude`)** aur **Codex (`codex`)** ki tarah ek interactive terminal experience deta hai.

## Kya kaam hua?
1. **Global Access (CMD mein bina path ke chalna):**
   - `C:\Users\Roshan\.local\bin` (jahan `claude.exe` rehta hai) mein `cloudssd.cmd` aur `cpx.cmd` shims dale gaye.
   - Windows User PATH mein `%LOCALAPPDATA%\Programs\Cloud-SSD` add kiya gaya.
   - `installer\cloudssd.cmd` banaya gaya aur `Install-CloudSSD.ps1` me user PATH auto-register kiya gaya.
2. **Interactive Terminal REPL Mode:**
   - Jab user sirf `cloudssd` type karta hai, to ek clean ASCII banner, quick live vitals summary aur `cloudssd > ` prompt open hota hai.
   - User seedhe bina baar-baar command prefix likhe andar commands chala sakta hai:
     - `status` (s)
     - `open [letter]`
     - `mounts` (drives)
     - `remotes` (accounts)
     - `phone` (devices)
     - `cache`
     - `clean`
     - `mirror` (sync)
     - `start` / `stop`
     - `deps`
     - `clear` (cls)
     - `help` (?)
     - `exit` (quit, q)
3. **One-Shot Direct Command Mode:**
   - User direct CMD se `cloudssd status`, `cloudssd phone`, `cloudssd open Z:`, `cpx status` chala sakta hai.

## Kaise use hota hai?
- CMD khol kar type karein: `cloudssd` (Interactive Mode)
- Ya direct: `cloudssd status`

## Badli gayi files:
- `src\CloudSSD.Cli\Program.cs`
- `installer\cloudssd.cmd`
- `installer\Install-CloudSSD.ps1`
- `installer\build-release.ps1`
- `C:\Users\Roshan\.local\bin\cloudssd.cmd`
- `C:\Users\Roshan\.local\bin\cpx.cmd`

## Jaanch (Verification):
- `cmd /c "cloudssd status"` — PID 20532, Y:\ 14.95 TiB, Z:\ 14.95 TiB, Cache 122 GiB free, accounts, phone online.
- `cmd /c "cloudssd phone"` — vivo I2221, PAIRED, active details.
- `cmd /c "cloudssd cache"` — budget and free space info.
- `cmd /c "cloudssd mirror"` — mirror and offload status.
- Pipe interaction test — prompt, help, status, exit clean.
- Unit tests: 464 tests passed (0 failed).

## Wapas kaise jaayein (Rollback):
Agar wapas jaana ho to is backup ke `before\` folder se `src\CloudSSD.Cli\Program.cs` ko replace karein, aur `.local\bin\cloudssd.cmd` mita dein.
