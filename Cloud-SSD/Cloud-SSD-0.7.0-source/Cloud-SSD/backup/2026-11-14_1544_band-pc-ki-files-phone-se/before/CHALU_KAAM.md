# CHALU KAAM: jo kaam abhi chal raha hai (Claude aur Codex dono ke liye)

Yeh file isliye hai ki kaam beech mein ruk jaye (token / usage limit khatam, session band, PC band) to jo bhi
agla session aaye, Claude ho ya Codex, wahin se kaam uthaye. Kuch dobara na ho, kuch toote nahi.

**Niyam:** kaam shuru karne se pehle yeh file padho. Har chhota kadam poora hote hi neeche "Abhi ka haal" badlo
(2 minute ka kaam hai; yahi sabse zaroori hai). Token kam lage to naya kaam mat chhedo: pehle yeh file likho.

Project: `C:\Users\Roshan\Downloads\Cloud-Drive\Cloud-Drive\Cloud-SSD\Cloud-SSD-0.7.0-source\Cloud-SSD`
(git ki jad do folder upar; branch `feature/multi-device`; GitHub repo private hai).

---

## 1. Naya session aaye to sabse pehle (5 minute)

1. Yeh file poori padho, khaaskar "Abhi ka haal".
2. `git status --short` (git ki jad se). Jo files badli dikhें woh pichhle session ka adhoora kaam hai.
3. `backup\` mein sabse naya folder dekho:
   - usme sirf `before\` hai, `complete\` nahi → **kaam adhoora hai**. `before\` ko mat chhuo.
   - `complete\README.md` hai → woh kaam poora ho chuka.
4. Build aur test chalao (neeche "Jaanch"). Laal ho to pehle wahi theek karo, naya kuch mat likho.
5. "Abhi ka haal" ke "Agla kadam" se aage badho.

## 2. Kaam adhoora ho to kya karna hai

- **Aage badhana (aam taur par yahi):** adhoori files project mein hi padi hain. "Abhi ka haal" mein likha hota hai
  kaunsi file kahan tak hui. Wahin se poora karo. Naya backup **mat** lo (`before\` pehle se hai).
- **Samajh na aaye / sab toot gaya ho:** us kaam ke `backup\<folder>\before\` se wahi files wapas copy karo
  (sirf woh files jo "Abhi ka haal" ki list mein hain), phir kadam dobara karo.
  Wapas karne se pehle `git stash` ya adhoori files ki copy `.work\adhoora\` mein rakh lo. Kabhi `git reset --hard`
  ya `git checkout -- .` mat chalao: usse doosre ka kaam bhi ud jata hai.
- `complete` tab hi banao jab kaam ban gaya ho **aur** asli PC + asli phone par jaanch ho gayi ho.

## 3. Backup ka niyam (user ka pakka niyam)

- Naya kaam shuru karne se **pehle**:
  `powershell -File tools\backup\backup.ps1 start -Name "<kaam ka naam>"`
  → `backup\<tareekh_samay>_<naam>\before\` banta hai. Ise kaam ke dauraan kabhi mat chhuo.
- Kaam ban kar jaanch ho jaye tab:
  `powershell -File tools\backup\backup.ps1 complete -Folder "<folder>" -Files a,b,c`
  phir `complete\README.md` saral Hinglish mein likho: yeh kya hai, kya kaam hua, kaise use hota hai,
  andar se kaise chalta hai (chhota teer wala chitr), files, jaanch, wapas kaise jaayein.
- Ek kaam = ek backup folder. Adhoore kaam ke liye doosra `start` mat chalao.

## 4. Kaam kaise karna hai

- Chhote kadam. Har kadam: code → build → test → (ho sake to asli device par dekho) → yeh file badlo.
- Ek phase poora = asli phone + asli PC par jaanch, saare bug aur warning theek. Tabhi agla phase.
- User se har phase ke beech permission mat poocho; sirf wahan ruko jahan uske haath chahiye (jaise Google key).
- Jawab saral Hinglish mein. User technical naam nahi jaanta; uska matlab samjho.
- **Commit / push sirf jab user kahe.** Push: `git add -A -f .` → niji cheezon ki jaanch
  (`node .work\scan-staged.js roshan rosha I2221` git ki jad se; `backup\*\before\` ke andar ke hit purani files hain)
  → commit → `git push origin HEAD:feature/multi-device HEAD:main`.
- **Kuch bhi Claude app / claude.ai / cloud par nahi:** koi Artifact, Doc, share link, cloud session nahi.
  Design ya report hamesha is PC par file (HTML / MD / PNG) aur user ko poora raasta batao.

## 5. Yeh galtiyan ho sakti hain (pehle ho chuki hain)

| Galti | Bachao |
|---|---|
| `src\CloudSSD.Desktop\App.xaml.cs` badal dena | Ise **kabhi mat chhuo**. |
| Phone page ki do copy alag ho jana | `mobile-android\src\main\assets\*` aur `src\CloudSSD.Desktop\wwwroot\mobile\*` hamesha ek jaise. Assets mein badlo, phir wwwroot mein copy karo. |
| Call ke waqt ya doosre app mein phone ko chhoo dena | adb se kuch bhi bhejne se pehle: `mCallState=0`, phone khula (`mDreamingLockscreen=false`), saamne `com.cloudssd.mobile`. `tools\live-test\phone.ps1` yeh khud dekhta hai; usi se kaam karo. PIN kahin likha nahi hai. |
| User ka look / bhasha badal dena | Pehle `localStorage cloudssd_look` padho, test ke baad wahi wapas rakho. |
| User ki jagah permission ka "Allow" dabana | Kabhi nahi. User khud dabata hai. |
| `node -e "..."` ya `sed` mein ulte slash / quote | Shell tod deta hai. Patch ko `.work\<naam>.js` file mein likho, phir `node` se chalao. |
| PowerShell 5.1 mein `2>&1` ke saath build-apk | javac ka purana note error ban jata hai; `2>&1` mat lagao. |
| PowerShell mein script ke output par `Select-Object -First N` | Script beech mein mar jati hai. Pehle output variable mein lo. |
| Naye phone shabd bina anuvad ke | `tools\i18n\add-words.js <words.json>` se `i18n-words.js` mein jodo (dono copy). |
| rclone ko `C:\` jaisa raasta dena | Aakhri ulta slash mat do; `C:/` likho. |
| Mirror apne aap poori disk upload karne lage | `Settings.Mirror.Paused = true` chhoda hai. User "Continue" dabayega. Test ke liye `Mirror.OnlyFolders` mein chhota folder do, baad mein khaali karo aur Drive ka test folder mitao. |
| Google ke token PC↔phone ke beech bhejna | Mana hai (LAN par saada HTTP). PC sirf client id/secret deta hai; phone khud sign-in karta hai. Google ka "revoke" kabhi mat bulao. |
| `Cloud-SSD Devices` folder Z:/Y: ya phone ke Cloud SSD tab mein dikhna | Chhupa rehna chahiye (permission ka chor darwaza). |
| Niji cheez GitHub par | PC ka asli naam, ghar ka IP, user ka naam, device id, e-mail source mein na jaye. |
| 100 MB se badi file push | `dist\*.zip` 95 MB ke aas-paas hai; 100 MB paar ho to push fail hoga. |

## 6. Jaanch (testing) kaise hoti hai

Sab commands project folder se:

```
dotnet build CloudSSD.slnx                      # 0 warning hona chahiye
dotnet test tests\CloudSSD.Tests                # C# tests (14 Nov ko 462 pass)
node --test tests/mobile-js/*.test.js           # phone page ke tests (44 pass)
powershell -File mobile-android\build-apk.ps1   # APK: .work\apk\Cloud-SSD-Mobile.apk
C:\Android\Sdk\platform-tools\adb.exe install -r .work\apk\Cloud-SSD-Mobile.apk
```

Asli phone (wireless adb chalu ho):
```
powershell -File tools\live-test\phone.ps1 -Launch -Js .work\<test>.js -Shot <naam>
```
JS file page ke andar chalti hai aur nateeja lautati hai; photo `.work\shots\<naam>.png`. Namoona: `.work\t-icons.js`.

Asli PC app:
```
powershell -File installer\build-release.ps1 -SkipTests        # dist\Cloud-SSD-0.9.0-win-x64
powershell -File tools\live-test\pc-close.ps1                  # app band (band na ho to user se kaho)
powershell -File dist\Cloud-SSD-0.9.0-win-x64\Install-CloudSSD.ps1 -Quiet
Start-Process "$env:LOCALAPPDATA\Programs\Cloud-SSD\Cloud-SSD.exe"
powershell -File tools\live-test\pc-shot.ps1 -Shot <naam> [-Press a,b]
```
PC app ka log: `%LOCALAPPDATA%\Cloud-SSD\logs\cloudplayx-<tareekh>.log` (rclone ke log mat chhaapo: unme file ke naam hain).

Jo jaanch nahi ho payi use report mein saaf likho ("yeh nahi jaancha, kyunki …"). Jhooth-mooth "sab theek" mat likho.

## 7. Bada kaam: "Band hone par bhi files"

User ka maqsad: **desktop power off ho tab bhi phone se uski files khulें** (aur ulta).
Poora plan: `docs\WHEN_OFF_PLAN.md`. Tareeka: device chalu ho tab files ki copy Google Drive mein
(`Cloud-SSD Devices/<id> <naam>/files/...`), band ho to doosra device wahi copy kholta hai.

| Phase | Kya | Haal |
|---|---|---|
| 0 | User ki apni Google key; key phone tak | **User ke haath chahiye** (neeche) |
| 1 | Permission "Files when it is off", dono taraf haan | Ho gaya |
| 2 | PC ki files → cloud (mirror engine, PC page, Windows ke saath chalu) | Ho gaya, asli Drive par test; **paused** chhoda hai |
| 3 | Phone se band PC ki files kholna | **Chal raha hai** (neeche "Abhi ka haal") |
| 4 | Phone ki files → cloud | Baaki |
| 5 | PC se band phone ki files | Baaki |
| 6 | Chune hue folder doosre device par (bina internet) | Baaki |

Phase 2 se bacha hua (chhota): naam badalne ki pehchaan (moveto), metered network par rukna, Transfers screen
par mirror ki line.

**User ke haath ka kaam (Phase 0):** PC app → Cloud Drives → "How do I get a key?" → Google Cloud Console mein
OAuth client (Desktop) banao, "In production" karo → "Switch to my own Google key". Iske bina phone Google Drive
mein sign-in nahi kar sakta, isliye Phase 3 ki **asli jaanch** key ke baad hi hogi.

---

## Abhi ka haal  (har kadam ke baad badlo)

**Aakhri badlaav:** 14 Nov 2026, 15:45 — Claude

**Chal raha kaam:** Phase 3 — phone se band PC ki files kholna.
**Backup folder:** (kaam shuru hote hi yahan likha jayega)
**GitHub par aakhri commit:** `5d3aa29` (isme Phase 3 ka kuch nahi hai).

Kadam:
- [ ] 3.1 Backup `start`
- [ ] 3.2 PC: `/api/whenoff/key` (client id/secret sirf us device ko jiske saath dono haan hain) + `/api/whenoff/state` mein
      cloud ka pata (account, folder ka naam) + tests
- [ ] 3.3 Phone: Google key build ke waqt ki jagah chalte waqt (PC se mili, phone mein sambhali) — `GoogleAuth.java`
- [ ] 3.4 Phone: `DriveBackend.java` mein nayi jad `device:<pcId>:<path>` → us PC ki cloud copy; `Cloud-SSD Devices` ko
      Cloud SSD tab se chhupana
- [ ] 3.5 Phone page (`app.js`): PC band + dono haan + sign-in ho → "Files (cloud copy · <samay> tak)"; sirf padhna
- [ ] 3.6 Tests (C#, JS), APK, PC build; asli device par jo ho sake (key ke bina: sahi sandesh dikhe)
- [ ] 3.7 Asli jaanch key ke saath: PC app band karke phone se folder kholo, file padho, download karo;
      permission band → raasta gayab
- [ ] 3.8 Backup `complete` + README

**Adhoori files (abhi):** koi nahi.
**Agla kadam:** 3.1.
**Ruka hua kis par:** 3.7 ke liye user ki Google key.
