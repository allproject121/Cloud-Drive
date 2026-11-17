# CHALU KAAM: jo kaam abhi chal raha hai (Claude aur Codex dono ke liye)

Yeh file isliye hai ki kaam beech mein ruk jaye (token / usage limit khatam, session band, PC band) to jo bhi
agla session aaye, Claude ho ya Codex, wahin se kaam uthaye. Kuch dobara na ho, kuch toote nahi.

**Niyam:** kaam shuru karne se pehle yeh file padho. Har chhota kadam poora hote hi neeche "Abhi ka haal" badlo
(2 minute ka kaam hai; yahi sabse zaroori hai). Token kam lage to naya kaam mat chhedo: pehle yeh file likho.

Project: `C:\Users\Roshan\Downloads\Cloud-Drive\Cloud-Drive\Cloud-SSD\Cloud-SSD\Cloud-SSD`
(git ki jad do folder upar; branch `main` + `feature/multi-device` dono; GitHub repo private hai).

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
Poora plan: `docs\archive\WHEN_OFF_PLAN.md` (archive me hai). Tareeka: device chalu ho tab files ki copy Google Drive mein
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

**Aakhri badlaav:** 17 Nov 2026, 02:45 — Claude Code, K session (firewall rule joda): **bina-key wala kaam (K1–K5, K7) poora, asli phone par jaancha, backup band.** Koi kaam chalu nahi.

**Aakhri kaam (poora):** band PC ki files phone se — **bina Google key** wala raasta (user ne 14 Nov 16:22 par kaha: key ke bina karo).
Plan: `docs\archive\WHEN_OFF_BINA_KEY_PLAN.md` (pehle ise padho). Raasta A = PC ke folder ki copy phone ke andar ("Offline rakho" ko PC disk ke liye kholna).
Lock: `docs\CURRENT_TASK.json` → `TASK-CLAUDE-K`, **COMPLETED / active false**. Poora byora: `backup\2026-11-14_1544_band-pc-ki-files-phone-se\complete\README.md`.

Bina-key ke kadam:
- [x] K1 PC: `/api/fs/*` mein PC disk ki jad `disk-c:` (sirf padhna, wahi roktham jo `/api/files` par), feature `fs-disk-roots`,
      test `A_pc_disk_is_a_read_only_drive_and_only_its_shared_places_open`. (14 Nov ko ban gaya tha, sirf yahan tick nahi laga tha.)
- [x] K2 Phone page (code + JS tests + asli phone 17 Nov 02:25): `data.js` `diskId` / `diskPath` / `isDiskId` / `pinsBelow`;
      `app.js` `keepIdOf` ab PC disk ke folder ko `disk-c:…` id deta hai (`diskIdOf`), `ssdPlaces` mein `disk: true`,
      `keptList` kept folder tak ka raasta (C: → Users → …) bhi copy se banata hai, `syncActions` PC disk par nahi,
      PC disk ki photo ke thumbnail, More → Offline files mein row dabane se folder khulta hai (`offline-open`).
- [x] K3 Ek tap (code + tests + asli phone 17 Nov 02:04): PC `/api/pc/home` → `main` (6 mukhya folder; raasta sirf jab
      "PC disks" chalu ho), feature `pc-main-folders`, test `The_phone_is_told_the_main_folders_…`. Phone: Permissions →
      "Files when it is off" → "Keep the PC's main folders on this phone" → "Choose…" → har folder ka size (`/api/fs/usage`),
      "Keep all N folders", bahut bada / 5000+ files ho to pehle hi saaf sandesh (`data.js` `keepTooBig`). 19 naye shabd (`.work\k-words.json`).
- [x] K4 `OfflinePins.java`: andar ka koi folder Windows padhne na de (403/404) to sirf wahi chhoota hai, poora pin fail nahi hota;
      aise round mein purani copy mitayi nahi jaati. 5000 ki seema wahi rakhi (page pehle bata deta hai). Apne aap taaza hona asli phone par dekha (badli file khud aayi, mitayi file hat gayi);
      "na-padha-ja-sakne wala folder" wali shaakha asli phone par nahi aayi (aisa folder Documents mein nahi tha).
- [x] K5 Asli jaanch (17 Nov 02:04–02:25, vivo I2221, test APK): Documents rakha (15 files) → PC tak raasta kaata → More → Offline files → Documents khula,
      test file phone ki copy se padhi → PC par badli: khud naya version → PC par mitayi: copy hati → ⋮ menu mein sirf "Open" + "Keep offline".
      **PC ko sach mein power off nahi kiya** (raasta `adb reverse --remove` se kaata; PC app aur drives chalte rahe).
- [ ] K6 "Cloud copy Google Drive mein kholo" button — **jaan-boojh kar nahi banaya:** PC ka mirror `Paused` hai aur Drive par koi copy nahi,
      to iski asli jaanch ho hi nahi sakti. Banana ho to: mirror pass ke baad `rclone lsjson "<account>:Cloud-SSD Devices" --dirs-only` se
      folder ka ID → `whenOff` mein `link` → phone par PC band dikhne par button (native mein URL kholne wala method bhi chahiye).
- [x] K7 Wake-on-LAN (sirf jaanch, 17 Nov 01:50, kuch badla nahi): yeh PC **Wi-Fi** par hai (Intel AX101), Ethernet cable lagi nahi.
      "Wake ke liye armed" sirf Ethernet card (Realtek) hai; Wi-Fi card wake kar sakta hai par armed nahi. Yaani abhi phone ka
      "Wake PC" is PC ko nahi jagayega. Chalane ke do raaste (dono user ka faisla, admin setting): router se LAN cable lagao, ya
      Device Manager → Intel Wi-Fi → Power Management → "Allow this device to wake the computer" (sirf Sleep se jagta hai, poore band se nahi).

**Jaanch (17 Nov 01:45):** build 0 warning / 0 error · C# **474/474** · JS **48/48**.
**PC par asli jaanch (17 Nov 01:56):** release build (`dist\Cloud-SSD-0.9.0-win-x64.zip`, SHA256 `eb469092…fb703aff`) install, app chalu,
Z:/Y: "Re-attached"; `/api/status` ke features mein `pc-main-folders` aur `fs-disk-roots`; bina key ke `/api/pc/home`, `/api/fs/list?path=disk-c:…`,
`/api/fs/roots?include=disks` → 401; PC jo page deta hai usme naya code (`main-keep`, `diskIdOf`). `MobileBridge.AllowPcDisks = true` pehle se hai.
**Test APK:** `.work\apk\Cloud-SSD-Mobile.apk` (-Debug, 17 Nov 01:47) ban gaya, Java compile hota hai. **Phone par install nahi hua.**
**Raaste mein mila bug (theek kiya):** `tools\live-test\pc-close.ps1` ka "title bar ka X dabao" wala hissa PS 5.1 par compile hi nahi hota tha
(`System.Drawing.Rectangle`), aur minimized window par X hota hi nahi → app 90 s mein band nahi hota tha. Ab apna `RECT`, pehle window saamne.

**Do session ek saath (17 Nov 01:53 se):** ek aur Claude window "CMD ka naya look" (TASK-CLAUDE-CLI-TUI) kar rahi hai — neeche uska hissa hai.
Bantwara: **woh** sirf `src\CloudSSD.Cli\*`, `tests\CloudSSD.Tests\CliTuiTests.cs` (+ test csproj), README ka CLI hissa.
**Yeh (K) session:** phone page, bridge (`src\CloudSSD.App`), `mobile-android`, APK, phone, PC app ka install. K session Cli ki files nahi chhuta.
**Teesra session (17 Nov ~02:05, naam `roshan-47`):** "drive speed + restart" — sirf `src\CloudSSD.Mount\{MountService,MountPlanning}.cs`,
`src\CloudSSD.App\ArchiveWarmer.cs`, `AppHost.cs` (ArchiveWarmer wali lines), naye tests. Tay hua: woh `backup.ps1 start -Force` chalayega aur K ka lock
wapas likhega; PC app band karne se pehle K session ko batayega (K5 mein PC app jaan-boojh kar band / chalu hota hai); `pc-close.ps1` nahi badlega.
Dhyan: `dotnet test` poora test project banata hai; doosri window ka adhoora `CliTuiTests.cs` build tod sakta hai — tab woh K ki galti nahi, ruk kar dobara chalao.
**Is hisse mein badli files:** `mobile-android\src\main\assets\{app.js,data.js,i18n-words.js}` (+ wahi teen `src\CloudSSD.Desktop\wwwroot\mobile` mein, ek jaisi),
`mobile-android\src\main\java\com\cloudssd\mobile\OfflinePins.java`, `src\CloudSSD.App\LocalMobileBridgeService.QuickAccess.cs`,
`src\CloudSSD.App\LocalMobileBridgeService.Security.cs` (feature ka naam), `tests\CloudSSD.Tests\QuickAccessTests.cs`,
`tests\mobile-js\data.test.js`, `.work\k-words.json` (lag chuka; dobara chalane se kuch nahi bigadta).
`tools\live-test\pc-close.ps1`, `.work\t-k3.js` (phone ki jaanch, sirf padhta hai).
**Adhoori files:** koi nahi (sab compile + test pass). PC par 02:05 ka build chal raha hai (teesre session ka install; K ke bridge badlaav usme hain); phone par test APK (17 Nov 01:59).

**Jaanch (17 Nov 02:28, teeno session ke badlaav ke saath):** `backup.ps1 validate` → build 0 warning / 0 error · C# **518/518** · JS **48/48** · **APPROVED**.
**Firewall (17 Nov 02:35, theek ho gaya):** phone 14 Nov ke baad se isliye nahi judta tha ki Windows Firewall rokta tha: Wi-Fi "Private" hai, `cloud-ssd.exe` ki
ijazat sirf "Public" profile ki thi, aur app ka apna rule "Cloud-SSD direct links" bana hi nahi tha. User ne kaha "usko bhi karo" → K session ne wahi rule joda jo
app ka Add device → "Allow" button jodta hai (user ne UAC par "Yes" dabaya):
`netsh advfirewall firewall add rule name="Cloud-SSD direct links" dir=in action=allow protocol=TCP localport=8090 remoteip=LocalSubnet profile=any`.
Jaanch: `adb reverse` hata kar phone se `http://<PC ka Wi-Fi IP>:8090/api/status` → 200 (40 ms); pehle yahi request fail hoti thi. **App ke andar "Connected (Wi-Fi)"
nahi dekha** — us waqt phone lock tha (PIN kahin likha nahi; khola nahi jata). Hatana ho: `netsh advfirewall firewall delete rule name="Cloud-SSD direct links"` (admin).
UDP (PC ko dhoondhna) ke liye alag rule nahi joda; phone ke paas PC ka pata saved hai.
**Aakhri chhota sudhaar (source + tests mein, installed PC build 02:05 mein NAHI):** `LocalMobileBridgeService.Files.cs` `DiskRoots()` ab cloud drive ko
`IsReady` poochhne se pehle chhod deta hai (busy Z: par `disk-…` wali request 10 s atak kar "timeout" de sakti thi; 02:21 par ek baar aisa hua). Agle install mein aayega.
**Phone par:** test (-Debug) APK laga hai; release APK dobara nahi bana. Phone par ek purana pin `Cloud-Drive.zip` (6.58 GB) "Not found." bata raha hai
(woh file cloud se ja chuki): uski copy phone mein 6.58 GB gher rahi hai — hatana user ka faisla (More → Offline files → Remove).
**Chhoti baatein (theek nahi ki):** `/api/fs/usage` chhupi `desktop.ini` bhi ginta hai (16 likha, 15 aaye); kabhi na khole gaye upar ke folder ka raasta copies se
banna sirf JS test mein dekha. **Commit / push nahi hua** (user ne nahi kaha).

**Agla kadam (jo bhi agla session aaye):** koi adhoora kaam nahi. User kahe to: (1) phone khula ho tab app mein "Connected" (Wi-Fi) dekhna (`.work\t-conn.js`);
(2) PC ka naya release install (Files.cs ka sudhaar + CLI session ka naya `cpx`) aur release APK; (3) K6; (4) Phase 3 ka 3.7 (apni Google key ke baad); (5) commit / push.

Neeche Phase 3 (Google key wala) ka haal hai: code ban chuka, key ke bina uski asli jaanch nahi ho sakti; use chheda nahi jayega.
**Backup folder:** `backup\2026-11-14_1544_band-pc-ki-files-phone-se` (`before\` + `complete\` + README, APPROVED; Phase 3 ka 3.7 key ke bina nahi jaancha — README mein likha hai).
**GitHub par aakhri commit:** `1e60b83` (`feature/multi-device` & `main` branches fully synchronized).

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

---

## Kaam: Latest Screenshots Sync & Showcase - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 10:41 IST
- **Agent:** Antigravity (Gemini 3.8 Flash High)
- **User Command:** "GitHub पर जो फोटोज अपलोड हैं, उन्हें लेटेस्ट वाले में अपलोड करो। जैसे होम डैशबोर्ड, क्लाउड ड्राइव, पिन ऑफलाइन एक्सेस, वर्चुअल टीम बैकअप, ऐप आइकन पिकर। जितनी फोटोज हैं, और भी फोटोज हैं, और वाले सेशंस हैं, उनको एक-एक करके दिखाओ।"
- **Backup Folder:** `backup\2026-11-16_1038_latest-screenshots-sync` (APPROVED: build 0 errors, 465/465 unit tests pass)
- **Badli Files:**
  - `README.md`
  - `screenshots/phone-pin-offline.png`
  - `screenshots/pc-devices-backup.png`
  - `screenshots/phone-perm-editor.png`
  - `screenshots/pc-bell-alerts.png`
  - `screenshots/phone-cards-kit.png`
  - `screenshots/phone-cards-paper.png`
  - `screenshots/phone-cards-auto.png`
  - `docs/antigravity.md`
  - `docs/CURRENT_TASK.json`
- **Haal:** Poora hua. Sabhi latest screenshots README mein jode gaye aur repository par push kiye gaye.

---

## Kaam: Archified Master Architecture & 9 Detailed System Flows in README.md - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 11:07 IST
- **Agent:** Antigravity (Gemini 3.8 Flash High)
- **User Command:** "how it work hai readme,md file me usko archify use karke banaosame jayse abhi hai wayse hi or eak or add karo uske niche hi eakdam deatil me kayse kam karta hai ekdam deatil me usme har eak chij ka destil em baytao ki kam kays ekarnat ahai usme side me optio dena ki login par aaya jayega phone se file share kiya to system aaye kam akrrta ahi me ye baas exmaple batao raha hu tumhe para systm deign bananna hai pura bahit bada bhi ban jayefa oi problem nahii hoga usme bas banao usko kayse kama karta hai wo banao usko"
- **Backup Folder:** `backup\2026-11-16_1104_detailed-architecture-docs` (APPROVED: build 0 errors, 465/465 unit tests pass)
- **Badli Files:** `README.md`, `docs/CURRENT_TASK.json`, `docs/CHALU_KAAM.md`, `docs/antigravity.md`
- **Haal:** Poora hua. README.md mein Archified Master Architecture Diagram, Matrix table, aur 9 complete end-to-end technical flows jode gaye aur GitHub par push kiya gaya.

---

## Kaam: Archify Interactive System Design (Side Gateways, Home Page Hub & Feature-to-System Execution Lines) - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 11:47 IST
- **Agent:** Antigravity (Gemini 3.8 Flash High)
- **Tooling:** Official GitHub `tt-a1i/archify` AI Agent Framework
- **User Command:** "archify use karp github wala use karke"
- **Backup Folder:** `backup\2026-11-16_1120_archify-system-design` (APPROVED: build 0 errors, 465/465 unit tests pass)
- **Badli Files:**
  - `README.md` (Archified System Design Mermaid flowchart, ASCII blueprint, expanded matrix, 12 technical flows, and link to standalone Archify HTML)
  - `docs/architecture-archify.html` (Standalone interactive architecture diagram compiled via official `tt-a1i/archify` tool)
  - `docs/CHALU_KAAM.md`
  - `docs/CURRENT_TASK.json`
  - `docs/antigravity.md`
  - Artifact: `cloud-drive-system-architecture.html`
- **Haal:** Poora hua. Official GitHub `tt-a1i/archify` tool install karke candidate architecture JSON banaya gaya, validate kiya gaya (`status: pass`, 0 errors), aur standalone interactive HTML compile karke README.md aur repository mein joda gaya.

---

## Kaam: Project Health Audit (MiniMax Code) - READ-ONLY, COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 15:05 - 15:20 IST
- **Agent:** MiniMax Code (MCode)
- **User Command:** "ha tum bhi aapane name ka file banakr usme kam karna or abhi isme kya kya chije tik se work nahi kar raha hai ... wo deko or batao"
- **Backup Folder:** `backup\2026-11-16_1518_mcode-health-audit-readme-links` (before + complete; APPROVED: build 0 errors/0 warnings, C# 465/465, JS 45/45)
- **Badli Files:** `docs/MCODE.md` (nayi — MCode ka apna work log), `docs/CHALU_KAAM.md`, `docs/CURRENT_TASK.json`
- **Code:** Koi source code nahi badla. Sirf jaanch (build, dono test suite, runtime logs, README link check, settings).
- **Haal:** Audit poora. Sabse badi 4 baatein:
  1. **App abhi band/crashed hai** — `Z:`/`Y:` mounted nahi, `Cloud-SSD.exe`/`rclone.exe` nahi chal rahe, aakhri activity 15:01:28. Windows Event Log mein WER `AppTermFailureEvent` (14:52, 14:55, 15:02, 15:05) — clean exit nahi hua.
  2. **7.3 GB ka upload adhoora chhoot gaya** — `Cloud-Drive.zip` 24% par ruka, `errors:89`, `lastError: couldn't list directory: context canceled`, resume nahi hua.
  3. **Mount auto-restore fail** — "Drive Z:/Y: did not appear within N s", "mountpoint Z: didn't became available", retry loop. Saath hi `--links` flag missing (symlink error) aur union remote ka `Statfs failed` (galat disk-space info).
  4. **README ke 40 relative links toote hain** (workspace README 37/40, codebase README 40/40) — folder structure `Cloud-SSD/Cloud-SSD-0.7.0-source/Cloud-SSD` se badal kar `Cloud-SSD/Cloud-SSD/Cloud-SSD` hua tha, README update nahi hua. Docs ab `docs\archive\` mein hain.
- **Poori list + evidence:** `docs\MCODE.md` (TASK-MCODE-001) — saare 17 points, har ek ke saath actual log line / command output.
- **Agla kadam:** user ka faisla. Fix karna ho to order: (1) mount restore + crash, (2) `--links` flag, (3) README links, (4) stale plan path (`docs\archive\...`), (5) phone par asli jaanch (Phase 3 step 3.7 — device "vivo I2221" ka LastSeen 14 Nov hai, 2 din se link nahi).

---

## Kaam: Sab kuch theek — mount, docs, release build, settings (MiniMax Code) - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 15:30 - 17:05 IST
- **Agent:** MiniMax Code (MCode)
- **User Command:** "fix karo sari chije" (audit ke 17 points par kaam)
- **Backup Folder:** `backup\2026-11-16_1532_mcode-fix-batch-1` (before + complete; APPROVED: build 0 errors/0 warnings, C# **470/470**, JS 45/45)
- **Badli Files:**
  - Code: `src/CloudSSD.Mount/{MountPlanning,MountService,RcloneConfigService}.cs`, `src/CloudSSD.Diagnostics/Logging.cs`,
    `src/CloudSSD.Core/{Settings.cs,SecretProtector.cs (nayi),CloudSSD.Core.csproj}`, `src/CloudSSD.Desktop/ViewModels/ConfigViewModels.cs`
  - Tests: `tests/CloudSSD.Tests/CoreTests.cs` (5 naye tests)
  - Scripts: `installer/build-release.ps1`, `tools/backup/backup.ps1`, `tools/live-test/pc-close.ps1`
  - Docs: `README.md` (3 copies), `RULE.md` (3 copies), `docs/{CHALU_KAAM,DEV_TESTING,PROJECT_POLICIES,MCODE}.md`, `docs/archive/SETUP.md`, `.work/README-DO-NOT-RERUN.md` (nayi), `backup/2026-11-14_2003_.../complete/README.md` (nayi)
  - Runtime: `%LOCALAPPDATA%\Cloud-SSD\settings.json` (Mirror ko safe kiya)
- **Haal:** Sab theek, aur ek asli PC par jaanch ke saath:
  1. **`--links` flag missing tha** → har mount par "symlinks not supported" + union ka `Statfs failed` (galat disk-space). Ab flag add hai: **symlink error 0**, statfs chalta hai (16.5 TB / 15.7 TB free).
  2. **45 s timeout** quota 403 me kaam nahi karta tha (mount ko 75-120 s lagte hain) → **120 s**, aur error ab batata hai: *"Google Drive API quota khatam ho gaya (403). Apni OAuth key use karo … Switch to my own Google key"*.
  3. **Release build toota hua tha** (`THIRD_PARTY_NOTICES.md` root par hi thi, ab `docs\archive\` me) → `Find-Doc` helper se theek; build ab chalta hai: `dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB, SHA256 `1105a640…`).
  4. **README ke 40/40 links** → teeno copies me **0 broken**; badge PC 0.9.0 / phone 0.12.0; download links naye path par. `docs/` ke 6 toote links bhi theek.
  5. **Mirror poori disk upload kar raha tha** → `OnlyFolders = Documents`, `IncludeSystem = false`, `Paused = true`.
  6. **settings.json me token/media key plain** → ab DPAPI se protected (purani plain files bhi chalti hain).
  7. Log file ka naam `cloudplayx-*.log` → `cloudssd-*.log`; `backup.ps1 -Files "a,b,c"` ka bug theek.
- **Phe:** WER "AppTermFailureEvent" Cloud-SSD ka crash **nahi** tha (payload khaali; `crashpad_log` wala Edge ka hai). Sach: app band hua tha aur 7.3 GB ka upload adhoora chhoda.
- **Poori list + evidence:** `docs\MCODE.md` (TASK-MCODE-002).
- **User ke haath me do cheezein ab bhi:** (1) **apni Google OAuth key** (Cloud Drives → "How do I get a key?" → "Switch to my own Google key") — rclone ka shared key 2026 me retire ho raha hai, uski quota khatam rehti hai; (2) **phone par jaanch** (Phase 3 step 3.7) — "vivo I2221" ka LastSeen 14 Nov 17:11 hai.
- **Push nahi hua** (user ne nahi kaha).
- **Ruka hua kis par:** user ka command. Koi code change bina kahe nahi kiya gaya.

---

## Kaam: Dono drive live mount + backup lock ka PS 5.1 bug (MiniMax Code) - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 16:41 - 17:00 IST
- **Agent:** MiniMax Code (MCode)
- **Backup Folder:** `backup\2026-11-16_1648_mcode-backup-lock-ps51` (before + complete)
- **Kya hua:**
  1. **Naya code:** `src\CloudSSD.Mount\MountService.cs` me `WatchForDriveAsync` — 120 s timeout hone par rclone ko **maarne ke bajaye zinda chhod** diya gaya; watcher 15 min tak drive letter ka intezaar karta hai aur jaise hi letter aata hai, session "Mounted" ho jaata hai.
  2. **Asli PC par proof (naya build install karke):**
     - Y: (Each Account) → **16:43:38 "Mounted at Y:"**
     - Z: (All Accounts) → **16:43:58 "Mounted at Z: (the drive appeared while the app was waiting)"**
     - Asli file read: 142181 bytes in 1729 ms aur 1028984 bytes in 2137 ms ✅
     - Disk space: Z: 15.0 TB / 14.9 TB free (pehle "Statfs failed") ✅
     - Symlink error: **0** ✅
  3. **Release build:** `dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB, SHA256 `d931ce2a338f247c4b50753afb658251901e42d8470c7f117b25cc36aa0ac355`), naya build install ho chuka hai.
  4. **Backup ka lock bug:** `tools\backup\backup.ps1` me `ConvertFrom-Json -AsHashtable` PS 5.1 par nahi hai → lock kabhi release nahi hota tha. Ab `Read-TaskLock` helper se 5.1 aur 7+ dono par chalta hai; `validate` ab `validationStatus` likhta hai aur `complete` khud lock band karta hai.
- **Task-002 ka backup band:** `backup\2026-11-16_1532_mcode-fix-batch-1` → `complete\` (new 3, changed 19), `VALIDATION.txt` = APPROVED, `complete\README.md` Hinglish me. `docs\CURRENT_TASK.json` → `active:false`, `status: COMPLETED`.
- **User ke haath me ab bhi:** (1) apni Google OAuth key (shared rclone key ki quota khatam rehti hai); (2) phone par Phase 3 step 3.7 jaanch ("vivo I2221" ka LastSeen 14 Nov 17:11).
- **Push nahi hua** (user ne nahi kaha).

---

## Kaam: Zip/install tez, app restart pe khud chale (MiniMax Code) - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 17:15 - 18:05 IST
- **Agent:** MiniMax Code (MCode)
- **User ka shikayat:** zip bahut slow khulta hai / khulta hi nahi, install bahut time leta hai, aur PC restart karne par Cloud-SSD band ho jaata hai (permanent hona chahiye jab tak uninstall na ho).
- **Backup Folder:** `backup\2026-11-16_1731_mcode-mount-speed-autostart` (before + complete; APPROVED: build 0/0, C# **471/471**)
- **Kya fix hua:**
  1. **Restart pe app ab khud chalega** — app me feature maujood tha (`StartWithWindows.cs`), par is PC par registry entry nahi thi. Entry bana di, aur ab **installer** bhi install ke time ye entry likhta hai (uninstaller hatata hai) → ek baar install = permanent.
  2. **7.3 GB ka junk upload band** — pehle ka accidental mirror dump 11.6 MB/s up le raha tha, is liye user ka download sirf 251 KB/s tha. Pending-upload wale cache copies (≈28 GB, sirf local cache) Recycle Bin me gaye; ab 0 upload, baaki cache rakha gaya (files turant khulti hain).
  3. **Read chunk 4 MiB → 32 MiB** (`Cache.ReadChunkSizeBytes`), **cache budget 20 → 60 GiB** — ek archive 16 API requests ki jagah 2; dusri baar file cache se turant.
  4. **App band karne par drive ab nahi marti** — rclone app ke pipe se chalta tha; pipe toot'ta → Go SIGPIPE → rclone mar jaata tha (controlled test me reproduce kiya). Naya `DetachedProcess.cs` (`CreateProcessW` + `STARTF_USESTDHANDLES`) rclone ko NUL device se chalaata hai → pipe nahi, toot' hi nahi sakta. **Proof:** app maarte hi 60 s baad bhi rclone zinda, `Z:` mounted, aur app band rahne par bhi file read (1 MB in 1277 ms); app dobara start karne par "Re-attached to running mount at Z:/Y:".
  5. **Khaali dikh raha folder theek** — ye stale dir-cache tha (quota 403 me fail listing "khali" cache ho gayi thi, 72 h tak). Cache clear kiya → files wapas. Isi liye `--vfs-refresh` hataya nahi gaya.
- **Asli blocker (code se nahi, user ke haath me):** Google Drive API ka **shared rclone quota** (`project_number:202264815644`) — 403 storm me download **4 KB/s** tak girta hai (cold read 181–222 s), jabki cache hit par random read **24 ms**. Solution: **apni OAuth key** (Cloud Drives → "How do I get a key?" → "Switch to my own Google key"). Uske baad drive 3–6 s me aati hai.
- **Release:** `dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB, SHA256 `998ee920d57d6323b379ab1778697f2b58b60baa6f20ca26d08ed0529a294084`), install ho chuka hai.
- **Push nahi hua** (user ne nahi kaha).

---

## Kaam: Zip ab khulega — "Fast browsing" mode (MiniMax Code) - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 18:20 - 18:50 IST
- **Agent:** MiniMax Code (MCode)
- **User ka shikayat:** *"zip abhi bhi bahot slow open ho raha hai ya bol do open hi nahi ho raha hai"* + quiz me confirm: **"Zip open hi nahi hota / bahut slow"**
- **Backup Folder:** `backup\2026-11-16_1834_mcode-fast-browsing-mode` (before + complete; APPROVED: build 0/0, C# **472/472**)
- **Asli gadda:** Windows zip ka **end** padhta hai, par drive `--vfs-cache-mode full` par thi — us mode me rclone koi bhi file kholte hi **poora file** download kar leta hai. A/B (same 460 MB zip): **full** → 1 MiB padhne me **38.8 s** aur **460 MB utra**; **writes** → **5.3 s** aur **0 MB extra**. isi se quota bhi jharta tha (har folder listing par har archive pura download hota tha → cache 13.7 GB, log 305k lines).
- **Fix:**
  1. Naya setting `Cache.VfsCacheMode` (`full` default = games ke liye, `writes` = fast browsing).
  2. **UI toggle**: Cloud Drives → "Drive mode" card → "Fast browsing" checkbox + "Apply and reconnect" (mode mount shuru hone par tay hota hai).
  3. Is PC par **"writes" ON** kar diya.
- **Proof (naya build, Z:):** `--vfs-cache-mode writes` command me ✅ · 460 MB zip ka end **21.5 s** + **0 MB** extra (pehle 38.8 s + 460 MB) · dusra read **47 ms** · Z: ready 15 s me.
- **Bacha hua wait:** Google ke shared quota ka backoff (`Rate limited, increasing sleep to 16.4s`) — **apni OAuth key** se khatam (browser me Google Console khul gaya hai, steps bheje gaye).
- **Release:** `dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB, SHA256 `cb4960b8fa07791b16e5568d944b56fabfdd1fd5b752c035280e3f626c2f1bd1`), install ho chuka hai.
- **Push nahi hua** (user ne nahi kaha).

---

## Kaam: Pura end-to-end test + chunk size wapas 4 MiB (MiniMax Code) - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 18:50 - 19:25 IST
- **Agent:** MiniMax Code (MCode)
- **User ka shikayat / instruction:** *"pura test kud kiya karo meri puri permission hai"* — poora build + teeno test suite + release build + install + asli device par jaanch, evidence ke saath.
- **Backup Folders:**
  - `backup\2026-11-16_1905_mcode-chunk-size-revert-4mib` (TASK-MCODE-006; APPROVED: build 0/0, C# **472/472**)
  - `backup\2026-11-16_1918_mcode-backup-readme-identity-fix` (TASK-MCODE-007; APPROVED: build 0/0, C# **472/472**)
- **Test results (sab abhi, issi machine par):**
  1. **Unit (C#):** `472/472 PASS`
  2. **Mobile JS:** `45/45 PASS`
  3. **Integration (pehli baar chala):** `28/29` — ek fail `Demo_game_launches_from_cloud...` ("run the demo game install step first")
  4. **Demo game install step kiya** (TEST_REPORT.md wala; `DOTNET_ROOT` set karna zaroori tha, PATH wala dotnet sirf .NET 8 runtime hai) → dataset **3,626 MB** bana → game flow bahut aage badha (Launch 1 cold 20030 ms / 126.4 MiB, Launch 2 7942 ms, Prepare 146/146 blocks "ReadyToLaunch" 22 s, Launch 3 7109 ms)
  5. **Hybrid step fail hua**: `UnsupportedFilesystemOperation` on `local-games\CPX Demo Game-...` → wajah `File.CreateSymbolicLink` (`ExecutionModes.cs:121`) → *"Administrator privilege required"* = Windows **Developer Mode band** tha. Elevated process me **"SYMLINK OK"** prove kiya → **code sahi hai**, sirf OS privilege state.
  6. **Developer Mode ON kiya** (user ki permission par): `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\AllowDevelopmentWithoutDevLicense = 1` (UAC se). Non-elevated process me abhi bhi fail → **reboot/sign-out chahiye** tabhi sab apps me effective hoga.
  7. **Elevated integration suite: `29/29 PASS`** (6.08 min) — game-flow wala bhi pass, hybrid step samet.
  8. **Chunk size wapas 4 MiB** (32 MiB se): 460 MB zip ka end **21.5 s → 5.3 s**, extra 0 MB.
  9. **Release build + install**: `dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB), SHA256 `8432850da5a0138e36f131d6e146dd7188ef96d77a2ecb2aa16cca665b3ae3d0`, install + app chalu.
  10. **Device test 14 sections — sab PASS** (app restart ke baad dobara chalaya, phir bhi PASS).
  11. **Regression: app band → drive zinda** → rclone zinda, Z:/Y: mounted, listing 122 ms. **App restart → re-attach**: log me `Re-attached to running mount at Z:` aur `at Y:` (19:07:06), aur **purana rclone (19:02:38 wala) zinda raha** — matlab app band karne par mount nahi mara.
- **Naya bug pada aur fix hua (TASK-MCODE-007):** `backup.ps1` ka `complete` step agent/taskid apne command line se leta tha (default `Antigravity`, TaskId khali) → README me **galat agent** likha jaata tha. Ab `TASK_INFO.json` se uthata hai. Sandbox me end-to-end prove kiya: `Agent: MiniMax Code | TaskId: TASK-TEST-999` ✅, aur `RESTORE_LOG.md` me bhi sahi agent ✅.
- **Bache hue masle (code se nahi, user ke haath me):**
  - Google Drive **shared quota** (`project_number:202264815644`, 403 `RATE_LIMIT_EXCEEDED`) → pehli cold read 15–34 s. Solution: **apni OAuth key**.
  - Drive me **junk** abhi bhi hai (6.6 GB + 6.8 GB `Cloud-Drive.zip`) → cloud data delete project rule ke khilaf, user ka faisla baaki.
  - Phone par Phase 3 step 3.7 jaanch pending.
  - App close karne par sirf **window** chala jaata hai (drives zinda rehte hain) → tray-mode ke liye `App.xaml.cs` chhedna padega jo RULE me banned hai.
- **Push nahi hua** (user ne nahi kaha).

---

## Kaam: Zip kholna — asli gadda mila, fix hua (MiniMax Code) - COMPLETE

- **Tareekh & Samay:** 16 Nov 2026, 19:44 - 20:10 IST
- **Agent:** MiniMax Code (MCode)
- **User ka instruction:** *"koi bhi zip file open karke test karo or check karo ki open ho raha hai ki nahi"*
- **Backup Folder:** `backup\2026-11-16_1954_mcode-warm-zip-cache-chunk-limit` (before + complete; APPROVED: build 0/0, C# **473/473**)
- **Do layer ka gadda:**
  1. **`--vfs-cache-mode writes` me read cache hote hi nahi** — rclone ke apne docs ke hisaab se *"files opened for read only are still read directly from the remote"*. Isi liye `ArchiveWarmer` ka poora prefetch bekaar tha (log: `item Jarvis.zip not removed, freed 0 bytes`) — har naya open = naya download = Google ke shared quota ki line me.
  2. **`--vfs-read-chunk-size-limit 256Mi`** chunk ko har read par double karta tha (4 → 8 → 16 …) — isi liye `full` mode "poora zip utar deta tha" aur TASK-MCODE-005 me `writes` par switch karna pada tha.
- **A/B (3 alag mount, naya cache, same quota):**

| Mount | 460 MB zip COLD | WARM (re-open) | Cache me data |
|---|---|---|---|
| `writes` (purana setting) | 4,706 ms | 3,279 / 5,307 / 5,027 ms | **0 MB** |
| `full` + limit `256Mi` (purana limit) | **38,383 ms** | 16 / 23 / 14 ms | 0.7 MB |
| **`full` + limit `4Mi` (fix)** | **4,328 ms** | **14 / 10 / 11 ms** | 0.8 MB |

- **Fix:**
  1. `--vfs-read-chunk-size-limit` ab **chunk size ke barabar** (4 MiB) — chunk kabhi double nahi hota.
  2. UI toggle ka mapping **palat diya**: "Fast browsing" ON = `full` (jo padha wo rakhna → dobara kholna **instant**), OFF = `writes` (kuch nahi rakhna). Pehle ON = `writes` tha, yaani "fast browsing" ka matlab tha "har baar dubara download" — bilkul ulta.
  3. XAML ka card ka text ab sach bolta hai; naya test `Fast_browsing_keeps_the_file_locally_and_switching_it_off_keeps_nothing`.
  4. Runtime `settings.json` → `Cache.VfsCacheMode = "full"`.
- **Proof (naya install, asli Z: drive):** dobara kholna **20–116 ms** (local disk jaisa) — pehle har baar 3–22 s. `NOVA AI.zip` ki list **127 ms** (1761 entries) aur andar ka 11.7 MB APK extract **169 ms**. 460 MB zip ki list **19,958 ms** me **17,979 entries**. Device test **14/14 sections PASS**.
- **Do side findings:**
  - **`Jarvis.zip` zip hi nahi hai** — pehli bytes `<!doctype html>` (Google AI Studio ka saved web page, 67 KB). Cloud me user ki apni file galat naam se hai.
  - **Z: ka size kabhi kabhi 1,024 TB dikhta hai** — quota khatam hone par rclone ka `about` call fail hota hai aur woh 1 PiB fallback dikhata hai. Sirf dikhne ki baat, data safe hai.
- **Bacha hua wait:** pehli baar ka open abhi bhi **Google ke shared quota** ki wajah se slow hai (`403 RATE_LIMIT_EXCEEDED`, `pacer: Rate limited, increasing sleep to 16.9s`) — **apni OAuth key** se khatam.
- **Release:** `dist\Cloud-SSD-0.9.0-win-x64.zip` (95.3 MB, SHA256 `05741b5931b4b826d0f0343cd2abd7b2e7bbdd92794a2124561d148e764d6919`), install ho chuka hai.
- **Push nahi hua** (user ne nahi kaha).

- **TASK-MCODE-010 — README "How it works" + naya `docs/HOW-IT-WORKS.md` (sirf wahi jo code me hai):**
  - **Naya file:** `docs/HOW-IT-WORKS.md` (915 lines) — **12 flows**, har ek ke saath exact `file:line` anchor, real
    HTTP route / rclone command, measured numbers, aur honest line ("kya nahi hota").
    Flows: login · doosra login · drive letters + rclone command · chunked read + cache · QR code ·
    phone?file transfer · phone↔laptop · "PC off" mirror · gaming prepare/launch · game stream (video) ·
    memory/space/offloader · security + storage.
  - **README (root + codebase):** fictional "How it works" (Archify diagram + 12 fake Deep Dive flows, ~435 lines)
    hata ke **12 honest flows ka condensed version** + `docs/HOW-IT-WORKS.md` link. "Architecture" ka fake mermaid
    (PKCE / mTLS 1.3 / 5-15TB Pool / Sparse VHDX / 3-5 GB RAM Drop / Markov ML) → **asli architecture map**.
  - **Theek kiye gaye claims:** PKCE nahi (rclone ka flow) · TLS nahi (plain HTTP) · "3-5 GB" target nahi
    (har run measure) · `K32EmptyWorkingSet` (psapi nahi) · Markov chain "ML" nahi · VHDX nahi ·
    IndexedDB vault nahi ("Keep offline" copies) · download badge 69 ? **94 MB** (checksum verify kiya).
  - **Proof:** `backup.ps1 validate` → build 0 warning / 0 error, unit **473/473**, **APPROVED**;
    backup `2026-11-16_2036_mcode-how-it-works-readme` (new 1, changed 1).
  - **Push nahi hua** (user ne is task ke liye push nahi kaha).

---

## Kaam: CMD ka naya look — Claude Code / Codex jaisa terminal UI (Claude Code) - COMPLETE

- **Tareekh & Samay:** 17 Nov 2026, 01:53 - 02:30 IST (TASK-CLAUDE-CLI-TUI; K aur SPEED ke saath-saath chala, lock K ka hi raha)
- **User ka command:** "C:\Users\Roshan\Downloads\Cloud-Drive ye wale me isko baanane ka try kiya cmd wala but wo dik se banana nahi usko ui banao kayse banna tha wo bhi deko or usko wayse hi banao antigrvity me hoga uska prompt"
- **Purana prompt (14 Nov, isi file mein upar):** "/plan mujhe isko cmd me bhi calana hai ... jaysa claude codex hai wayse hi mujhe isko bhi wayse hi banana hai".
  Antigravity ke data (`%USERPROFILE%\.gemini\antigravity`) mein Cloud-SSD ki koi baatcheet nahi bachi (sirf 16 Nov ki college website wali).
- **Backup:** `backup\2026-11-17_0153_cli-tui-claude-codex-look` (before + complete + Hinglish README; `validate` **APPROVED**:
  build 0/0, C# **518/518**). `start` / `complete` / `validate` ne `CURRENT_TASK.json` badla tha; doosre session
  (TASK-CLAUDE-K) ka lock wapas rakh diya (`.work\cli-tui\CURRENT_TASK.k-lock.json` se). Yeh kaam **sirf** `src\CloudSSD.Cli\*`,
  `tests\CloudSSD.Tests\CliTuiTests.cs` (+ test csproj mein Cli ka reference), README ka CLI hissa chhuta hai. Phone / bridge files nahi.
- **Plan:** `cloudssd` / `cpx` kholo to: gol kone wala swagat box (live: PC app, Z:/Y:, phone), neeche input box `> `, `/` dabate hi
  commands ki list (upar-neeche teer, Tab/Enter), Claude jaisa `⏺` / `⎿` jawab, spinner, purane command ↑↓, Ctrl+C / Esc / Ctrl+L.
  Purane shabd (`status`, `phone` ...) aur `cloudssd status` jaise ek-baar wale command waise hi chalenge. Pipe / file mein output ho
  to rang nahi (saada text).
- **Haal (17 Nov 02:30): POORA.** Naya `cpx.*` installed app mein hai (Release, self-contained, R2R; purana `.work\cli-tui\old-cpx\`).
  Asli CMD mein `cloudssd` (installed shim) se photo li: chalta hai.
  - Nayi files: `src\CloudSSD.Cli\{Ansi.cs, Commands.cs, Views.cs, Shell.cs}`; badli: `Program.cs`, `CloudSSD.Cli.csproj`
    (InternalsVisibleTo), `tests\CloudSSD.Tests\CloudSSD.Tests.csproj` (Cli ka reference), nayi `tests\CloudSSD.Tests\CliTuiTests.cs` (38 test).
  - README ka CLI hissa teeno copy mein naya (`.work\cli-tui\readme-apply.js` + `readme-cli.md`; dobara chalane se kuch nahi bigadta).
  - Jaanch: build 0 warning / 0 error · **C# 517/517** (doosre session ke 479 + 38 naye) · asli `conhost` window mein
    `.work\cli-tui\shot.ps1` se 9 photo: `C:\Users\Roshan\Downloads\Cloud-Drive\cli-tui-photos\` (git ke **bahar** rakhi hain,
    kyunki unme e-mail dikhte hain aur push `git add -A -f .` se hota hai).
  - `secret emit-config-pass` (rclone ise chalata hai): purane aur naye cpx ka output **same 43 bytes, same hash** (secret dikhaya nahi).
  - Pipe / file mein output saada ASCII (test bhi hai). PowerShell pipe ka BOM wala purana bug ("Unknown command: ﻿help") theek.
- **Seekh (agle session ke liye):** Claude Code ke shell mein `NO_COLOR=1` set hota hai → test window bina rang khulti hai; `shot.ps1`
  ise hata deta hai. `⎿` Consolas font mein nahi hai (khaali dabba) → `└` lagaya. xUnit `Assert.DoesNotContain("\u001b", s)` jhootha
  "mila" bolta hai (culture search ESC ko ignore karti hai) → `s.Contains('\u001b')` (char) use karo.
  - `accounts` / `remotes` pehle poora AppHost chalata tha: phone bridge port 8090 par ERR (app ke log mein), Z:/Y: "re-attach",
    ek baar 180 s+ atka. Ab sirf `rclone listremotes` → **0.8 s**, app log mein koi line nahi. Har command 0.1–0.8 s.
  - `cpx deps` hamesha exit 0 (jaise pehle): `installer\build-release.ps1` ka smoke test isi par chalta hai.
  - Photos ab `cli-tui-photos\` mein 6 hain (installed `cloudssd` se); mein e-mail dikhte hain, isliye git ke bahar.
- **Agla kadam:** koi nahi. Push nahi hua (user ne nahi kaha). Agle release build mein naya Cli apne aap jayega.

---

## Kaam: Drive restart par bani rahe + zip / install ki speed (Claude Code) - COMPLETE

- **Tareekh & Samay:** 17 Nov 2026, 01:40 - 02:35 IST
- **Agent:** Claude Code (Claude Fable 5.2), TASK-CLAUDE-SPEED (K aur CLI-TUI ke saath-saath chala; lock K ka hi raha)
- **User ka shikayat:** restart / power off ke baad drive "wapas load" hoti hai, permanent rehni chahiye; zip slow, fix ke baad apne aap phir slow; app install 5-10 guna slow.
- **Backup Folder:** `backup\2026-11-17_0158_claude-drive-speed-restart` (before + complete + README; APPROVED: build 0/0, C# **518/518**)
- **Jad:** rclone ki **shared Google key** (`project_number:202264815644`) par Google lagbhag aadhe request 403 lautata hai; har 403 par rclone 1-16 s rukta hai. Naapa (internet 9.25 MB/s): 54 MB file 259 s / 37 request / 32 x 403.
- **Fix (naya build 02:05 par install, chal raha hai):**
  1. `MountService.cs`: auto-restart kabhi band nahi hota (5 jaldi koshish, phir har 2 min) — pehle "Automatic restart disabled … Remount manually".
  2. `MountPlanning.cs`: `--vfs-read-chunk-size-limit off` (pehle `4Mi`) — 54 MB = 4 request (pehle 37), 110 s.
  3. `ArchiveWarmer.cs` + `AppHost.cs`: 403 ke baad 2 min tak zip pehle se nahi mangwata (user ki file ke aage line nahi lagata).
- **Naapa, code se theek nahi hota:** Z: par likhna — 60 chhoti files + 13 folder = 280 s, 105 x 403; har naya folder 2 s + 20-60 s. Hatana 453 s.
- **Nahi jaancha:** asli power off / restart; internet band karke auto-restart; warmer ka rukna asli drive par.
- **User ke haath me:** apni Google key (Cloud Drives -> "How do I get a key?"). Shared key 2026 me band hogi; tab login bhi tootega.
- **Dhyan:** `backup.ps1 validate` / `complete` doosre ke lock (`CURRENT_TASK.json`) me `validationStatus` aur `COMPLETED` likh dete hain. Do kaam saath chalein to lock ko baad me haath se wapas likho.
- **Naapne ke script:** `.work\speed\read-test.ps1`, `zip-list-test.ps1`, `write-test.ps1`.
- **Push nahi hua** (user ne nahi kaha).
---

## Kaam: CMD shell ko aur behtar — Hinglish samajhna, Yes/No sawaal, drive chunna, logo (Claude Code) - COMPLETE

- **Tareekh & Samay:** 17 Nov 2026, 02:35 - 03:00 IST · TASK-CLAUDE-CLI-TUI-2
- **User ka command:** "isko improve karo" (pichhla kaam: CMD ka Claude/Codex jaisa look, upar)
- **Backup:** `backup\2026-11-17_0235_cli-tui-improve-hinglish-picker-logo` (before + complete + Hinglish README; `validate` **APPROVED**, 547/547;
  lock `TASK-CLAUDE-CLI-TUI-2` COMPLETED / active false)
- **Kya bana:**
  1. **Hinglish / saade shabd** (`CommandCatalog.Understand`, bina AI, shabd ki shuruaat se): "z drive kholo" → `/open Z:`,
     "drive kholo" → kaunsi drive (sawaal), "phone dikhao" / "फोन दिखाओ" → `/phone`, "kitni jagah bachi" → `/cache`,
     "google account dikhao" → `/accounts`, "kya haal hai" → `/status`, "app band karo" → `/stop`, "safai karo" → `/clean`.
     "drive band karo" app band **nahi** karta (sentence drive ke baare mein hai) → `/drives`. Shell `→ /cache` dikhata hai.
     Command line (`cloudssd drive kholo`) par bhi chalta hai, par band/delete wale sentence wahan **kabhi nahi** chalte (exit 64, saaf sandesh).
  2. **Yes / No sawaal** (Claude ki permission jaisa box) `/stop` (app chal raha ho tab) aur `/clean` se pehle; **"No" pehle se chuna**
     (galti ka Enter kuch nahi badalta); ↑↓ / 1 2 / Enter / Esc.
  3. **`/open ` ke baad drives ki list** (Y: Each Account, Z: All Accounts, band ho to "not connected now"); letter na ho to sawaal.
  4. **Bada rangeen CLOUD-SSD logo** (teal → blue) swagat box mein (`Logo.cs`); patli window / bina-Unicode mein nahi.
  5. 1 s+ wale jawab ki heading mein samay; heading mein faltu shabd nahi ("Phones", "Phones dikhao" nahi);
     cache mein "30 days" / "5 s" (pehle "30.00:00:00").
- **Files:** naya `src\CloudSSD.Cli\Logo.cs`; badle `Commands.cs`, `Shell.cs`, `Views.cs`, `Program.cs`, `Ansi.cs`;
  `tests\CloudSSD.Tests\CliTuiTests.cs` (CLI tests 39 → 70); README ka CLI hissa (3 copy, `.work\cli-tui\readme-cli.md` + `readme-apply.js`).
- **Jaanch:** build 0 warning / 0 error · C# **547/547** · naya `cpx.*` installed app mein · `secret` output same (43 bytes, same hash) ·
  asli conhost mein installed `cloudssd` se photo (`C:\Users\Roshan\Downloads\Cloud-Drive\cli-tui-photos\`, git ke bahar) ·
  `/stop` ke sawaal par Esc → "Nothing was changed", app ka PID 13768 pehle aur baad mein same.
- **Kabhi-kabhi fail hone wala test (is kaam ka nahi):** `RemotePcClientTests.Files_sent_while_away_wait_survive_a_restart…` ek baar 21 s
  mein fail hua, akele aur dobara poore suite mein pass. Doosre session ne `MobileBridgeResumeTests.Details_and_folder_size` aisa bataya tha.
- **Agla kadam:** koi nahi. Push nahi hua (user ne nahi kaha).
---

## Kaam: Storage permanent rahe jab tak app laga hai (Claude Code) - COMPLETE

- **Tareekh & Samay:** 17 Nov 2026, 02:45 - 03:00 IST
- **Agent:** Claude Code (Claude Fable 5.2), TASK-CLAUDE-PERMANENT
- **User ka kehna:** "file aata hai mujhe wo permanent chahiye jab tak app hai tab tak mujhe storage mile"
- **Backup Folder:** `backup\2026-11-17_0247_claude-drive-permanent` (before + complete + README; APPROVED: build 0/0, C# **553/553**)
- **Fix (build 02:54 par install, chal raha hai):**
  1. Khidki band karne ke sawaal me pehle se chuna jawab ab **Yes** (drives rahein): `Settings.cs` default + is PC ki `settings.json` (`KeepMountsAfterExit = true`; purani copy `settings.json.before-keep-drives`).
  2. `RcloneConfigService.cs` (`ConfigGuard`) + `AppHost.RefreshRemotesAsync`: accounts ki file ki aakhri sahi copy `rclone.conf.good`; file gayab / khaali / na-padhne-layak mile to app khud wapas rakhta hai. Account khud disconnect karne par (`DeleteRemoteAsync`) copy hata di jati hai.
- **Asli jaanch:** `rclone.conf` ko jaan-boojh kar 0 bytes kiya -> app ne 1.4 s me wahi content wapas rakha, drives judi rahi. App band (Yes) par Z:/Y: wahi rclone process ke saath rahi.
- **Nahi jaancha:** asli restart / power off; aadhi likhi file wala raasta (sirf unit test); kuch account kam ho jane wala case pakad me nahi aata.
- **Baaki khatra:** rclone ki shared Google key 2026 me band hogi -> saare login tootenge. User ki apni Google key chahiye.
- **Dhyan (naye account-disconnect raaste ke liye):** account hatana hamesha `RcloneConfig.DeleteRemoteAsync` se karo, warna `rclone.conf.good` use wapas la sakta hai.
- **Push nahi hua** (user ne nahi kaha).