# Hero Recruitment

**Game Logic & Game Design Document**

| Field | Value |
| --- | --- |
| Version | 1.2 |
| Platform | Roblox |
| Status | Design freeze untuk implementasi |

Dokumen ini adalah versi master logic. Semua perubahan terakhir sudah digabung, termasuk:

- Recruit Fee; Accept gratis; Hero mahal sangat jarang
- Pending Candidate
- Magic Stone → Gold **1:1**
- Raid maksimal **5 Hero**
- Sell / Release Hero, refund maksimal **25% nilai katalog Tier**
- Display `hero` maksimal **40 Hero** total; tidak bisa recruit lagi sampai ada yang di-Sell

Sistem berikut **tidak dipakai**: Auto Combine, Manual Combine, Fusion, Evolution, Training, Hero Level.

Urutan kerja implementasi: lihat [`PHASES.md`](./PHASES.md).

---

## Daftar Isi

1. [Game Overview](#1-game-overview)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [Currency & Resource](#3-currency--resource)
4. [Gold](#4-gold)
5. [Magic Stone](#5-magic-stone)
6. [Magic Stone Conversion](#6-magic-stone-conversion)
7. [Hero Recruitment Center](#7-hero-recruitment-center)
8. [Recruitment Flow](#8-recruitment-flow)
9. [Recruit Fee](#9-recruit-fee)
10. [Accept Fee](#10-accept-fee)
11. [Recruit Fee vs Accept Fee](#11-recruit-fee-vs-accept-fee)
12. [Accept Candidate](#12-accept-candidate)
13. [Reject Candidate](#13-reject-candidate)
14. [Insufficient Accept Gold](#14-insufficient-accept-gold)
15. [Pending Candidate](#15-pending-candidate)
16. [Pending Candidate Limit](#16-pending-candidate-limit)
17. [Pending Candidate UI](#17-pending-candidate-ui)
18. [Candidate Data Lock](#18-candidate-data-lock)
19. [Hero Tier](#19-hero-tier)
20. [Random Hero Stats](#20-random-hero-stats)
21. [Hero Power](#21-hero-power)
22. [Hero Production](#22-hero-production)
23. [Hero Display](#23-hero-display)
24. [Hero Production State](#24-hero-production-state)
25. [Magic Stone Storage](#25-magic-stone-storage)
26. [Magic Stone Converter](#26-magic-stone-converter)
27. [Converter Speed](#27-converter-speed)
28. [Converter Behavior](#28-converter-behavior)
29. [Production vs Converter](#29-production-vs-converter)
30. [Recruitment Center Upgrade](#30-recruitment-center-upgrade)
31. [Recruitment Probability](#31-recruitment-probability)
32. [No Auto Combine](#32-no-auto-combine)
33. [No Manual Combine](#33-no-manual-combine)
34. [No Evolution System](#34-no-evolution-system)
35. [No Training System](#35-no-training-system)
36. [Hero Collection](#36-hero-collection)
37. [Raid System](#37-raid-system)
38. [Raid Team](#38-raid-team)
39. [Maximum Raid Hero](#39-maximum-raid-hero)
40. [Raid Maps](#40-raid-maps)
41. [Raid Access](#41-raid-access)
42. [Raid Power Ratio](#42-raid-power-ratio)
43. [Raid Success Chance](#43-raid-success-chance)
44. [Raid Success Chance Principle](#44-raid-success-chance-principle)
45. [Perfect / Overpowered Raid](#45-perfect--overpowered-raid)
46. [Raid Start](#46-raid-start)
47. [Hero Raid State](#47-hero-raid-state)
48. [Raid Timer](#48-raid-timer)
49. [Raid Display](#49-raid-display)
50. [Raid Completion](#50-raid-completion)
51. [Raid Success](#51-raid-success)
52. [Raid Failure](#52-raid-failure)
53. [Raid Opportunity Cost](#53-raid-opportunity-cost)
54. [Raid Reward Philosophy](#54-raid-reward-philosophy)
55. [Guaranteed Raid Reward](#55-guaranteed-raid-reward)
56. [Random Bonus Loot](#56-random-bonus-loot)
57. [Recruitment Ticket](#57-recruitment-ticket)
58. [Elite Recruitment Ticket](#58-elite-recruitment-ticket)
59. [Raid Production Bonus](#59-raid-production-bonus)
60. [Raid Map Reward Example](#60-raid-map-reward-example)
61. [Raid Reward Scaling](#61-raid-reward-scaling)
62. [Hero Display vs Raid](#62-hero-display-vs-raid)
63. [Gold Economy Loop](#63-gold-economy-loop)
64. [Progression Loop](#64-progression-loop)
65. [Hero Quality](#65-hero-quality)
66. [Hero Role Secara Implisit](#66-hero-role-secara-implisit)
67. [Perfect Hero](#67-perfect-hero)
68. [No Direct Gold Production](#68-no-direct-gold-production)
69. [Converter Upgrade Decision](#69-converter-upgrade-decision)
70. [Recruitment Decision](#70-recruitment-decision)
71. [Pending Candidate Strategy](#71-pending-candidate-strategy)
72. [Pending Candidate Restriction](#72-pending-candidate-restriction)
73. [Candidate Accept Transaction](#73-candidate-accept-transaction)
74. [Candidate Accept Failure](#74-candidate-accept-failure)
75. [Candidate Data](#75-candidate-data)
76. [Hero Data](#76-hero-data)
77. [Raid Data](#77-raid-data)
78. [Raid Validation](#78-raid-validation)
79. [Raid Hero Lock](#79-raid-hero-lock)
80. [Raid Completion Resolve](#80-raid-completion-resolve)
81. [Raid Failure Consequence](#81-raid-failure-consequence)
82. [Raid Risk](#82-raid-risk)
83. [Raid Strategy](#83-raid-strategy)
84. [Display Management](#84-display-management)
85. [Total Production](#85-total-production)
86. [Total Team Power](#86-total-team-power)
87. [Raid vs Production Decision](#87-raid-vs-production-decision)
88. [Upgrade Priority](#88-upgrade-priority)
89. [No Hero Leveling System](#89-no-hero-leveling-system)
90. [No Fusion](#90-no-fusion)
91. [Game Economy](#91-game-economy)
92. [Main Progression](#92-main-progression)
93. [Gameplay Identity](#93-gameplay-identity)
94. [Final Game Loop](#94-final-game-loop)
95. [Systems Not Included](#95-systems-not-included)
96. [Final System Summary](#96-final-system-summary)
97. [One-Line Game Concept](#97-one-line-game-concept)
98. [Core Philosophy](#98-core-philosophy)
99. [Sell / Release Hero](#99-sell--release-hero)
100. [Sell Refund](#100-sell-refund)
101. [Sell Restrictions](#101-sell-restrictions)
102. [Sell Transaction](#102-sell-transaction)
103. [Sell vs Reject](#103-sell-vs-reject)
104. [Display Slots & Bag](#104-display-slots--bag)

---

## 1. Game Overview

Game Roblox ini menggabungkan:

- Hero Recruitment
- Hero Collection
- Idle Production
- Resource Conversion
- Hero Management
- Risk & Reward Raid
- Base / Facility Upgrade

### Core Gameplay

```text
RECRUIT
   ↓
CANDIDATE
   ↓
ACCEPT / REJECT
   ↓
HERO
   ↓
PRODUCTION
   ↓
MAGIC STONE
   ↓
CONVERTER
   ↓
GOLD
   ↓
UPGRADE / RECRUIT
   ↓
BETTER HEROES
   ↓
RAID
   ↓
REWARD
   ↓
MORE PROGRESSION
```

### Tujuan Utama Player

Mendapatkan Hero dengan kombinasi **Tier**, **Power**, dan **Production** yang bagus, membangun koleksi Hero, menghasilkan Magic Stone, mengubahnya menjadi Gold, melakukan upgrade, dan menggunakan maksimal **5 Hero terbaik** untuk menjalankan Raid.

---

## 2. Core Gameplay Loop

```text
              🪙 GOLD
                 │
                 ▼
        🏢 HERO RECRUITMENT
                 │
          PAY RECRUIT FEE
                 │
                 ▼
           👤 CANDIDATE
                 │
          ┌──────┴──────┐
          ▼             ▼
       ❌ REJECT      ✅ ACCEPT
          │             │
          │             ▼
          │       CHECK ACCEPT FEE
          │             │
          │      ┌──────┴──────┐
          │      ▼             ▼
          │   ENOUGH        NOT ENOUGH
          │      │             │
          │      ▼             ▼
          │   PAY FEE      SAVE CANDIDATE
          │      │             │
          │      ▼             ▼
          │   🦸 HERO      📦 PENDING
          │                    │
          │                 EARN GOLD
          │                    │
          │                    ▼
          │               ACCEPT HERO
          │
          └──────────────► RECRUIT AGAIN
                               │
                               ▼
                           🦸 HERO
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
                 DISPLAY                 RAID
                    │                     │
                    ▼                     ▼
              💎 PRODUCTION         ⚔️ 5 HEROES
                    │                     │
                    ▼                     ▼
              💎 MAGIC STONE       SUCCESS / FAIL
                    │                     │
                    ▼                     ▼
               ⚙️ CONVERTER          🎁 REWARD
                    │
                    ▼
                 🪙 GOLD
                    │
             ┌──────┴──────┐
             ▼             ▼
          RECRUIT       UPGRADE
```

---

## 3. Currency & Resource

Game hanya memakai **dua resource utama**:

| Resource | Peran |
| --- | --- |
| Gold | Currency utama |
| Magic Stone | Hasil production Hero |

Tidak memakai banyak jenis currency agar ekonomi tetap mudah dipahami.

---

## 4. Gold

Gold adalah currency utama dan paling fleksibel.

Gold digunakan untuk:

- Recruit Hero
- Upgrade Hero Recruitment
- Upgrade Magic Stone Converter
- Upgrade fasilitas lainnya

---

## 5. Magic Stone

Magic Stone adalah resource yang dihasilkan oleh Hero.

**Hero tidak menghasilkan Gold secara langsung.**

```text
🦸 HERO
   ↓
💎 MAGIC STONE
   ↓
📦 STORAGE
   ↓
⚙️ CONVERTER
   ↓
🪙 GOLD
```

Magic Stone bukan currency utama. Magic Stone adalah hasil production.

---

## 6. Magic Stone Conversion

Rasio konversi **selalu tetap**:

```text
1 Magic Stone = 1 Gold
```

Contoh:

```text
100 Magic Stone
      ↓
   Converter
      ↓
100 Gold
```

Tidak ada perubahan rasio. Player **tidak dapat** meng-upgrade:

- 1 → 2
- 1 → 5
- 1 → 10

Yang dapat di-upgrade hanya **kecepatan converter**.

---

## 7. Hero Recruitment Center

| Item | Nilai |
| --- | --- |
| Nama sistem | Hero Recruitment |
| Fungsi | Menghasilkan kandidat Hero secara random |

Recruitment Center dapat di-upgrade. Upgrade meningkatkan:

- Tier Hero yang dapat muncul
- Kemungkinan munculnya tier lebih tinggi
- Kualitas pool kandidat

Upgrade **tidak otomatis** meningkatkan stat setiap Hero yang sudah dimiliki.

---

## 8. Recruitment Flow

Ketika player menekan tombol **Recruit**:

```text
Player
  ↓
Check Recruit Fee
  ↓
Gold cukup?
  ├── NO
  │    ↓
  │ Recruitment gagal
  │
  └── YES
       ↓
    Kurangi Gold
       ↓
Generate Candidate
       ↓
Generate Hero Type
       ↓
Generate Tier
       ↓
Generate Power
       ↓
Generate Production
       ↓
Generate Catalog Value
       ↓
Tampilkan Candidate
```

**Recruit Fee** dibayar untuk roll. **Accept gratis.** Hero mahal jarang muncul.

---

## 9. Recruit Fee

Recruit Fee adalah biaya untuk menjalankan proses recruitment.

Contoh:

| Item | Nilai |
| --- | --- |
| Recruit Cost | 100 Gold |

Player membayar 100 Gold untuk melihat kandidat.

```text
100 Gold
   ↓
Candidate Generated
```

Aturan Recruit Fee:

- Tidak dikembalikan
- Tetap hangus meskipun candidate ditolak
- Tidak termasuk Accept Fee

---

## 10. Accept Fee

Accept **gratis**. Tidak ada Gold tambahan untuk mengambil candidate.

Nilai katalog per Tier tetap disimpan sebagai `AcceptCost` untuk Sell (refund 25%), bukan untuk ditagih saat Accept.

| Tier | Catalog (Sell) |
| --- | ---: |
| B1 | 100 Gold |
| B2 | 250 Gold |
| B3 | 600 Gold |
| B4 | 1,500 Gold |
| B5 | 4,000 Gold |
| B6 | 10,000 Gold |
| B7 | 25,000 Gold |

---

## 11. Recruit Fee vs Accept Fee

Contoh:

Player melakukan Recruit seharga **100 Gold**, lalu mendapatkan B5.

```text
Recruit Fee   100 Gold
Accept        FREE
────────────────────────
Total         100 Gold
```

Biaya Hero mahal adalah **kesempatan roll yang sangat kecil**, bukan harga Accept.

---

## 12. Accept Candidate

Accept **tidak memotong Gold**.

```text
Candidate
   ↓
Player klik ACCEPT
   ↓
Candidate menjadi Hero
   ↓
Hero masuk Collection
```

Hero langsung dapat digunakan. **Tidak ada training.**

---

## 13. Reject Candidate

Jika player memilih **REJECT**:

```text
Candidate
   ↓
Deleted
```

- Recruit Fee tetap hangus
- Accept tidak memotong Gold

Contoh:

| Item | Nilai |
| --- | --- |
| Recruit | 100 Gold |
| Candidate | B5 |
| Aksi | REJECT |
| Result | -100 Gold, candidate hilang |

Player harus Recruit lagi jika ingin mencari kandidat baru.

---

## 14. Insufficient Accept Gold

Tidak dipakai. Accept gratis, jadi kekurangan Gold tidak menahan Accept.

Pending Candidate tetap ada sampai TAKE ALL / CLEAR ALL, atau board penuh (maks 10 kartu).

---

## 15. Pending Candidate

Pending Candidate adalah candidate yang sudah di-roll tetapi belum di-Accept atau Reject.

Candidate tetap tersimpan sampai:

- Player memiliki Gold cukup dan menerima Hero
- Player secara manual memilih Reject
- Candidate dihapus melalui aturan khusus yang nantinya ditentukan

Default:

| Aturan | Nilai |
| --- | --- |
| Expire | Tidak ada |
| Countdown | Tidak ada |
| Perubahan stat | Tidak ada |
| Reroll | Tidak ada |

---

## 16. Pending Candidate Limit

Untuk menjaga ekonomi, board menampung maksimal **10 Pending Candidate**.

Recruit 1X / 5X / 10X hanya mengisi slot kosong. Kalau slot atau roster 40 penuh, pull ditolak. TAKE ALL = Accept semua. CLEAR ALL = Reject semua (fee hangus).

```text
Recruit 1X / 5X / 10X
      ↓
Empty slots on the board?
      │
      ├── NO (pending + pull > 10)
      │    ↓
      │ Pull ditolak — TAKE ALL atau CLEAR ALL dulu
      │
      └── YES
           ↓
      Heroes + pending + pull ≤ 40?
           │
           ├── NO → pull ditolak, jual Hero dulu
           └── YES → bayar fee × jumlah, isi slot kosong
```

Kartu baru tetap tertutup sampai OPEN ALL. TAKE ALL = Accept semua. CLEAR ALL = Reject semua (fee hangus).

---

## 17. Pending Candidate UI

Jika Gold belum cukup:

```text
┌───────────────────────────────┐
│        👤 CANDIDATE           │
│                               │
│          LEGENDARY            │
│             B5                │
│                               │
│     ⚔️ Power      247         │
│     💎 Income     +138/s      │
│                               │
│     Accept Cost               │
│     🪙 4,000 Gold             │
│                               │
│     Your Gold                 │
│     🪙 1,250 Gold             │
│                               │
│     ⚠️ Insufficient Gold      │
│                               │
│     Candidate Saved           │
└───────────────────────────────┘
```

Setelah Gold mencapai 4,000:

```text
┌───────────────────────────────┐
│        👤 CANDIDATE           │
│             B5                │
│                               │
│     ⚔️ Power      247         │
│     💎 Income     +138/s      │
│                               │
│     Accept Cost               │
│     🪙 4,000 Gold             │
│                               │
│     Your Gold                 │
│     🪙 4,000 Gold             │
│                               │
│       [ ACCEPT ]              │
└───────────────────────────────┘
```

---

## 18. Candidate Data Lock

Ketika Candidate dibuat, seluruh data langsung ditentukan dan harus disimpan.

Contoh:

| Field | Nilai |
| --- | --- |
| Candidate ID | 928471 |
| Hero Type | Knight |
| Tier | B5 |
| Power | 247 |
| Production | 138/s |
| Accept Cost | 4,000 Gold |

Ketika candidate menjadi Pending:

- Tidak boleh dilakukan random ulang
- Ketika player kembali, candidate harus tetap sama

---

## 19. Hero Tier

Tier menunjukkan rarity / tingkat kelangkaan Hero.

Contoh: `B1`, `B2`, `B3`, `B4`, `B5`, `B6`, `B7`, ...

Semakin tinggi Tier:

- Semakin langka
- Semakin mahal Accept Fee
- Potensi Power semakin tinggi
- Potensi Production semakin tinggi
- Visual dapat semakin bagus
- Potensi performa Raid semakin tinggi

**Tier bukan jaminan stat sempurna.**

---

## 20. Random Hero Stats

Setiap Hero memiliki stat random.

| Hero | Tier | Power | Production |
| --- | --- | ---: | ---: |
| Hero A | B5 | 150 | 70/s |
| Hero B | B5 | 210 | 115/s |

Keduanya sama-sama B5, tetapi Hero B memiliki roll yang lebih bagus.

---

## 21. Hero Power

Power digunakan untuk **Raid**.

Contoh:

| Field | Nilai |
| --- | --- |
| Hero | B5 Knight |
| Power | 210 |

- Power tidak menghasilkan Gold
- Power hanya digunakan untuk menentukan kekuatan team Raid

---

## 22. Hero Production

Production menentukan jumlah Magic Stone yang dihasilkan Hero setiap detik.

| Hero | Production |
| --- | ---: |
| Hero A | 10/s |
| Hero B | 25/s |
| Hero C | 40/s |
| **Total** | **75 Magic Stone/s** |

---

## 23. Hero Display

Hero yang tidak sedang digunakan untuk Raid berada di area display.

```text
🏢 HERO DISPLAY

🦸       🦸

    🦸

🦸       🦸
```

Hero di display muncul di pad **hero**. Maksimal **40 Hero** di panggung.

Kalau display penuh, Hero baru hasil Accept masuk **Tas** (`BAGGED`), bukan ke pad.

Hero di display dan di Tas tetap menghasilkan Magic Stone. Hanya status `RAIDING` yang menjeda production.

---

## 24. Hero Production State

Hero memiliki tiga status:

| Status | Lokasi | Production |
| --- | --- | --- |
| `ACTIVE` | Pad `hero` (maks 40) | Aktif |
| `BAGGED` | Tas | Aktif |
| `RAIDING` | Raid | Dijeda |

Hero menghasilkan Magic Stone jika statusnya `ACTIVE` atau `BAGGED`.

---

## 25. Magic Stone Storage

Magic Stone yang dihasilkan Hero masuk ke storage.

Contoh: `2,500 / 10,000`

Storage memiliki kapasitas. Jika storage penuh:

| Item | Nilai |
| --- | --- |
| Production | +100/s |
| Storage | 10,000 / 10,000 |

Maka production baru **tidak dapat masuk**.

Player perlu menggunakan Converter, atau meningkatkan kapasitas storage jika sistem storage upgrade ditambahkan nanti.

---

## 26. Magic Stone Converter

Converter mengubah Magic Stone menjadi Gold.

```text
1 Magic Stone = 1 Gold
```

Contoh:

```text
500 Magic Stone
      ↓
Converter
      ↓
500 Gold
```

---

## 27. Converter Speed

Converter memiliki processing speed.

| Converter Level | Speed |
| --- | ---: |
| Lv.1 | 10/s |
| Lv.2 | 25/s |
| Lv.3 | 50/s |
| Lv.4 | 100/s |
| Lv.5 | 200/s |

Angka dapat diubah untuk balancing.

---

## 28. Converter Behavior

Jika storage berisi **5,000 Magic Stone** dan converter **100/s**, maka setiap detik:

```text
-100 Magic Stone
+100 Gold
```

Jika storage hanya memiliki 30:

| Item | Nilai |
| --- | --- |
| Storage | 30 |
| Converter | 100/s |
| Processed | 30 Magic Stone |

Converter tidak dapat menghasilkan Gold dari resource yang tidak ada.

---

## 29. Production vs Converter

Contoh:

| Item | Nilai |
| --- | ---: |
| Hero Production | 1,000 Magic Stone/s |
| Converter | 100/s |
| Net storage | +900 Magic Stone/s |

Player harus meningkatkan Converter agar Gold tidak tertahan di storage.

---

## 30. Recruitment Center Upgrade

Recruitment Center dapat di-upgrade menggunakan Gold.

Tujuan utama: membuka kemungkinan tier yang lebih tinggi.

| Level | Tier yang bisa muncul |
| --- | --- |
| Level 1 | B1, B2 |
| Level 2 | B1, B2, B3 |
| Level 3 | B1, B2, B3, B4 |
| Level 4 | B1, B2, B3, B4, B5 |

Dan seterusnya.

---

## 31. Recruitment Probability

Angka berikut adalah **contoh balancing**.

### Recruitment Level 1

| Tier | Chance |
| --- | ---: |
| B1 | 93% |
| B2 | 7% |

### Recruitment Level 2

| Tier | Chance |
| --- | ---: |
| B1 | 85% |
| B2 | 14% |
| B3 | 1% |

### Recruitment Level 3

| Tier | Chance |
| --- | ---: |
| B1 | 80% |
| B2 | 16% |
| B3 | 3% |
| B4 | 1% |

### Recruitment Level 4

| Tier | Chance |
| --- | ---: |
| B1 | 76% |
| B2 | 20% |
| B3 | 3% |
| B4 | 0.9% |
| B5 | 0.1% |

### Recruitment Level 5

| Tier | Chance |
| --- | ---: |
| B1 | 68% |
| B2 | 23% |
| B3 | 7% |
| B4 | 1.8% |
| B5 | 0.2% |

---

## 32. No Auto Combine

Sistem Auto Combine **tidak digunakan**.

Tidak ada:

```text
3 × B1 → B2
3 × B2 → B3
3 × B3 → B4
3 × B4 → B5
```

Jika player memiliki tiga B1, ketiganya tetap Hero individual.

---

## 33. No Manual Combine

Player juga tidak dapat melakukan combine secara manual.

Tidak ada tombol **COMBINE**. Setiap Hero tetap individual.

---

## 34. No Evolution System

Tidak ada sistem Evolution. Hero tidak memiliki:

- Evolution Level
- Evolution Material
- Evolution Form
- Evolution Upgrade

Progression Hero berasal dari:

- Recruitment tier
- Random stats
- Collection
- Raid usage

---

## 35. No Training System

Tidak ada Training. Ketika player berhasil Accept Candidate:

```text
Candidate
   ↓
ACCEPT
   ↓
🦸 HERO
   ↓
READY
```

Hero langsung dapat:

- Dipajang
- Menghasilkan Magic Stone
- Digunakan untuk Raid

---

## 36. Hero Collection

Player memiliki Hero Collection.

Contoh:

| Hero | Power | Production |
| --- | ---: | ---: |
| B1 Knight | 20 | 5/s |
| B2 Archer | 48 | 16/s |
| B3 Mage | 74 | 29/s |
| B5 Knight | 210 | 113/s |

Tidak ada batas combine. Jumlah Hero dapat bertambah selama player memperoleh dan menerima Candidate.

Display world hanya menampung **40 Hero** di aset `hero`. Sisanya masuk Tas. Lihat seksi 104.

Player dapat merapikan koleksi dengan **Sell / Release**. Itu bukan Combine. Lihat seksi 99–103.

---

## 37. Raid System

Raid adalah sistem yang menggunakan **Power Hero**.

Player memilih maksimal **5 Hero**. Hero yang dipilih akan dikirim ke Raid.

---

## 38. Raid Team

Contoh:

| Hero | Power |
| --- | ---: |
| Hero 1 | 420 |
| Hero 2 | 380 |
| Hero 3 | 310 |
| Hero 4 | 290 |
| Hero 5 | 250 |
| **Team Power** | **1,650** |

---

## 39. Maximum Raid Hero

Maximum Hero dalam satu Raid: **5 Hero**.

Player tidak dapat membawa lebih dari 5 Hero. Player boleh membawa kurang dari 5 Hero.

Semua jumlah berikut valid: 1, 2, 3, 4, atau 5 Hero.

---

## 40. Raid Maps

Game memiliki **5 Raid Map**.

| Map | Recommended Power | Duration |
| --- | ---: | ---: |
| 🌲 Whispering Forest | 500 | 3 menit |
| 🏜️ Desert Ruins | 2,000 | 5 menit |
| 🌋 Volcano Fortress | 7,500 | 7 menit |
| ❄️ Frozen Citadel | 20,000 | 10 menit |
| 🌌 Void Fortress | 50,000 | 15 menit |

Recommended Power **bukan requirement mutlak**.

---

## 41. Raid Access

Player tetap dapat memasuki map meskipun Power berada di bawah Recommended Power.

Contoh:

| Item | Nilai |
| --- | ---: |
| Recommended | 7,500 |
| Player Team | 3,000 |

Player tetap dapat **START RAID**, tetapi success chance rendah.

---

## 42. Raid Power Ratio

```text
Power Ratio = Team Power / Recommended Power
```

Contoh:

```text
Team Power     = 3,000
Recommended    = 7,500
Ratio          = 3,000 / 7,500 = 0.40
```

---

## 43. Raid Success Chance

Contoh balancing:

| Condition | Success Chance |
| --- | ---: |
| Ratio >= 1.50 | 100% |
| Ratio >= 1.25 | 95% |
| Ratio >= 1.00 | 85% |
| Ratio >= 0.75 | 60% |
| Ratio >= 0.50 | 35% |
| Ratio >= 0.25 | 10% |
| Ratio < 0.25 | 5% |

Angka final dapat disesuaikan.

---

## 44. Raid Success Chance Principle

- Semakin tinggi Team Power dibanding Recommended Power, semakin tinggi peluang berhasil
- Semakin rendah Team Power, semakin tinggi risiko gagal
- Recommended Power **tidak menjamin 100% success**

---

## 45. Perfect / Overpowered Raid

Jika Team Power jauh lebih tinggi:

| Item | Nilai |
| --- | ---: |
| Recommended | 10,000 |
| Team | 20,000 |
| Success | 100% |

Selain itu dapat diberikan **Bonus Loot Chance**.

Contoh: Bonus Loot `+50%`.

---

## 46. Raid Start

Ketika player menekan **START RAID**, sistem melakukan:

1. Validate Hero
2. Validate Hero tidak sedang Raid
3. Validate jumlah Hero `<= 5`
4. Calculate Team Power
5. Calculate Success Chance
6. Lock Hero
7. Set Hero Status = `RAIDING`
8. Hide Hero dari Display
9. Pause Production
10. Start Raid Timer

---

## 47. Hero Raid State

Ketika Raid aktif, Hero Status = `RAIDING`.

Hero:

- Tidak dapat digunakan Raid lain
- Tidak dapat menghasilkan Magic Stone
- Tidak muncul di display
- Tidak dapat digunakan untuk aktivitas lain
- Tetap dimiliki player

---

## 48. Raid Timer

Timer map adalah **durasi maksimal**. Power party yang lebih tinggi bisa mempercepat Raid.

```text
Power Ratio = Team Power / Recommended Power
```

- Ratio **<= 1.0** → durasi penuh
- Ratio **1.0 → 1.5** → semakin cepat, turun ke 50% durasi
- Ratio **>= 1.5** → lantai **50%** durasi (tidak lebih cepat)

Durasi dikunci saat START RAID.

| Map | Durasi maks |
| --- | --- |
| Whispering Forest | 3 menit |
| Desert Ruins | 5 menit |
| Volcano Fortress | 7 menit |
| Frozen Citadel | 10 menit |
| Void Fortress | 15 menit |

Timer dimulai ketika Raid benar-benar dimulai.

---

## 49. Raid Display

```text
⚔️ RAID IN PROGRESS

Whispering Forest

Team Power:       1,650
Success Chance:   95%
Time Remaining:   02:31

🦸 🦸 🦸 🦸 🦸
DEPLOYED
```

---

## 50. Raid Completion

Ketika timer mencapai 0:

```text
Raid Timer
   ↓
0
   ↓
Resolve Raid
   ↓
Generate Random Result
   ↓
Success / Fail
```

---

## 51. Raid Success

Jika random result berhasil:

```text
⚔️ RAID SUCCESS
```

Player mendapatkan Reward.

```text
Raid Success
    ↓
Generate Reward
    ↓
Give Reward
    ↓
Return Hero
    ↓
Hero Status = ACTIVE
    ↓
Production Resume
```

---

## 52. Raid Failure

Jika random result gagal:

```text
⚔️ RAID FAILED
```

Player:

- Tidak mendapatkan reward Raid
- Tidak kehilangan Hero
- Tidak kehilangan Power
- Tidak kehilangan Production
- Tidak kehilangan Tier
- Tidak kehilangan level
- Tidak membayar penalty tambahan

```text
Raid Fail
   ↓
No Reward
   ↓
Return Hero
   ↓
Hero Status = ACTIVE
   ↓
Production Resume
```

---

## 53. Raid Opportunity Cost

Walaupun tidak ada Hero Loss, player tetap mengambil risiko.

Selama Hero berada di Raid: **Production = 0**.

Contoh 5 Hero:

| Hero | Production |
| --- | ---: |
| Hero 1 | 100/s |
| Hero 2 | 120/s |
| Hero 3 | 150/s |
| Hero 4 | 180/s |
| Hero 5 | 200/s |
| **Total** | **750 Magic Stone/s** |

Jika mereka Raid selama 5 menit:

```text
750 × 300 = 225,000 Magic Stone
```

Production tersebut tidak diperoleh selama Hero Raid. Jadi player harus mempertimbangkan **Farming vs Raid**.

---

## 54. Raid Reward Philosophy

Raid reward harus terasa jauh lebih menarik dibanding hanya menunggu Production.

Reward dapat terdiri dari:

- Gold
- Magic Stone
- Recruitment Ticket
- Elite Recruitment Ticket
- Temporary Production Bonus
- Random Bonus Loot

---

## 55. Guaranteed Raid Reward

Setiap Raid yang berhasil mendapatkan Guaranteed Reward.

Contoh Whispering Forest:

| Item | Nilai |
| --- | --- |
| Map | 🌲 Whispering Forest |
| Guaranteed | 🪙 50,000 Gold |

---

## 56. Random Bonus Loot

Selain Guaranteed Reward, Raid dapat memberikan random bonus.

Contoh:

| Bonus | Chance |
| --- | ---: |
| Gold | 70% |
| Magic Stone | 20% |
| Recruit Ticket | 9% |
| Elite Recruit Ticket | 1% |

Probability dapat disesuaikan berdasarkan map.

---

## 57. Recruitment Ticket

Recruitment Ticket memungkinkan player melakukan recruitment tanpa membayar Recruit Fee.

Contoh:

```text
🎟️ Recruit Ticket ×1
Use: FREE RECRUIT
```

**Accept tetap gratis.** Ticket hanya menghapus Recruit Fee.

Contoh:

| Item | Nilai |
| --- | --- |
| Recruit Fee | FREE |
| Candidate | B5 |
| Accept | FREE |

---

## 58. Elite Recruitment Ticket

Elite Recruitment Ticket adalah reward langka dari Raid tingkat tinggi.

Elite Recruitment dapat memberikan **minimum Tier lebih tinggi**.

Contoh:

| Item | Nilai |
| --- | --- |
| Minimum | B3+ |
| Possible | B3, B4, B5, B6 |

Accept tetap gratis.

---

## 59. Raid Production Bonus

Raid sukses dapat memberikan temporary production bonus.

Contoh:

| Item | Nilai |
| --- | --- |
| Bonus | +20% Production |
| Duration | 10 minutes |

Jika normal 1,000 Magic Stone/s:

```text
1,000 × 1.20 = 1,200 Magic Stone/s
```

---

## 60. Raid Map Reward Example

Semua angka reward masih dapat diubah saat balancing ekonomi.

| Map | Recommended Power | Duration | Base Reward | Additional |
| --- | ---: | --- | --- | --- |
| 🌲 Whispering Forest | 500 | 3 menit | 50,000 Gold | — |
| 🏜️ Desert Ruins | 2,000 | 5 menit | 250,000 Gold | — |
| 🌋 Volcano Fortress | 7,500 | 7 menit | 1,000,000 Gold | — |
| ❄️ Frozen Citadel | 20,000 | 10 menit | 3,000,000 Gold | — |
| 🌌 Void Fortress | 50,000 | 15 menit | 5,000,000+ Gold | Elite Recruitment Ticket |

---

## 61. Raid Reward Scaling

Map yang lebih tinggi harus memberikan:

- Reward lebih tinggi
- Risiko lebih tinggi
- Recommended Power lebih tinggi
- Duration lebih lama
- Bonus Loot lebih menarik

Player harus merasa:

> Kalau Hero gue semakin kuat, gue bisa masuk map yang reward-nya jauh lebih besar.

---

## 62. Hero Display vs Raid

Hero mempunyai dua kondisi utama.

### Display / Active

```text
Hero
 ↓
Display
 ↓
Production ON
```

### Raiding

```text
Hero
 ↓
Raid
 ↓
Production OFF
```

Setelah Raid selesai:

```text
Raid
 ↓
Hero Return
 ↓
Display
 ↓
Production ON
```

---

## 63. Gold Economy Loop

Gold digunakan untuk:

```text
🪙 GOLD
  │
  ├── Recruit Fee
  ├── Accept Fee
  ├── Recruitment Upgrade
  └── Converter Upgrade
```

Gold juga bisa kembali sedikit dari **Sell Hero** (maksimal 25% Accept Fee). Recruit Fee tidak pernah kembali.

Gold diperoleh dari:

```text
💎 MAGIC STONE
      ↓
⚙️ CONVERTER
      ↓
🪙 GOLD

⚔️ RAID
      ↓
🎁 GOLD REWARD

🦸 SELL HERO
      ↓
🪙 25% ACCEPT FEE
```

---

## 64. Progression Loop

```text
MORE GOLD
    ↓
UPGRADE RECRUITMENT
    ↓
HIGHER TIER POSSIBILITY
    ↓
BETTER HEROES
    ↓
HIGHER POWER / PRODUCTION
    ↓
BETTER RAID PERFORMANCE
    ↓
HIGHER RAID REWARD
    ↓
MORE GOLD
```

Parallel:

```text
MORE GOLD
    ↓
UPGRADE CONVERTER
    ↓
FASTER MAGIC STONE → GOLD
    ↓
MORE AVAILABLE GOLD
```

---

## 65. Hero Quality

Hero quality tidak hanya ditentukan Tier. Hero memiliki tiga faktor utama:

1. Tier
2. Power
3. Production

| Hero | Power | Production | Lebih cocok untuk |
| --- | ---: | ---: | --- |
| B5 | 250 | 60/s | Raid |
| B5 | 180 | 150/s | Production |

---

## 66. Hero Role Secara Implisit

Tidak perlu membuat sistem class khusus. Stat menciptakan dua tipe Hero secara natural:

### Power-Oriented

| Stat | Nilai |
| --- | --- |
| Power | HIGH |
| Production | MEDIUM / LOW |

Cocok untuk Raid.

### Production-Oriented

| Stat | Nilai |
| --- | --- |
| Power | MEDIUM / LOW |
| Production | HIGH |

Cocok untuk farming.

### Balanced

| Stat | Nilai |
| --- | --- |
| Power | HIGH |
| Production | HIGH |

Sangat langka dan sangat berharga.

---

## 67. Perfect Hero

Hero dengan **High Tier + High Power + High Production** merupakan Hero yang sangat bernilai.

Contoh:

| Field | Nilai |
| --- | --- |
| Tier | B5 |
| Power | 245 |
| Production | 150/s |

Hero seperti ini cocok untuk Display, Production, dan Raid.

---

## 68. No Direct Gold Production

Hero **tidak boleh** langsung menghasilkan Gold.

Salah:

```text
Hero → Gold
```

Benar:

```text
Hero → Magic Stone → Converter → Gold
```

Tujuannya agar Converter memiliki fungsi penting dalam gameplay.

---

## 69. Converter Upgrade Decision

Player harus menentukan prioritas: **Recruitment Upgrade** atau **Converter Upgrade**.

| Upgrade | Keuntungan |
| --- | --- |
| Recruitment | Potensi mendapatkan Hero lebih langka |
| Converter | Magic Stone dapat dikonversi lebih cepat |

Ini menciptakan keputusan ekonomi.

---

## 70. Recruitment Decision

Recruitment memiliki dua tahap keputusan.

### Tahap 1

Apakah saya mau membayar Recruit Fee untuk mendapatkan Candidate?

### Tahap 2

Setelah melihat Candidate, apakah Hero ini layak dibayar Accept Fee?

Contoh A — mungkin **Reject**:

| Field | Nilai |
| --- | --- |
| Recruit | 100 Gold |
| Tier | B2 |
| Power | 45 |
| Production | 12/s |
| Accept | 250 Gold |

Contoh B — mungkin **harus grinding Gold** untuk mengambilnya:

| Field | Nilai |
| --- | --- |
| Tier | B5 |
| Power | 240 |
| Production | 140/s |
| Accept | 4,000 Gold |

---

## 71. Pending Candidate Strategy

Pending Candidate membuat player tidak kehilangan Hero bagus hanya karena kekurangan Gold.

Contoh:

| Item | Nilai |
| --- | ---: |
| Player Gold | 1,000 |
| Accept Cost | 10,000 |

Candidate tetap tersimpan.

```text
Farm
 ↓
Convert
 ↓
Raid
 ↓
Get Gold
 ↓
10,000 Gold
 ↓
Accept Candidate
```

---

## 72. Pending Candidate Restriction

Recruit 1X / 5X / 10X terkunci hanya jika board penuh (10 kartu) atau roster + pending tidak muat 40.

```text
┌────────────────────────────┐
│ RECRUITMENT                │
│                            │
│ ⚠️ Board penuh (10/10)     │
│    atau roster hampir cap  │
│                            │
│ TAKE ALL / CLEAR ALL       │
│ atau jual Hero dulu.       │
└────────────────────────────┘
```

Board boleh berisi sampai 10 kartu sekaligus. Recruit hanya ditolak kalau slot atau roster tidak cukup.

---

## 73. Candidate Accept Transaction

Ketika player menekan Accept:

```text
Check Candidate Exists
        ↓
Check Candidate Status
        ↓
Check Gold >= Accept Fee
        ↓
Subtract Accept Fee
        ↓
Create Hero
        ↓
Add Hero to Collection
        ↓
Remove Pending Candidate
        ↓
Hero Status = ACTIVE
        ↓
Start Production
```

---

## 74. Candidate Accept Failure

Jika player menekan Accept tetapi Gold masih kurang:

```text
Check Gold
    ↓
Gold < Accept Fee
    ↓
Transaction cancelled
    ↓
No Gold removed
    ↓
Candidate remains saved
```

Tidak ada partial payment.

Contoh:

| Item | Nilai |
| --- | ---: |
| Required | 4,000 |
| Player | 3,900 |
| Result | Accept gagal, Gold tetap 3,900, Candidate tetap tersimpan |

---

## 75. Candidate Data

Minimal Candidate harus memiliki:

| Field | Keterangan |
| --- | --- |
| `CandidateID` | ID unik |
| `HeroType` | Tipe Hero |
| `Tier` | Rarity |
| `Power` | Stat Raid |
| `Production` | Stat Magic Stone /s |
| `AcceptCost` | Biaya Accept |
| `CreatedAt` | Waktu dibuat |
| `Status` | `PENDING` / `ACCEPTED` / `REJECTED` |

---

## 76. Hero Data

Minimal Hero harus memiliki:

| Field | Keterangan |
| --- | --- |
| `HeroID` | ID unik |
| `HeroType` | Tipe Hero |
| `Tier` | Rarity |
| `Power` | Stat Raid |
| `Production` | Stat Magic Stone /s |
| `AcceptCost` | Catalog value locked at Accept or starter grant |
| `Purchased` | `true` if accepted from the board; `false` for starters |
| `Status` | `ACTIVE` / `BAGGED` / `RAIDING` |
| `DisplaySlot` | Nomor pad 1–40 jika `ACTIVE`, selain itu kosong |
| `CreatedAt` | Waktu dibuat |

---

## 77. Raid Data

Minimal Raid harus menyimpan:

| Field | Keterangan |
| --- | --- |
| `RaidID` | ID unik |
| `PlayerID` | Pemilik Raid |
| `MapID` | Map yang dipilih |
| `HeroIDs` | Hero yang dikirim |
| `TeamPower` | Total Power |
| `RecommendedPower` | Rekomendasi map |
| `SuccessChance` | Peluang sukses |
| `StartTime` | Waktu mulai |
| `EndTime` | Waktu selesai |
| `Status` | `ACTIVE` / `SUCCESS` / `FAILED` |

---

## 78. Raid Validation

Sebelum Raid dimulai:

```text
Check Map Exists
        ↓
Check Hero Count <= 5
        ↓
Check Hero Count >= 1
        ↓
Check Semua Hero milik player
        ↓
Check Semua Hero status ACTIVE
        ↓
Calculate Team Power
        ↓
Calculate Success Chance
        ↓
Start Raid
```

Jika salah satu validation gagal, Raid tidak dimulai.

---

## 79. Raid Hero Lock

Ketika Raid dimulai:

```text
Hero Status: ACTIVE → RAIDING
```

Hero tidak dapat digunakan dalam sistem lain sampai Raid selesai.

---

## 80. Raid Completion Resolve

Ketika timer selesai:

```text
Check Success Chance
       ↓
Random Roll
       ↓
Roll <= Success Chance
       │
   ┌───┴────┐
   ▼        ▼
SUCCESS    FAIL
   │        │
   ▼        ▼
Rewards   No Reward
   │        │
   └───┬────┘
       ▼
Return Heroes
       ↓
Status = ACTIVE
       ↓
Production Resume
```

---

## 81. Raid Failure Consequence

Tidak ada permanent punishment.

Failure hanya berarti **No Reward**. Hero tetap aman.

Tujuannya membuat player berani mencoba Raid meskipun Power belum ideal.

---

## 82. Raid Risk

Risk utama: **Opportunity Cost**.

Hero yang dikirim Raid memiliki Production = 0 selama Raid.

Player mempertaruhkan potential Magic Stone Production demi Raid Reward.

---

## 83. Raid Strategy

### Safe Strategy

```text
High Power
 ↓
High Success Chance
 ↓
Low Risk
```

### Greedy Strategy

```text
Low Power
 ↓
Low Success Chance
 ↓
High Risk
 ↓
Potential Reward
```

---

## 84. Display Management

Player dapat melihat:

- Hero yang sedang aktif
- Hero yang sedang Raid
- Production per Hero
- Total Production

Contoh:

```text
TOTAL PRODUCTION

+1,250 💎/s

Active Heroes: 8 / 10
Raid Heroes:   5
```

---

## 85. Total Production

Total Production dihitung hanya dari Hero `ACTIVE`.

```text
Total Production = Sum(Production dari seluruh Hero ACTIVE)
```

Hero `RAIDING` tidak dihitung.

Contoh:

| Hero | Production | Status |
| --- | ---: | --- |
| Hero A | 100/s | ACTIVE |
| Hero B | 150/s | ACTIVE |
| Hero C | 200/s | RAIDING |
| Hero D | 300/s | ACTIVE |
| **Total** | **550/s** | A + B + D |

---

## 86. Total Team Power

```text
Team Power = Sum(Power semua Hero Raid)
```

Contoh:

```text
420 + 380 + 310 + 290 + 250 = 1,650
```

---

## 87. Raid vs Production Decision

Contoh:

| Hero | Power | Production |
| --- | ---: | ---: |
| Hero A | 500 | 20/s |
| Hero B | 400 | 100/s |

Player harus menentukan Hero mana yang dikirim Raid. Tidak selalu Hero dengan Production terbesar.

Ini membuat stat Hero memiliki fungsi berbeda.

---

## 88. Upgrade Priority

Player memiliki dua progression utama:

| Facility | Efek |
| --- | --- |
| 🏢 Recruitment Level | Meningkatkan kualitas peluang Hero |
| ⚙️ Converter Level | Meningkatkan kecepatan menghasilkan Gold |

---

## 89. No Hero Leveling System

Hero tidak memiliki level progression individual.

Tidak ada:

- Hero Level 1
- Hero Level 2
- Hero Level 3

Hero Power dan Production ditentukan ketika Candidate dibuat.

Jika ingin meningkatkan kualitas Hero, player mencari Hero baru melalui Recruitment.

---

## 90. No Fusion

Tidak ada:

- Fusion
- Combine
- Merge
- Evolution

Setiap Hero berdiri sendiri.

---

## 91. Game Economy

### Sumber Gold

```text
💎 Magic Stone → ⚙️ Converter → 🪙 Gold
⚔️ Raid → 🎁 Gold Reward
🦸 Sell Hero → 🪙 25% Accept Fee
```

### Gold Sink

```text
🪙 Gold
 │
 ├── Recruit Fee
 ├── Recruitment Upgrade
 └── Converter Upgrade
```

---

## 92. Main Progression

```text
START
  ↓
Initial Gold
  ↓
Recruit
  ↓
Candidate
  ↓
Accept
  ↓
Hero
  ↓
Production
  ↓
Magic Stone
  ↓
Converter
  ↓
Gold
  ↓
Upgrade
  ↓
Better Recruitment
  ↓
Higher Tier Hero
  ↓
Higher Power
  ↓
Higher Production
  ↓
Higher Raid
  ↓
Better Rewards
  ↓
More Gold
```

---

## 93. Gameplay Identity

Game memiliki empat pilar utama.

### 1. Recruit

Cari kandidat terbaik.

> Apakah kandidat ini layak dibayar?

### 2. Produce

Gunakan Hero untuk menghasilkan Magic Stone.

> Seberapa besar production Hero ini?

### 3. Raid

Gunakan maksimal 5 Hero.

> Apakah Power team gue cukup untuk mengambil risiko?

### 4. Invest

Gunakan Gold untuk memperkuat sistem.

> Upgrade Recruitment atau Converter dulu?

---

## 94. Final Game Loop

```text
              🪙 GOLD
                 │
                 ▼
        🏢 HERO RECRUITMENT
                 │
          PAY RECRUIT FEE
                 │
                 ▼
           👤 CANDIDATE
                 │
          ┌──────┴──────┐
          ▼             ▼
       ❌ REJECT      ✅ ACCEPT
          │             │
          │             ▼
          │       CHECK ACCEPT FEE
          │             │
          │      ┌──────┴──────┐
          │      ▼             ▼
          │   ENOUGH        NOT ENOUGH
          │      │             │
          │      ▼             ▼
          │   PAY FEE      📦 PENDING
          │      │             │
          │      ▼          EARN GOLD
          │   🦸 HERO          │
          │                    ▼
          │               ACCEPT HERO
          │                    │
          └────────────────────┘
                       │
                       ▼
                 🦸 HERO
                       │
                ┌──────┴──────┐
                ▼             ▼
             DISPLAY         RAID
                │             │
                ▼             ▼
          💎 PRODUCTION   ⚔️ 5 HEROES
                │             │
                ▼             ▼
          💎 MAGIC STONE  SUCCESS / FAIL
                │             │
                ▼             ▼
           ⚙️ CONVERTER    🎁 REWARD
                │
                ▼
             🪙 GOLD
                │
         ┌──────┴──────┐
         ▼             ▼
      RECRUIT       UPGRADE
```

---

## 95. Systems Not Included

Sistem berikut secara resmi **tidak digunakan**:

- Training
- Auto Combine
- Manual Combine
- Fusion
- Evolution
- Hero Level
- Hero Loss
- Hero Death
- Multiple Main Currencies
- Direct Hero → Gold Production

---

## 96. Final System Summary

### 🏢 Hero Recruitment

- Player membayar Recruit Fee
- Candidate di-generate
- Candidate memiliki Tier, Power, Production, dan Accept Cost
- Player dapat Accept atau Reject
- Reject membuat Candidate hilang
- Recruit Fee tidak dikembalikan
- Accept membutuhkan pembayaran tambahan

### 📦 Pending Candidate

- Jika Gold tidak cukup untuk Accept, Candidate disimpan
- Candidate tidak hilang
- Stat tidak berubah
- Tidak ada reroll
- Tidak ada expiration
- Maksimal 10 Pending Candidate di Recruitment Board
- Recruit 1X / 5X / 10X mengisi slot kosong
- TAKE ALL menerima semua kartu; CLEAR ALL menolak semua
- Setelah Gold cukup, player dapat Accept

### 🦸 Hero

- Hero langsung aktif setelah Accept
- Hero memiliki Tier, Power, Production
- Hero dapat dipajang di `hero` (maks 40)
- Kelebihan Accept masuk Tas (`BAGGED`)
- Hero `ACTIVE` dan `BAGGED` menghasilkan Magic Stone
- Hero dapat dikirim Raid
- Hero yang dibeli atau starter dapat di-Sell / Release dengan refund maksimal 25% catalog Accept Fee

### 💰 Sell / Release

- Harga beli = Accept Fee yang terkunci saat Accept
- Refund maksimal **25%** Accept Fee, dibulatkan ke bawah
- Recruit Fee tidak dikembalikan
- Hero `RAIDING` tidak bisa dijual
- Seed / starter Hero bisa dijual; refund 25% dari catalog tier yang dikunci saat grant
- Sell menghapus Hero dari koleksi, display, dan production

### 💎 Magic Stone

- Dihasilkan Hero `ACTIVE` (display) dan `BAGGED` (tas)
- Disimpan di Storage
- Tidak langsung menjadi Gold
- Diproses oleh Converter

- Mengubah Magic Stone menjadi Gold
- Ratio **1:1**
- Hanya speed yang dapat di-upgrade

### 🏢 Recruitment Upgrade

- Membuka peluang Tier lebih tinggi
- Tidak menjamin stat tinggi

### ⚔️ Raid

- Maksimal 5 Hero
- Power dijumlahkan
- Dibandingkan dengan Recommended Power
- Bisa masuk walaupun Power di bawah rekomendasi
- Power lebih tinggi = peluang sukses lebih tinggi
- Memiliki durasi
- Hero tidak menghasilkan Magic Stone selama Raid
- Success memberikan reward
- Fail tidak memberikan reward
- Hero tidak pernah hilang karena Raid

### 🎁 Raid Reward

Reward dapat berupa:

- Gold
- Magic Stone
- Recruitment Ticket
- Elite Recruitment Ticket
- Temporary Production Bonus
- Random Bonus Loot

---

## 97. One-Line Game Concept

A Roblox Hero Management game where players pay to recruit randomized Hero candidates, decide whether each candidate is worth the additional Accept Fee, build a collection of Heroes with unique Power and Production stats, generate Magic Stones, convert them into Gold, upgrade their Recruitment and Converter facilities, and risk up to five Heroes in timed Raids for valuable rewards.

---

## 98. Core Philosophy

Gameplay harus terus menciptakan keputusan:

```text
"Recruit lagi?"
        ↓
"Candidate ini bagus?"
        ↓
"Accept Fee-nya mahal."
        ↓
"Gold gue cukup?"
        ↓
"Kalau belum, simpan dulu."
        ↓
"Hero ini lebih bagus buat farming atau Raid?"
        ↓
"Kalau jelek, jual rugi. Cuma 25% Accept Fee yang balik."
        ↓
"Kalau gue kirim Raid, production gue berhenti."
        ↓
"Tapi reward Raid besar."
        ↓
"Setelah dapat Gold, upgrade Recruitment atau Converter?"
        ↓
"Recruitment lebih tinggi berarti peluang Hero langka lebih besar."
        ↓
"Hero lebih bagus."
        ↓
"Raid lebih kuat."
        ↓
"Reward lebih besar."
        ↓
"Repeat."
```

Tujuan akhirnya adalah menciptakan loop:

```text
RECRUIT → JUDGE → SAVE/ACCEPT → COLLECT → PRODUCE → CONVERT → INVEST → RAID → REWARD → RECRUIT AGAIN
```

Sell adalah cabang opsional dari COLLECT: buang Hero jelek, terima rugi 75%+ Accept Fee.

---

## 99. Sell / Release Hero

Sell / Release dipakai untuk merapikan koleksi. Ini **bukan** Combine, Fusion, atau Hero Loss karena Raid.

```text
HERO (ACTIVE)
   ↓
Player pilih SELL
   ↓
Check boleh dijual?
   ├── NO → transaksi batal
   └── YES
        ↓
     Bayar refund 25% Accept Fee
        ↓
     Hapus Hero
        ↓
     Production dan Display update
```

Tujuan: player tidak stuck dengan tumpukan Hero roll jelek, tapi tetap rugi kalau jual.

---

## 100. Sell Refund

Refund dihitung **hanya dari Accept Fee**. Recruit Fee tidak masuk harga beli.

```text
Refund = floor(AcceptCost × 0.25)
```

`0.25` adalah **maksimal**. Tidak ada bonus di atas 25%.

Contoh B2:

| Item | Gold |
| --- | ---: |
| Recruit Fee | 100 (hangus, tidak dihitung) |
| Accept Fee / harga beli | 250 |
| Refund jual | 62 |
| Rugi | 288 |

Contoh B5:

| Item | Gold |
| --- | ---: |
| Recruit Fee | 100 (hangus) |
| Accept Fee | 4,000 |
| Refund jual | 1,000 |

`AcceptCost` dikunci saat Accept. Kalau tabel Accept Fee di-balance ulang nanti, Hero lama tetap memakai biaya yang dulu dibayar.

---

## 101. Sell Restrictions

Hero **tidak bisa** dijual jika:

| Kondisi | Alasan |
| --- | --- |
| `Status == RAIDING` | Hero sedang di Raid |
| Hero tidak milik player | Validasi server |
| Candidate Pending | Candidate memakai Reject, bukan Sell |

Tidak ada jual cicilan. Tidak ada jual sebagian stat. Satu transaksi = satu Hero dihapus.

---

## 102. Sell Transaction

```text
Check Hero Exists
        ↓
Check Hero milik player
        ↓
Check Status != RAIDING
        ↓
Refund = floor(AcceptCost × 0.25)
        ↓
Add Gold
        ↓
Remove Hero from Collection
        ↓
Remove from Display
        ↓
Recalculate Production
```

Jika salah satu check gagal: Gold tidak berubah, Hero tetap ada.

---

## 103. Sell vs Reject

| Aksi | Objek | Recruit Fee | Accept Fee | Hasil |
| --- | --- | --- | --- | --- |
| Reject | Candidate | Hangus | Tidak dibayar | Candidate hilang |
| Sell | Hero | Hangus | Sudah dibayar, 25% kembali | Hero hilang |

Reject sebelum punya Hero. Sell setelah punya Hero. Keduanya bukan Combine.

---

## 104. Display Slots & Bag

Aset panggung di Workspace bernama **hero** (folder `hero`).

Aturan:

- Maksimal **40** Hero tampil di pad `hero` (`ACTIVE`)
- Setiap Hero display punya **slot tetap** (pad 1–40). Jual Hero di pad itu → pad itu **kosong**
- Hero lain **tidak bergeser** mengisi pad kosong
- Hero Tas **tidak** otomatis naik ke pad kosong
- Accept baru boleh mengisi pad kosong pertama. Kalau semua pad terisi, masuk Tas
- `RAIDING` keluar dari pad dan production dijeda; pad yang ditinggal tetap kosong
- Seed / starter Hero mulai di pad 1, 2, dst.

```text
ACCEPT HERO
   ↓
Ada pad kosong?
   ├── YES → Status ACTIVE, kunci ke pad itu
   └── NO  → Status BAGGED → masuk Tas

SELL HERO DI PAD 3
   ↓
Pad 3 kosong
Hero di pad lain tetap di pad-nya
```


