const fs = require('fs');
const now = process.argv[2];
const B = String.fromCharCode(92);
let s = fs.readFileSync('.work/haal.txt', 'utf8');
s = s.replace(/\*\*Aakhri badlaav:\*\* .*/, '**Aakhri badlaav:** 14 Nov 2026, ' + now + ' — Claude (window A)');
const a = '**Chal raha kaam:** Phase 3 — phone se band PC ki files kholna.';
if (!s.includes(a)) { console.log('missing'); process.exit(1); }
s = s.replace(a,
  '**Chal raha kaam:** band PC ki files phone se — ab **bina Google key** wala raasta (user ne ' + now + ' par kaha: key ke bina karo).\n' +
  'Plan: `docs' + B + 'WHEN_OFF_BINA_KEY_PLAN.md` (pehle ise padho). Raasta A = PC ke folder ki copy phone ke andar ("Offline rakho" ko PC disk ke liye kholna).\n\n' +
  'Bina-key ke kadam (yahi abhi chal rahe hain):\n' +
  '- [ ] K1 PC: `/api/fs/*` mein PC disk ki jad `disk-c:` (sirf padhna, Browse permission, wahi roktham jo `/api/files` par), feature `fs-disk-roots`, tests\n' +
  '- [ ] K2 Phone page: PC disk ki jagah ko id dena (`ssdPlaces`), "Keep offline" PC ke folder par, PC band hone par copy se khulna\n' +
  '- [ ] K3 Ek tap: Permissions → Files when it is off → "mukhya folder phone par rakho"\n' +
  '- [ ] K4 Apne aap taaza hona jaanchna; 5000 files ki seema dekhna\n' +
  '- [ ] K5 Asli jaanch (PC app band karke phone se kholna)\n' +
  '- [ ] K6 "Cloud copy Google Drive mein kholo" button\n' +
  '- [ ] K7 Wake-on-LAN is PC par chalta hai ya nahi (sirf jaanch)\n\n' +
  '**Bina-key ka agla kadam:** K1 (pehle `LocalMobileBridgeService.Files.cs` ke `BrowseRoots` / `ResolveCloudPath` aur `/api/files` ki roktham padho).\n\n' +
  'Neeche Phase 3 (Google key wala) ka haal hai: code ban chuka, key ke bina uski asli jaanch nahi ho sakti; use chheda nahi jayega.');
fs.writeFileSync('.work/haal.txt', s);
