# Implementation Phases

Source of truth for rules: [`GAME_LOGIC.md`](./GAME_LOGIC.md).  
Tune numbers in `src/shared/GameConfig.lua`.

Facility upgrades adalah **Phase 5** (selesai). Raid adalah **Phase 6** (selesai). UI polish adalah **Phase 7** (selesai). Recruitment Board mulai **Phase 8**.

| Phase | Nama | Status | Isi |
| --- | --- | --- | --- |
| 1 | Economy core | Done | Gold, Magic Stone, storage, production `ACTIVE`, converter 1:1 |
| 2 | Recruitment | Done | Recruit Fee, candidate lock, Accept / Reject, Pending maks 10 di board |
| 3 | Collection + Display | Done | List Hero, pad `hero` maks 40, sisanya Tas (`BAGGED`) |
| 4 | Sell / Release | Done | Jual Hero dibeli, refund `floor(AcceptCost × 0.25)` |
| 5 | Facility upgrades | Done | Recruitment level (buka tier), Converter speed |
| 6 | Raid | Done | 1–5 Hero, timer, success/fail, no hero loss |
| 7 | UI polish | Done | Visual, layout, feedback — logic tetap di server |
| 8A | Recruitment Board shell | Done | Frame aset + tombol X; buka saat **sentuh** `summon`; gerak lock sampai X |
| 8B | Board grid | Done | 10 slot (2×5) + rail Recruit 1/5/10X + TAKE/CLEAR/OPEN (tampilan) |
| 8C | Recruit 1X | Done | Kartu tertutup → OPEN ALL → TAKE ALL / CLEAR ALL; tab Recruit HUD dihapus |
| 8D | Altar open | Done | Board dari `altar/summon` (sentuh, bukan jarak / tab HUD) |
| 8E | Board penuh | Done | 5X / 10X, OPEN ALL, TAKE ALL, CLEAR ALL — pending maks 10 |

## Phase 4 — Sell / Release

Selesai kalau:

- Tombol Sell hanya pada Hero `Purchased == true` dan status bukan `RAIDING`
- Refund = `floor(AcceptCost × 0.25)` Gold, Recruit Fee tidak kembali
- Seed / starter Hero tidak bisa dijual
- Hero `RAIDING` tidak bisa dijual
- Setelah jual: Hero hilang dari koleksi + display, production turun
- Transaksi gagal tidak mengubah Gold

## Phase 5 — Facility upgrades

Selesai kalau:

- Upgrade Recruitment dan Converter bayar Gold, gagal tidak mengubah Gold
- Converter upgrade hanya menambah speed; rasio tetap `1 Magic Stone = 1 Gold`
- Recruitment upgrade menaikkan level roll (buka chance tier lebih tinggi)
- Level max tidak bisa di-upgrade lagi
- Pending candidate tidak berubah karena upgrade (stats tetap lock)

## Phase 6 — Raid

Selesai kalau:

- Tim 1–5 Hero, Recommended Power bukan gate
- Maks 1 Raid aktif per player
- Hero `RAIDING` tidak produce, tidak di pad, tidak bisa dijual
- Timer selesai → roll success/fail di server
- Success: Gold (dan bonus loot / ticket / production +20%)
- Fail: tidak ada reward, Hero tidak hilang
- Hero kembali ke pad asalnya jika masih kosong

## Phase 7 — UI polish

Selesai kalau:

- Navbar kanan atas, panel hanya terbuka saat tab diklik
- Feedback status kelihatan (sukses/gagal)
- Timer Raid besar + progress bar saat Raid berjalan
- Marker pad lebih jelas (warna tier, label, PAD number)

## Phase 8A — Recruitment Board shell

Selesai kalau:

- Tab Recruit **tidak** membuka board. Board muncul saat player **berdiri di / menyentuh** `summon` atau `summonplate`
- Saat board terbuka, player tidak bisa jalan / lompat (fokus ke UI)
- X atau klik di luar board menutupnya dan mengembalikan gerak
- Masih berdiri di pad setelah X → tidak auto-buka. Harus turun, lalu sentuh lagi
- Isi board masih kosong (belum slot / pull)
- Recruit Fee, Accept / Reject, pending maks 1 **tidak berubah** (panel Recruit lama tetap di tab HUD)

## Phase 8B — Board grid

Selesai kalau:

- 10 slot kosong (2×5) memakai aset `118354964205016`
- Belum ada Recruit 1X / kartu tertutup / pull
- Logic recruit tidak berubah

## Phase 8C — Recruit 1X on the board

Selesai kalau:

- Tab Recruit di HUD **hilang** (sisa Heroes / Upgrade / Raid)
- RECRUIT 1X bayar fee, isi slot 1 sebagai **kartu tertutup** (`71614679116854`)
- OPEN ALL membuka kartu (tier / type / Power / Production)
- TAKE ALL = Accept gratis, CLEAR ALL = Reject (fee hangus)
- Saat itu masih maks 1 pending; 5X / 10X belum aktif (lihat Phase 8E)

## Phase 8E — Full board pulls

Selesai kalau:

- Board menampung sampai 10 kartu pending
- RECRUIT 5X / 10X bayar fee × 5 / × 10 dan mengisi slot kosong
- Pull ditolak jika slot tidak cukup, Gold tidak cukup, atau roster + pending + pull > 40
- OPEN ALL membuka semua kartu tertutup
- TAKE ALL menerima semua kartu; CLEAR ALL menolak semua (fee hangus)
- Kartu baru tetap tertutup sampai OPEN ALL

Progress player (Gold, Hero, upgrade, Raid) disimpan lewat DataStore.

## Kenapa urutannya begitu

1. Economy harus ada sebelum Recruit (bayar fee).
2. Recruit harus ada sebelum Collection (Hero baru masuk list).
3. Collection harus ada sebelum Sell (player pilih Hero di list).
4. Sell sebelum Raid supaya koleksi bisa dirapikan; lock `RAIDING` tetap di-code dari sekarang.
5. Upgrade lalu Raid: keputusan “upgrade dulu atau raid dulu” baru terasa setelah economy + collection hidup.
6. UI polish terakhir, jangan mengunci layout sebelum sistem inti ada.
