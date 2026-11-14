# CHALU KAAM: jo kaam abhi chal raha hai (Claude aur Codex dono ke liye)

Yeh file isliye hai ki kaam beech mein ruk jaye (token / usage limit khatam, session band, PC band) to jo bhi
agla session aaye, Claude ho ya Codex, wahin se kaam uthaye. Kuch dobara na ho, kuch toote nahi.

**Niyam:** kaam shuru karne se pehle yeh file padho. Har chhota kadam poora hote hi neeche "Abhi ka haal" badlo
(2 minute ka kaam hai; yahi sabse zaroori hai). Token kam lage to naya kaam mat chhedo: pehle yeh file likho.

Project: `C:\Users\Roshan\Downloads\Cloud-Drive\Cloud-Drive\Cloud-SSD\Cloud-SSD\Cloud-SSD`
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
  `powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 start -Name "<kaam ka naam>"`
  → `backup\<tareekh_samay>_<naam>\before\` banta hai. Ise kaam ke dauraan kabhi mat chhuo.
- Kaam ban kar jaanch ho jaye tab:
  `powershell -ExecutionPolicy Bypass -File tools\backup\backup.ps1 complete -Folder "<folder>" -Files a,b,c`
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
| Ek hi kaam do window / do agent ek saath karein (14 Nov ko hua: ek hi session do window mein, dono ne wahi files badlin) | Kaam shuru karne se pehle `git status` aur files ka samay dekho. Koi file abhi-abhi badli ho jo tumne nahi badli, to ruk jao: "Abhi ka haal" mein note likho kaun kya karega, aur ek hi jan source / build / phone / PC chhue. |
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
| Google key ki file GitHub par chali jana | Push se pehle dekho ki `client_secret*.json`, `installer\google-client.json`, `mobile-android\google-oauth.json` stage na hon (`git add -A -f .` inhe bhi utha leta hai). Ho to `git reset -- <file>`. |
| 100 MB se badi file push | `dist\*.zip` 95 MB ke aas-paas hai; 100 MB paar ho to push fail hoga. |

## 6. Jaanch (testing) kaise hoti hai

Sab commands project folder se:

```
# "dotnet" seedha nahi chalta (PATH wale mein SDK nahi hai). PowerShell mein pehle yeh:
$dn = "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe"
& $dn build CloudSSD.slnx                       # 0 warning hona chahiye
& $dn test tests\CloudSSD.Tests                 # C# tests (14 Nov ko 462 pass)
node --test tests/mobile-js/*.test.js           # phone page ke tests (44 pass)
# Jaanch wala APK (-Debug): isi mein phone.ps1 page ke andar jhaank sakta hai. Bina -Debug wala APK release ke liye hai
# (mobile-android\Cloud-SSD-Mobile.apk); us par phone.ps1 "fetch failed / other side closed" deta hai.
powershell -ExecutionPolicy Bypass -File mobile-android\build-apk.ps1 -Debug -OutDir .work\apk
C:\Android\Sdk\platform-tools\adb.exe install -r .work\apk\Cloud-SSD-Mobile.apk
```

Asli phone (wireless adb chalu ho):
```
powershell -ExecutionPolicy Bypass -File tools\live-test\phone.ps1 -Launch -Js .work\<test>.js -Shot <naam>
```
JS file page ke andar chalti hai aur nateeja lautati hai; photo `.work\shots\<naam>.png`. Namoona: `.work\t-icons.js`.

Asli PC app:
```
powershell -ExecutionPolicy Bypass -File installer\build-release.ps1 -SkipTests        # dist\Cloud-SSD-0.9.0-win-x64
powershell -ExecutionPolicy Bypass -File tools\live-test\pc-close.ps1                  # app band (band na ho to user se kaho)
powershell -ExecutionPolicy Bypass -File dist\Cloud-SSD-0.9.0-win-x64\Install-CloudSSD.ps1 -Quiet
Start-Process "$env:LOCALAPPDATA\Programs\Cloud-SSD\Cloud-SSD.exe"
powershell -ExecutionPolicy Bypass -File tools\live-test\pc-shot.ps1 -Shot <naam> [-Press a,b]
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

## Abhi ka haal  (har kadam ke baad badlo: `.work\haal.txt` badal kar `node .work\haal.js .work\haal.txt`)

**Aakhri badlaav:** 14 Nov 2026, 16:24 — Claude (window A)

**Chal raha kaam:** band PC ki files phone se — ab **bina Google key** wala raasta (user ne 16:22 par kaha: key ke bina karo).
Plan: `docs\WHEN_OFF_BINA_KEY_PLAN.md` (pehle ise padho). Raasta A = PC ke folder ki copy phone ke andar ("Offline rakho" ko PC disk ke liye kholna).

Bina-key ke kadam (yahi abhi chal rahe hain):
- [ ] K1 PC: `/api/fs/*` mein PC disk ki jad `disk-c:` (sirf padhna, Browse permission, wahi roktham jo `/api/files` par), feature `fs-disk-roots`, tests
- [ ] K2 Phone page: PC disk ki jagah ko id dena (`ssdPlaces`), "Keep offline" PC ke folder par, PC band hone par copy se khulna
- [ ] K3 Ek tap: Permissions → Files when it is off → "mukhya folder phone par rakho"
- [ ] K4 Apne aap taaza hona jaanchna; 5000 files ki seema dekhna
- [ ] K5 Asli jaanch (PC app band karke phone se kholna)
- [ ] K6 "Cloud copy Google Drive mein kholo" button
- [ ] K7 Wake-on-LAN is PC par chalta hai ya nahi (sirf jaanch)

**Bina-key ka agla kadam:** K1 (pehle `LocalMobileBridgeService.Files.cs` ke `BrowseRoots` / `ResolveCloudPath` aur `/api/files` ki roktham padho).

Neeche Phase 3 (Google key wala) ka haal hai: code ban chuka, key ke bina uski asli jaanch nahi ho sakti; use chheda nahi jayega.
**Backup folder:** `backup\2026-11-14_1544_band-pc-ki-files-phone-se` (sirf `before\` hai = kaam adhoora).
**GitHub par aakhri commit:** `5d3aa29` (isme Phase 3 ka kuch nahi hai; Phase 3 abhi sirf is PC par hai).

Kaise banega (design, tay ho chuka):
- PC `/api/status` ke `whenOff` mein `folder` (PC ka cloud folder ka naam) aur `key` (apni Google key hai?) deta hai;
  `/api/whenoff/key` Google key (client id/secret) deta hai, sirf dono-haan wale device ko. Token kabhi nahi.
- Phone: `GoogleAuth` key ko chalte waqt leta hai (PC se mili, `TokenStore` mein). Build wali key ho to wahi chalti hai.
  Sign-out par Google ka "revoke" **nahi** (warna PC ka rclone bhi logout ho sakta hai).
- Phone: `DriveBackend` mein nayi jad `pc-<pcId>:<path>` = us PC ki copy
  (`Cloud-SSD Devices/<pcId> <naam>/files/<path>`), sirf padhne ke liye. `roots()` yeh jad tab deta hai jab us PC ke
  liye dono haan yaad hon. `Cloud-SSD Devices` folder baaki jagah (All Accounts, Each Account, search) se chhupa.
- Phone page: PC band ho aur phone Google mein sign-in ho to Cloud SSD tab pehle se "drive" mode mein chalta hai
  (`cloudSource() === 'drive'`); nayi jad wahin ek aur jagah ban kar dikhegi. Upar patti: "<PC> band hai · copy <samay> tak".
- Page har status par native ko batata hai kaun se PC ke saath dono haan hain (`native.whenOffSync`).

Kadam:
- [x] 3.1 Backup `start`
- [x] 3.2 PC: `/api/whenoff/key`, `whenOff.folder` / `whenOff.key`, feature `whenoff-key`,
      `RcloneConfigService.OwnDriveClient` + tests (WhenOffTests 4 pass, build 0 warning)
- [x] 3.3 Phone: Google key chalte waqt — `GoogleAuth.java` (`setKey`, `available(Context)`, revoke hataya), bridge `setGoogleKey`
- [x] 3.4 Phone: `DriveBackend.java` jad `pc-<pcId>` (`copyBase`, `copyInfo`, `hidden`), sirf padhna; `WhenOffStore.java` (nayi);
      bridge `whenOffSync`, cloudOp `copy-info`. APK compile hota hai.
- [x] 3.5 Phone page: `data.js` (`whenOffReady`, `whenOffReadyText`, `copyNote`), `app.js` (`syncWhenOff`, Permissions mein doosri
      line + "Sign in", `renderDriveNote`), 16 naye shabd (`.work\p3-words.json`), dono copy ek jaisi, JS tests 45 pass.
- [x] 3.6 Tests pass (C# 464, JS 45). PC: naya build install, chal raha hai. Phone (16:24): test APK install, `.work\t-whenoff.js` ka nateeja sahi:
      "Keep copies in the cloud · On: … both said yes" + "Not ready yet · … shared key …", Sign in button nahi, `errors: []`.
- [ ] 3.7 Asli jaanch key ke saath: PC app band karke phone se folder kholo, file padho, download karo;
      permission band → raasta gayab
- [ ] 3.8 Backup `complete` + README

**Is kaam mein badli files (ab tak):**
- Phone: `mobile-android\src\main\java\com\cloudssd\mobile\GoogleAuth.java`, `DriveBackend.java`, `MainActivity.java`,
  `WhenOffStore.java` (nayi); `assets\app.js`, `data.js`, `i18n-words.js` (+ wahi teen `wwwroot\mobile` mein);
  `tests\mobile-js\data.test.js`. Code poora hai, **asli phone par abhi nahi dekha**.
- Patch scripts jo lag chuke (dobara mat chalao): `.work\p3-pc.js`, `p3-auth.js`, `p3-drive.js`, `p3-fix1.js`, `p3-fix2.js`, `p3-page.js`.
- `src\CloudSSD.Mount\RcloneConfigService.cs`, `src\CloudSSD.App\LocalMobileBridgeService.WhenOff.cs`,
  `src\CloudSSD.App\LocalMobileBridgeService.Security.cs`, `tests\CloudSSD.Tests\WhenOffTests.cs` — poori, test pass.
- `CHALU_KAAM.md` (nayi), `.work\p3-pc.js` (patch jo lag chuka; dobara mat chalao), `.work\haal.js`, `.work\haal.txt`.

**Adhoori files (abhi):** koi nahi.
**Agla kadam:** 3.6 ka phone wala hissa (upar likha hai). Uske baad 3.7 (key ke baad).
**Ruka hua kis par:** (1) phone par Cloud-SSD saamne ho (ya home screen), tab `t-whenoff.js` chalana; (2) 3.7 ke liye user ki apni Google key
(PC app → Cloud Drives → "How do I get a key?" → "Switch to my own Google key"). Key ke baad: phone ke Permissions mein
"Sign in" aayega → user Google mein sign in kare → PC par Devices → When off → Continue (chhota test: `Mirror.OnlyFolders`)
→ PC app band karke phone ke Cloud SSD tab mein "<PC> (cloud copy)" kholna.
PC par ab Phase 3 wala build chal raha hai. Commit / push nahi hua (user ne nahi kaha).

**Doosri window ka note (14 Nov, 15:58 — Claude, window B):**
Yeh session do window mein ek saath chal raha hai (transcript mein dono ke kadam mile hue hain: A ne `p3-auth.js` likha,
B ne `p3-pc.js`). B ne 3.1 aur 3.2 kiya; 3.3 se aage A ne. Ek hi file do log na badlein, isliye:
- **A (jisne `p3-auth.js`, `p3-drive.js`, `p3-page.js` likhe) hi 3.6, 3.7, 3.8 kare.**
- **B ab source, build, APK, phone aur PC install kuch nahi chhuega.** B ka `WhenOffStore.java` A ke version se badal gaya
  (theek hai, A wala hi rahe); B ka apna Java patch kabhi laga hi nahi aur hata diya gaya.
- B ne A ka `DriveBackend.java` / `GoogleAuth.java` padha. Design sahi hai. Teen chhoti baatein (A chahe to theek kare):
  1. Copy ke andar ke folder par `doc()` abhi `canCreate = true` de sakta hai (line ~282); `create()` mana kar deta hai, par
     page "yahan naya banao" dikha sakta hai. Copy ke liye `canCreate = false` kar do.
  2. "All Accounts" ki search: Google se `max` nateeje aate hain, phir copy wale chhaant diye jaate hain. PC ki copy mein
     lakhon files hon to aam search khaali aa sakti hai. Jab `WhenOffStore.pcs` khaali na ho tab Google se zyada maango
     (jaise `max * 3`).
  3. `GoogleAuth.accessToken`: key badalne par Google `unauthorized_client` / `invalid_client` bhi de sakta hai; abhi sirf
     `invalid_grant` par "dobara sign in" lagta hai.
- User ko bata diya jayega ki ek kaam ke liye ek hi window chalayein.
- **A, 16:00:** teeno baatein theek kar din (`.work\p3-fix2.js`): copy mein `canCreate = false`, search `max * 3`, key badle to "dobara sign in".
  C# tests 464 pass, JS 45 pass.

---

## Kaam: CMD / CLI Support (Claude & Codex style) - COMPLETE

- **Tareekh & Samay:** 14 Nov 2026, 16:18 - 16:26
- **User Commands:**
  1. /plan mujhe isko cmd me bhi calana hai wo kayse banega or kayse kam karega
  2. jaysa claude codex hai wayse hi mujhe isko bhi wayse hi banana hai
  3. jo bhi kam karo uska date time jo cammand mene diya jo plan tum banan rahe ho or main chij jo bhi change karo uska backup
- **Backup Folder:** ackup\2026-11-14_1618_cmd-claude-codex-cli (before + complete, README.md)
- **Badli Files:**
  - src\CloudSSD.Cli\Program.cs
  - installer\cloudssd.cmd
  - installer\Install-CloudSSD.ps1
  - installer\build-release.ps1
  - C:\Users\Roshan\.local\bin\cloudssd.cmd
  - C:\Users\Roshan\.local\bin\cpx.cmd
- **Haal:** Ho gaya. CMD mein cloudssd aur cpx dono interactive shell (Claude/Codex style) aur direct one-shot mode dono support karte hain. Unit tests 464 pass.
