<div align="center">

# YORU NO SHINOBI

**Game endless runner ninja bertema Jepang — malam & siang, pencahayaan 2D dinamis, ultimate sinematik.**

![Godot](https://img.shields.io/badge/Godot-4.4-478CBF?logo=godotengine&logoColor=white)
![Renderer](https://img.shields.io/badge/renderer-GL%20Compatibility-5c6bc0)
![Language](https://img.shields.io/badge/GDScript-100%25-355570)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS-2e7d32)

</div>

Lari tanpa henti melewati 11 stage bergaya Jepang, hindari rintangan, kumpulkan koin, beli karakter baru, lalu
lepaskan **ultimate sinematik** yang unik untuk tiap karakter. Hampir seluruh visual (sprite, tekstur diffuse /
normal / specular, latar parallax, efek partikel, ultimate) **digambar lewat kode** — tidak ada file gambar sama sekali
selain ikon. Efek suara dan musik latar berupa file MP3.

---

## Daftar Isi

1. [Fitur](#fitur)
2. [Mulai Cepat](#mulai-cepat)
3. [Kontrol](#kontrol)
4. [Isi Game](#isi-game)
5. [Struktur Proyek](#struktur-proyek)
6. [Cara Kerja (Arsitektur)](#cara-kerja-arsitektur)
7. [Panduan Modifikasi](#panduan-modifikasi)
   - [Cooldown, harga, dan angka keseimbangan](#1-cooldown-harga-dan-angka-keseimbangan)
   - [Mengubah / menambah karakter](#2-mengubah--menambah-karakter)
   - [Membuat skill Dash / Special baru](#3-membuat-skill-dash--special-baru)
   - [Membuat Ultimate baru](#4-membuat-ultimate-baru)
   - [Membuat stage (tema) baru](#5-membuat-stage-tema-baru)
   - [Mengatur level generator](#6-mengatur-level-generator)
   - [Menambah musuh / rintangan](#7-menambah-musuh--rintangan)
   - [Menambah power-up](#8-menambah-power-up)
   - [Fisika & kecepatan lari](#9-fisika--kecepatan-lari)
   - [Upgrade, save, dan pengaturan](#10-upgrade-save-dan-pengaturan)
   - [Kontrol & input](#11-kontrol--input)
   - [Shader post-process](#12-shader-post-process)
   - [Audio: musik, SFX, dan generator Maou](#13-audio-musik-sfx-dan-generator-maou)
   - [Tips debugging & testing cepat](#14-tips-debugging--testing-cepat)
8. [Export ke Android](#export-ke-android)
9. [Pemecahan Masalah](#pemecahan-masalah)
10. [Kontribusi](#kontribusi)
11. [Kredit, Lisensi, dan Atribusi Audio](#kredit-lisensi-dan-atribusi-audio)

---

## Fitur

- **11 stage** bergilir malam / siang, tiap ±380 m, dipisahkan gerbang torii. Setelah stage terakhir, siklus berulang
  dengan kecepatan yang terus naik.
- **Pencahayaan 2D kompleks**: `CanvasModulate` ambient per stage, `DirectionalLight2D` bulan dengan bayangan,
  `PointLight2D` lentera berkedip dengan bayangan dinamis, tanah ber-normal-map + specular, kunang-kunang berlampu,
  god-ray torii, kabut, bloom (`WorldEnvironment` glow), flash petir.
- **Shader post-process**: vignette, aberasi kromatik, radial blur saat dash, color grading per stage, letterbox &
  sinar radial saat ultimate.
- **Ninja prosedural** (rig tulang digambar kode): lari, lompat, double-jump flip, slide, dash + afterimage, syal verlet,
  gaya lari berbeda per karakter.
- **6 karakter** dengan dash, special, ultimate, dan upgrade unik masing-masing.
- **Ultimate sinematik** (slow-motion, zoom kamera, letterbox) dengan "sutradara visual" tersendiri per karakter.
- **Rintangan**: jurang air, platform melayang, bambu runcing, oni, gagak, hitodama, drum taiko (trampolin), sambaran
  petir bertanda peringatan, serta **gerombolan musuh** di akhir tiap stage.
- **Power-up**: Shield, Magnet, Star (kebal), Raijin Strike (petir berantai), Heart. Combo koin.
- **Ekonomi & progres**: toko karakter, toko upgrade per karakter (9 upgrade), save otomatis.
- **Menu utama dengan mode demo** (AI bermain di latar), pause, game over, pengaturan.
- **Mendukung** keyboard, gamepad, dan layar sentuh (tombol virtual).

---

## Mulai Cepat

**Kebutuhan:** [Godot 4.4](https://godotengine.org/download) (versi 4.3+ kemungkinan besar bisa, tetapi proyek diuji
di 4.4). Tidak perlu .NET / Mono, tidak ada plugin atau dependensi lain.

```bash
git clone <url-repo-anda>
cd <nama-folder-repo>
```

1. Buka Godot → **Import** → pilih `project.godot`.
2. Tunggu proses import aset (file MP3 diimpor otomatis pada pembukaan pertama).
3. Tekan **F5** (Run). Scene utama adalah `res://scenes/boot.tscn`.

Menjalankan dari terminal (tanpa editor):

```bash
godot --path .
```

Renderer yang dipakai adalah **GL Compatibility**, sehingga berjalan di HP kelas menengah maupun PC. Resolusi dasar
**1280 × 576**, mode stretch `canvas_items`, aspect `keep`, orientasi landscape.

---

## Kontrol

| Aksi | Keyboard | Gamepad | Sentuh |
|---|---|---|---|
| Lompat (tekan lagi = double jump) | `Space` / `W` / `↑` | A | tombol **JUMP** |
| Slide (di udara = jatuh cepat) | `S` / `↓` | D-Pad bawah / B | tombol **SLIDE** |
| Lempar shuriken | `J` / `X` / `→` / `D` | X | tombol **SHURIKEN** |
| Dash (skill 1, tiap karakter berbeda) | `K` / `Shift` / `Z` / `←` | Y / RB | tombol **DASH** |
| Special (skill 2) | `L` / `C` / `E` | — | tombol **SHADOW X** (label mengikuti karakter) |
| Ultimate | `U` | — | tombol **ULTI** |
| Pause | `Esc` / `P` | Start | tombol **II** |
| Konfirmasi menu | `Enter` / `Space` | A | — |

Tombol sentuh dapat diatur di **Settings → Touch Buttons**: `AUTO` (muncul hanya di perangkat layar sentuh),
`ALWAYS ON`, atau `OFF`.

---

## Isi Game

### Stage

Urutan dan seluruh tampilan stage didefinisikan di `scripts/core/themes.gd` (urutan lewat array `order`).

| # | Stage | Suasana | Cuaca |
|---|---|---|---|
| 1 | Sakura Moon Garden | malam | kelopak sakura |
| 2 | Sunlit Hanami Hills | **siang** | kelopak sakura |
| 3 | Frozen Shrine | malam, aurora | salju |
| 4 | Golden Rice Terraces | **pagi emas** | serbuk sari |
| 5 | Storm Over the Castle | badai, sambaran petir otomatis | hujan |
| 6 | Silver Snow Peaks | **siang salju** | salju |
| 7 | Crimson Maple Festival | malam, festival | daun maple |
| 8 | Azure Seaside Village | **siang laut** | serbuk sari |
| 9 | Spirit Bamboo Forest | malam, aurora | roh / hitodama |
| 10 | Twilight Lotus Lake | **senja** | roh / hitodama |
| 11 | Ember Volcano Forge | **gunung api** | bara api |

Tahap-tahap ini disusun selang-seling malam / siang agar tidak monoton.

### Karakter

| Karakter | Harga | Gaya lari | Dash | Special | Ultimate |
|---|---:|---|---|---|---|
| **KAGE** — Shadow Ninja | gratis | Silent Run | Kage Dash (kebal + menebas) | Shadow X (teleport-tebas hingga 3 musuh) | Thunder Judgement (petir satu layar) |
| **HAYATE** — Wind Runner | 900 | Wind Sprint (condong, cepat) | Wind Dash (isi ulang double jump) | Gale Slash (gelombang angin menembus) | Storm Rush (tornado raksasa menerjang layar) |
| **HONOO** — Flame Brawler | 1.800 | Flame Stomp (berat, api tiap langkah) | Flare Dash (membakar musuh di jalur) | Fireball (bola api meledak) | Meteor Rain (matahari, hujan meteor, meteor raksasa) |
| **KORI** — Frost Maiden | 2.800 | Ice Skate (meluncur) | Ice Slide (membekukan musuh di depan) | Frost Nova (membekukan sekitar) | Absolute Zero (sayap es, bekukan dunia lalu hancurkan) |
| **KAKUOU** — Atomic Overlord *(S-Class)* | 20.000 | Titan March (tanah bergetar) | Plasma Dash (menguapkan musuh) | Nuke Blast (ledakan besar) | Zero Hour (hitung mundur, bom nuklir, jamur atom) |
| **MAOU** — Eclipse Demon Lord *(SS-Class)* | 50.000 | Sovereign March | Eclipse Step (hapus semua di jalur) | Twilight Judgement (7 pilar cahaya + gelap) | **World End** (mengakhiri run, semua koin diamankan) |

Pasif: **Kakuou** +2 nyawa, perisai awal, aura radiasi radius 70. **Maou** +3 nyawa, perisai awal, aura eclipse radius 96
yang langsung melenyapkan musuh di dekatnya.

Musuh yang **beku** berhenti, tidak melukai, dan pecah saat disentuh ninja.

### Rintangan & power-up

| Rintangan | Cara menghadapi |
|---|---|
| Jurang air, platform, jembatan | lompat / double jump |
| Bambu runcing (spikes) | lompati |
| Oni | diinjak, ditembak shuriken, atau di-dash |
| Gagak | tembak / hindari |
| Hitodama (wisp) | **jangan diinjak** |
| Drum taiko | trampolin — lompat tinggi |
| Sambaran petir | ada tanda peringatan sebelum menyambar |
| Gerombolan | muncul saat bar progres stage ≥ 85 % |

| Power-up | Efek |
|---|---|
| Shield | menahan satu serangan |
| Magnet | menarik koin (durasi bisa di-upgrade) |
| Star | kebal & lebih cepat selama 7 detik |
| Raijin Strike | petir berantai |
| Heart | +1 nyawa |

### Upgrade (dibeli dengan koin, level **per karakter**)

`SPIRIT HEARTS` (+1 nyawa awal) · `MAGNET TALISMAN` · `SHURIKEN POUCH` (+2 maks shuriken) · upgrade **Dash** ·
upgrade **Special** · upgrade **Ultimate** (ketiganya mengurangi cooldown) · upgrade **Unik** karakter ·
`LUCKY COINS` (+15 % nilai koin) · `PAPER WARD` (perisai awal).

---

## Struktur Proyek

```
.
├── project.godot              # konfigurasi: autoload, display, input (shadow_attack, ultimate)
├── icon.png                   # ikon proyek
├── icons/                     # ikon launcher Android (main 192, adaptive fg/bg 432)
├── scenes/
│   ├── boot.tscn              # scene awal: layar loading
│   └── main.tscn              # scene utama: menu, HUD, dunia
├── autoload/
│   ├── game_state.gd          # singleton GameState: save, koin, upgrade, pengaturan, input map
│   └── audio_manager.gd       # singleton Sfx: pool SFX, musik latar, suara karakter, BGM ultimate
├── scripts/
│   ├── boot.gd                # loading (bangun musik + muat aset di thread) → pindah ke main
│   ├── main.gd                # state UI: menu, pause, game over, toko, pengaturan
│   ├── core/
│   │   ├── characters.gd      # ★ DATA semua karakter (harga, warna, skill, cooldown, upgrade unik)
│   │   ├── themes.gd          # ★ DATA semua stage (warna, cahaya, cuaca, tanah)
│   │   ├── assets.gd          # pemuat SFX (MP3, ber-cache) + musik prosedural bawaan
│   │   ├── texgen.gd          # generator tekstur (diffuse / normal / specular / cahaya / bentuk)
│   │   └── safe_draw.gd       # helper menggambar poligon yang aman dari data tidak valid
│   ├── world/
│   │   ├── world.gd           # dunia: kamera, cahaya, spawn, skor, ultimate, state run
│   │   ├── level_gen.gd       # ★ generator level tak berujung (pola rintangan)
│   │   ├── background.gd      # latar parallax (mengatur BGLayer)
│   │   ├── bg_layer.gd        # satu lapis latar (langit, gunung, desa, pohon, ...)
│   │   ├── ground.gd / platform.gd / water.gd / prop.gd
│   │   ├── weather.gd         # partikel cuaca
│   │   └── firefly.gd         # kunang-kunang berlampu
│   ├── entities/
│   │   ├── ninja.gd           # pemain: fisika, rig, animasi, input, dash/special/ultimate
│   │   ├── skills.gd          # ★ logika dash / special / ultimate semua karakter
│   │   ├── hazard.gd          # basis musuh/rintangan
│   │   ├── oni.gd crow.gd wisp.gd barrel.gd spikes.gd strike.gd
│   │   ├── coin.gd powerup.gd shuriken.gd skill_proj.gd ult_aura.gd
│   ├── fx/
│   │   ├── fx.gd / fx_shape.gd        # ring, burst, material additive/unshaded
│   │   ├── ult_dir.gd                 # kelas dasar "sutradara visual" ultimate
│   │   ├── ult_draw.gd                # helper gambar bersama (UD)
│   │   ├── ultimate_fx.gd             # ultimate Kage (Thunder Judgement)
│   │   ├── ult_hayate.gd ult_honoo.gd ult_kori.gd ult_kakuou.gd ult_maou.gd
│   │   ├── world_end_fx.gd we_mesh.gd maou_pillar.gd    # efek khusus Maou
│   └── ui/
│       ├── hud.gd  touch_controls.gd  ui_theme.gd
│       ├── char_carousel.gd  char_preview.gd            # kartu karakter + pratinjau
├── shaders/post.gdshader      # post-process layar
├── assets/audio/
│   ├── lobby.mp3 gameplay.mp3 # musik menu & gameplay
│   └── sfx/                   # seluruh efek suara (*.mp3)
└── tools/maou_sfx/            # generator SFX Maou (Python) — tidak ikut ke game (.gdignore)
```

> ★ = berkas yang paling sering Anda sentuh saat memodifikasi game.

---

## Cara Kerja (Arsitektur)

**Alur program**

```
boot.tscn (boot.gd)
   │  bangun musik prosedural + muat SFX Maou di thread terpisah, menyiapkan aset tiap stage
   ▼
main.tscn (main.gd)
   │  membangun UI, SubViewport berisi World, dan material post-process
   ▼
World (world.gd)  ←→  Ninja (ninja.gd)  ←→  Skills (skills.gd) / Fx / UltDir
   │
   └── LevelGen (level_gen.gd) menciptakan tanah, rintangan, koin, power-up di depan pemain
```

**Prinsip desain**

- **Data-driven.** Karakter ada di `Characters.DATA`, stage di `Themes._build()`. Hampir semua penyetelan cukup
  dengan mengubah dictionary — tanpa menyentuh logika.
- **Dua autoload** (`project.godot`): `GameState` (data permainan, save, input map) dan `Sfx` (audio).
- **Tanpa aset gambar.** Teks, bentuk, dan tekstur dibuat oleh `TexGen` serta `_draw()` tiap node.
- **Dunia bergerak ke kiri**: kamera mengikuti pemain; jarak dihitung dalam piksel
  (`Themes.PX_PER_M = 30` piksel per meter, `Themes.STAGE_M = 380` meter per stage).
- **Ultimate** dikoreografikan oleh `Skills` berdasarkan waktu `Ninja.ultimate_elapsed`; visualnya digambar oleh node
  "sutradara" (`UltDir`) yang membaca waktu yang sama sehingga selalu sinkron.
- **Slow-motion ultimate** memakai `Engine.time_scale`; efek visual memakai waktu nyata (`rd`) agar tidak ikut melambat.
- **Save** disimpan di `user://yoru_save.json` (JSON).

---

## Panduan Modifikasi

Setiap bagian di bawah menyebut berkas, nama kunci/fungsi, dan langkah yang perlu Anda lakukan.

### 1. Cooldown, harga, dan angka keseimbangan

Semua ada di **`scripts/core/characters.gd`**, pada tabel `DATA` bagian `"skills"` tiap karakter.

| Slot | Tombol | Kunci |
|---|---|---|
| `"dash"` | `K` / DASH | skill 1 |
| `"special"` | `L` / `C` / `E` | skill 2 |
| `"ultimate"` | `U` / ULTI | ultimate |

Tiap skill punya tiga angka:

| Kunci | Arti |
|---|---|
| `"cd"` | cooldown dasar (detik) pada level upgrade 0 |
| `"step"` | detik cooldown yang berkurang per 1 level upgrade |
| `"min"` | batas cooldown terendah |

Rumus: `cooldown = max(min, cd - step × level_upgrade)`.

Konstanta global di bagian atas file yang sama:

| Konstanta | Fungsi |
|---|---|
| `SHURIKEN_RECHARGE` | detik untuk mengisi 1 shuriken (default `3.0`) |
| `ULTI_START_FRACTION` | pecahan cooldown ultimate saat run dimulai (`0.0` = langsung siap, `1.0` = tunggu penuh; default `0.35`). Karakter bisa menimpanya lewat `"ult_start"` |

Angka lain per karakter:

| Kunci | Arti |
|---|---|
| `"price"` | harga karakter (koin) |
| `"speed"`, `"jump"`, `"gravity"` | pengali kecepatan lari, kekuatan lompat, gravitasi |
| `"bonus_hearts"` | nyawa tambahan |
| `"start_shield"` | mulai run dengan perisai |
| `"passive"`, `"passive_radius"` | pasif aura (`"radiation"` / `"eclipse"`) dan jangkauannya |
| `"cost_mult"` | pengali harga upgrade karakter itu |
| `"unique"` | upgrade unik: `name`, `desc`, `max` (level maksimum), `base` (harga dasar) |
| `"len"`, `"zoom"` (di `ultimate`) | durasi sinematik ultimate (detik) dan zoom kamera |

Harga upgrade: `base × (level + 1) × cost_mult`. Upgrade umum (`hearts`, `magnet`, `pouch`, `fortune`, `ward`) ada di
konstanta `UPGRADES` pada `autoload/game_state.gd`.

### 2. Mengubah / menambah karakter

**Mengubah tampilan:** edit `"pal"` (palet) di `Characters.DATA`:

| Kunci palet | Dipakai untuk |
|---|---|
| `navy`, `navy_l` | pakaian utama & sisi terang |
| `wrap` | pembalut / syal |
| `red` | aksen |
| `skin` | kulit |
| `eye` | warna mata (nilai > 1 = bercahaya / HDR) |
| `glow` | cahaya & aura |
| `trail` | jejak afterimage dash |
| `dust` | debu langkah |

**Menambah karakter baru** — langkah lengkap:

1. **Daftarkan data.** Di `characters.gd` tambahkan satu entri di `DATA` (salin entri karakter yang mirip) dan tambahkan
   id-nya ke `ID_ORDER` (urutan di toko). Isi minimal: `name`, `title`, `price`, `desc`, `run_style`, `run_name`,
   `speed`, `jump`, `gravity`, `pal`, `skills` (`dash`, `special`, `ultimate`), dan `unique`.
2. **Gaya lari.** `"run_style"` memilih animasi di `Ninja._animate()` (`classic`, `sprint`, `stomp`, `skate`, `titan`).
   Pakai salah satunya atau tambahkan cabang `match run_style` baru di `scripts/entities/ninja.gd`.
3. **Skill.** Tiap skill punya `"kind"` yang dikenali `scripts/entities/skills.gd`. Pakai `kind` yang sudah ada
   (mis. `"fire"`, `"ice"`, `"gale"`, `"plasma"`) atau buat baru — lihat bagian [3](#3-membuat-skill-dash--special-baru)
   dan [4](#4-membuat-ultimate-baru).
4. **Suara karakter.** Nama berkas yang dicari game: `step_<id>`, `jump_<id>`, `djump_<id>`, `slide_<id>`, `land_<id>`,
   `throw_<id>`, `hurt_<id>` di `assets/audio/sfx/`. Jika belum punya, salin berkas milik karakter lain dengan nama
   baru. (Maou memakai suara Kakuou: `Assets.sfx()` mengalihkan akhiran `_maou` menjadi `_kakuou`; tambahkan aturan
   serupa untuk karakter Anda bila ingin berbagi suara.)
5. **Ekstra visual.** `"extras"` (`"overlord"`, `"demonlord"`) menambah dekorasi pada rig di `Ninja._build_extras()`.
6. **Pratinjau.** Kartu karakter digambar oleh `scripts/ui/char_preview.gd` — tambahkan bentuk khusus di sana bila perlu.
7. **Save lama otomatis kompatibel**: `GameState.load_game()` hanya memuat id yang ada di `Characters.DATA`.

### 3. Membuat skill Dash / Special baru

Di `scripts/entities/skills.gd`:

- **Dash** — fungsi `dash_begin(p, kind)` (efek awal + SFX) dan `dash_tick(p, kind)` (dipanggil tiap tick afterimage:
  jejak partikel dan efek area). Tambahkan cabang `match kind` baru, mis. `"poison"`. Atur di data karakter:
  `"time"` (durasi dash, detik) dan `"speed"` (pengali kecepatan).
- **Special** — fungsi `special(p, kind)` memutar SFX lalu memanggil fungsi khusus (`_gale`, `_fireball`, `_frost_nova`,
  `_nuke_blast`, `_judgement`). Tambahkan `kind` baru di kedua `match` pada fungsi itu (satu untuk nama SFX, satu untuk
  logika).
- **SFX**: `skill_dash_<nama>` dan `skill_special_<nama>` (lihat [tabel audio](#13-audio-musik-sfx-dan-generator-maou)).
- **Label tombol sentuh** diambil dari `"touch"` di data skill; teks info di menu dari `"info"`.

Helper yang berguna: `Skills.enemies(world)` (daftar musuh), `Hazard.take_damage(n, sumber)` / `Hazard.kill(sumber)` /
`Hazard.freeze(detik)`, `Fx.ring(...)` dan `Fx.burst(...)` untuk efek, `world.shake(amp, t)` untuk guncangan layar.
Nilai `sumber` ("fire", "ice", "plasma", "eclipse", ...) menentukan suara musuh terluka/mati di `Hazard.take_damage()`.

### 4. Membuat Ultimate baru

Ultimate Kage (`kind: "thunder"`) memakai jalur khusus; ultimate lain memakai mesin sinematik umum. Untuk menambah
ultimate dengan `kind` baru (misal `"venom"`):

1. **Data** — di `characters.gd` isi `skills.ultimate` dengan `"kind": "venom"`, `"cd"`, `"step"`, `"min"`, `"len"`
   (durasi), `"zoom"`.
2. **Koreografi** — di `skills.gd`:
   - `cine_begin()`: tambahkan warna grading (`w.fx_tint`, `w.fx_raycol`) dan daftarkan skrip sutradara di dictionary
     `dir_paths` (`"venom": "res://scripts/fx/ult_venom.gd"`).
   - `cine_update()`: arahkan `"venom"` ke fungsi koreografi baru `_venom(p, delta, rd, t)` (waktu `t` = detik nyata
     sejak ultimate mulai). Salin pola `_storm` / `_inferno` / `_blizzard`.
   - `cine_end()`: bersihkan state bila perlu.
   - Gunakan `_cue(p, "kunci", t, waktu_visual, "nama_sfx")` untuk memutar suara tepat di momen visual — `_cue`
     otomatis mengurangi latensi output audio perangkat.
3. **Visual** — buat `scripts/fx/ult_venom.gd` yang `extends UltDir` dan isi fungsi yang diperlukan:

   | Fungsi | Tugas |
   |---|---|
   | `_pal()` | tiga warna tema (`[utama, kedua, aksen]`) |
   | `_init_fx()` | inisialisasi sekali |
   | `_tick(t, bc)` | dipanggil tiap frame sebelum menggambar (pancarkan partikel dengan `emit(...)`) |
   | `_light_energy(t)` | energi `PointLight2D` mengikuti ninja |
   | `_shade(ci, t, bc, fade)` | lapisan **gelap** (z=3) untuk meredupkan dunia |
   | `_back(ci, t, bc, fade)` | lapisan **cahaya additive** di belakang ninja (z=4) |
   | `_front(ci, t, bc, fade)` | lapisan **cahaya additive** di depan ninja (z=22) |

   `t` = waktu ultimate, `bc` = posisi tubuh ninja, `fade` = 1→0 di akhir. Helper gambar ada di `ult_draw.gd` (`UD`:
   glow, flame, crystal, taper, seg7, dll.) dan `view()` memberi persegi dunia yang tampak di layar.
4. **Suara pembuka** — di `Ninja.start_ultimate()` tambahkan cabang pada `match ult_kind` untuk kunci riser
   `ult_charge_<kind>`; di `World._ult_line_cols()` tambahkan warna garis kecepatan awal.
5. **Suara akhir** — fase *impact* dan *finish* (`ult_impact_<elemen>`, `ult_finish_<elemen>`) dipicu dari koreografi
   dan `Ninja._finish_ultimate()`; konstanta `FINISH_CUE_DELAY` (`ninja.gd`) mengatur jeda cue *finish* setelah sinematik.

### 5. Membuat stage (tema) baru

Stage adalah dictionary di `Themes._build()` (`scripts/core/themes.gd`). Tambahkan `out.append({...})` baru; jumlah
stage terbaca otomatis (`Themes.count()`) dan setelah stage terakhir permainan mengulang dari awal.

**Urutan tampil** ditentukan oleh array `order` di akhir `_build()` (`[0, 5, 1, 6, 2, 7, 3, 8, 4, 9, 10]`, berisi indeks
urutan `out.append`). Tema baru **harus ditambahkan ke array `order`** (mis. `..., 10, 11`) — kalau tidak, tema itu tidak
akan pernah muncul di game.

| Kunci | Arti |
|---|---|
| `"name"` | nama yang tampil di banner |
| `"sky"` | 3 warna gradasi langit (atas → bawah) |
| `"ambient"` | warna `CanvasModulate` (penentu terang-gelapnya seluruh dunia) |
| `"moon"` | `{pos, r, col, glow}` — bulan (atau matahari untuk stage siang) |
| `"stars"` | kepadatan bintang (`0` = tanpa bintang) |
| `"cloud_a"`, `"cloud_b"`, `"cloud_n"` | warna & jumlah awan |
| `"fuji"` | 4 warna gunung Fuji di latar |
| `"mtn_far"`, `"mtn_mid"` | warna lapisan gunung |
| `"village"`, `"window"` | siluet desa & warna jendela |
| `"tree"` | `{kind, a, b, c, trunk}` — `kind`: `sakura`, `maple`, `pine`, `bamboo` |
| `"ground"` | `{style, a, b, lip}` — `style`: `wood`, `stone`, `slate`, `grass`, `bamboo`, `magma` |
| `"weather"` | `petals`, `snow`, `rain`, `leaves`, `spirits`, `pollen`, `embers` |
| `"firefly"` | `{count, col}` kunang-kunang |
| `"lantern"` | warna lentera |
| `"moon_light"`, `"moon_energy"` | warna & kekuatan cahaya arah (bulan/matahari) |
| `"fog"` | warna kabut + alfa |
| `"lightning"` | `true` = sambaran petir langit otomatis |
| `"aurora"`, `"castle"`, `"festival"` | dekorasi latar (`true`/`false`) |
| `"grade"` | warna color grading stage |
| `"water"` | 2 warna air jurang |

Kunci **opsional** (ada default aman bila tidak diisi), umumnya untuk stage siang:
`"day"` (latar berwarna, bukan siluet), `"sun"` (cakram matahari), `"lamp"` (pengali cahaya lentera),
`"glow_thr"` / `"glow_int"` (ambang & intensitas bloom), `"vig"` (pengali vignette), `"wall"` / `"roof"` (warna
rumah siang hari), `"pollen"` (warna partikel serbuk sari).

Panjang stage: `Themes.STAGE_M` (meter) dan `Themes.PX_PER_M`. Menambah jenis cuaca baru → tambahkan cabang di
`Weather.set_kind()` (`scripts/world/weather.gd`). Gaya tanah baru → tambahkan di generator tekstur
`TexGen` (`scripts/core/texgen.gd`, cari `style`).

### 6. Mengatur level generator

`scripts/world/level_gen.gd` menyusun dunia "sepotong demi sepotong" sedikit di depan pemain (`AHEAD`).

- **Pola** adalah fungsi `_p_<nama>(d, st)` — `flat`, `gap`, `bridge`, `platforms`, `spikes`, `oni`, `crow`, `wisp`,
  `barrel`, `strike`, `mixed`, `horde`. Parameter `d` = tingkat kesulitan, `st` = nomor stage.
- **Bobot kemunculan** ada pada array `opts` di `_next()` (`["oni", 2.8 + d * 3.0]` = bobot dasar + naik sesuai
  kesulitan). Pola yang sama tidak muncul dua kali berturut-turut.
- **Pola baru:** tulis `func _p_namaanda(d: float, st: int)` — panggil `_ground(len, st)`, spawn lewat
  `w.spawn_hazard(...)`, `_coin_line(...)`, `_coin_arc(...)`, lalu `cursor += len` — lalu tambahkan
  `["namaanda", bobot]` ke `opts`.
- `difficulty()` naik hingga stage ke-3 (`cursor / (STAGE_PX × 3)`), ditambah `st × 0.04` per stage.
- **Gerombolan (horde)**: `HORDE_START` (fraksi progres stage tempat mulai, default `0.85`), `HORDE_MIN` / `HORDE_MAX`
  (panjang tanah gerombolan). `CLOSE_RUN` = jarak penutup stage (tanah + gerbang). Gerombolan tidak aktif di mode demo.
- Stage dengan `st % 5 == 2` menambahkan pola sambaran petir (`strike`).
- Pola pertama tiap stage selalu tanah datar (jeda bernapas) dan dua pola awal run hanya `flat`/`gap`.

### 7. Menambah musuh / rintangan

1. Buat `scripts/entities/musuh_baru.gd` yang `extends Hazard` (lihat `oni.gd` sebagai contoh lengkap):
   - `_build()` — set `hp`, `top_offset`, `score_value`, bentuk tabrakan (`_rect_shape(size, pos)`), light/occluder.
   - `_update(delta)` — gerak & logika per frame.
   - `_draw()` — gambar dengan `draw_rect` / `SafeDraw.poly`.
   - Properti berguna: `stompable` (bisa diinjak), `bouncy` (trampolin), `shurikenable` (bisa ditembak),
     `contact_enabled`, `frozen_t` (beku).
2. Daftarkan di `World.spawn_hazard()` (`match k:` → `"musuhbaru": h = MusuhBaru.new()`; beri `class_name`).
3. Munculkan dari pola di `level_gen.gd` (`w.spawn_hazard("musuhbaru", Vector2(x, GY), st)`).

### 8. Menambah power-up

1. `scripts/entities/powerup.gd`: tambahkan warna di `COLORS` dan gambar ikon di cabang `match kind` pada `_draw()`.
2. `World.collect_powerup()` (`world.gd`): tambahkan cabang efek dan label popup.
3. `LevelGen._powerup()`: tambahkan nama ke daftar `kinds` (duplikat = lebih sering muncul).

### 9. Fisika & kecepatan lari

| Parameter | Lokasi | Default |
|---|---|---|
| `GRAVITY`, `JUMP_V`, `DJUMP_V` | `ninja.gd` | `1750`, `-540`, `-470` |
| `COYOTE`, `BUFFER` | `ninja.gd` | `0.09`, `0.12` detik (toleransi lompat) |
| `SLIDE_TIME`, `DASH_TIME` | `ninja.gd` | `0.55`, `0.24` |
| Kecepatan lari | `world.gd` `_physics_process` | `min(228 + 14 × stage_progress, 345)` |
| `STAGE_GRACE`, `STAGE_GRACE_AFTER` | `world.gd` | detik kebal saat melewati gerbang |
| Skor | `World.compute_score()` | `meter × 2 + koin × 5 + bonus` |
| `ULTIMATE_*` | `world.gd` | zoom & margin kamera saat ultimate |

### 10. Upgrade, save, dan pengaturan

`autoload/game_state.gd`:

- `UPGRADES` — definisi upgrade umum (`name`, `desc`, `max`, `base`) dan `UPGRADE_ORDER` untuk urutan tampil.
- Fungsi turunan: `max_hearts()`, `max_ammo()`, `magnet_time()`, `dash_cooldown()`, `special_cooldown()`,
  `ulti_cooldown()`, `coin_mult()`. Ubah rumusnya di sini untuk mengubah efek upgrade.
- Save: `user://yoru_save.json` berisi koin, rekor, daftar karakter yang dimiliki, level upgrade per karakter, karakter
  terpilih, dan pengaturan. Menambah kunci pengaturan baru: tambahkan di `settings`, lalu tambahkan kontrolnya di
  `Main._build_settings()`.
- Lokasi `user://` — Windows: `%APPDATA%\Godot\app_userdata\Yoru no Shinobi (4.4)\`,
  Linux: `~/.local/share/godot/app_userdata/Yoru no Shinobi (4.4)/`. Hapus berkas save untuk mereset progres.

### 11. Kontrol & input

- Aksi `jump`, `slide`, `throw`, `dash`, `pause_game`, `confirm` dibuat lewat kode di `GameState._setup_inputs()`
  (tambahkan tombol keyboard / gamepad di sana).
- Aksi `shadow_attack` (special) dan `ultimate` didefinisikan di `project.godot` (bagian `[input]`) atau lewat
  *Project → Project Settings → Input Map*.
- Tombol sentuh: `scripts/ui/touch_controls.gd` (`_add(aksi, posisi, radius, label, warna, slot)`).

### 12. Shader post-process

`shaders/post.gdshader` dijalankan pada seluruh layar. Uniform yang tersedia: `vignette`, `flash` / `flash_color`,
`fade` / `fade_color`, `aberration`, `damage`, `dash`, `grain`, `sat`, `grade`, `scan` (garis pindai halus bernuansa
pixel-art), `cine` (letterbox + grading ultimate), `rays` (sinar radial), `cine_tint`, `rays_col`. Nilainya
dikendalikan dari `world.gd` (`fx_*`) dan `main.gd`.

### 13. Audio: musik, SFX, dan generator Maou

**Musik latar.** Letakkan `assets/audio/lobby.(ogg|mp3|wav)` (menu) dan `assets/audio/gameplay.(ogg|mp3|wav)`
(gameplay). Prioritas format: **OGG → MP3 → WAV**. Nama berkas harus huruf kecil dan persis. Jika berkas tidak ada atau
gagal dimuat, game memakai **musik prosedural bawaan** (skala Hirajoshi, petikan koto, pad shakuhachi, taiko — dibangun
oleh `Assets.build_music()`). Pastikan volume *Music* tidak nol di Settings.

**Efek suara.** Semua SFX dimuat dari `res://assets/audio/sfx/<nama>.mp3` oleh `Assets.sfx(nama)` (di-cache). Cara
memutar dari kode:

```gdscript
Sfx.play("nama_sfx", pitch, volume_db)          # SFX biasa (pool round-robin)
Sfx.play_voice("ult_maou_voice")                # ucapan karakter (pemutar sendiri, tidak terpotong)
Sfx.play_ult_bgm("ult_maou_bgm", -6.0)          # backsound ultimate; musik latar diredam otomatis
```

**Untuk mengganti suara cukup timpa berkas MP3 dengan nama yang sama** — tidak perlu mengubah kode.

| Kelompok | Pola nama berkas |
|---|---|
| Gerak karakter | `step_`, `jump_`, `djump_`, `slide_`, `land_`, `throw_`, `hurt_` + `kage` / `hayate` / `honoo` / `kori` / `kakuou` (Maou memakai versi `kakuou`) |
| Dash | `skill_dash_gale`, `_fire`, `_ice`, `_plasma`, `_eclipse`, `shadow_dash` |
| Special | `skill_special_gale`, `_fireball`, `_frost_nova`, `_nuke_blast`, `_judgement` |
| Dampak skill | `skill_impact`, `skill_impact_gale`, `_fireball`, `_frost`, `_nuke`, `_judgement`, `shadow_impact` |
| Ultimate (per elemen `thunder`, `storm`, `meteor`, `blizzard`, `nuke`) | `ult_charge_<e>` (riser), `ult_release_<e>`, `ult_impact_<e>` (fase 1), `ult_finish_<e>` (fase 2), `ult_after_<e>` |
| Ultimate khusus | `ult_thunder_orb`, `ult_thunder_throw`, `ult_thunder_crack`, `ult_meteor_barrage`, `ult_freeze_wave`, `ult_tornado`, `ult_reactor`, … |
| Maou | `ult_charge_worldend`, `ult_maou_{eye,pillar,sword,quake,impact,crack,shatter,suck,end,voice}`, `ult_maou_bgm`, `ult_maou_bgm2` |
| Musuh | `enemy_hurt_{shuriken,fire,ice,plasma,skill}`, `enemy_death_{shuriken,fire,ice,plasma,skill}` |
| Lain-lain | `coin`, `heart`, `powerup`, `click`, `warn`, `stage`, `kill`, `hit`, `gameover`, `skill_ready`, `skill_recharge`, `thunder`, `ski_loop` (loop; Kori) |

**Sinkronisasi ultimate.** Cue suara ultimate dipicu dengan `Skills._cue(...)` pada waktu visual dikurangi latensi output
perangkat (`AudioServer.get_output_latency()`, maks. 0,15 dtk). Riser `ult_charge_*` dirender agar puncak kenaikannya jatuh
tepat pada momen visual pertama (storm 1,7 dtk, meteor 1,7, blizzard 1,8, nuke 1,5). Bila Anda mengganti riser dengan
durasi berbeda, sesuaikan waktu cue di awal fungsi `_storm` / `_inferno` / `_blizzard` / `_nuke_ult` (`skills.gd`).

**Backsound WORLD END (Maou).** Dua sesi: `ult_maou_bgm.mp3` (~10,3 dtk) diputar saat ultimate diklik,
`ult_maou_bgm2.mp3` saat pedang menyentuh tanah (`Skills.WE_IMPACT`). Konstanta `WE_*` di `skills.gd`
(`WE_EYE0`, `WE_EYE1`, `WE_GLOW`, `WE_PILLAR`, `WE_SWORD`, `WE_IMPACT`, `WE_SHATTER`, `WE_TEXT`) mengatur jadwal tiap
adegan dan harus tetap selaras dengan audio.

**Merender ulang SFX Maou** — folder `tools/maou_sfx/` (diabaikan Godot lewat `.gdignore`):

```bash
# kebutuhan: python3, numpy, scipy, ffmpeg (dengan rubberband), espeak-ng
pip install numpy scipy
cd tools/maou_sfx
python3 build_maou_sfx.py      # render ulang semua SFX Maou + suara "The world will end" → assets/audio/sfx/*.mp3
python3 bgm_worldend.py        # render ulang backsound WORLD END (ult_maou_bgm.mp3, 16,6 dtk stereo)
```

| Berkas | Isi |
|---|---|
| `sfx_maou.py` | definisi tiap efek (kamus `SOUNDS`) — ubah desain suara di sini |
| `make_voice.py`, `voice.py` | pembuat suara bicara: TTS espeak-ng diolah menjadi suara iblis berlapis (kalimat, kecepatan, campuran lapisan) |
| `bgm_worldend.py` | komposisi backsound, timeline sinkron dengan `Skills.WE_*` |
| `dsp.py` | pustaka DSP kecil (filter, reverb, envelope, penulis WAV) |

Berkas baru `.mp3` akan di-import otomatis oleh Godot saat proyek dibuka.

### 14. Tips debugging & testing cepat

- **Beli karakter tanpa grinding:** turunkan `"price"` di `Characters.DATA`, atau ubah `coins` pada berkas save.
- **Ultimate langsung siap:** setel `ULTI_START_FRACTION := 0.0` dan/atau `"ult_start": 0.0` di karakter.
- **Uji stage tertentu:** ubah urutan `out.append` di `themes.gd`, atau perpendek `STAGE_M`.
- **Uji skill:** turunkan `"cd"` dan `"min"` ke `0.1`.
- Peringatan `SFX tidak ditemukan: res://assets/audio/sfx/...` di panel *Output* berarti nama kunci SFX salah ketik atau
  berkasnya belum ada.
- Mode demo (AI di menu utama) memakai `World._demo_ai()` — berguna untuk melihat perubahan level tanpa bermain.

---

## Export ke Android

1. *Editor → Manage Export Templates* — pasang template untuk Godot 4.4.
2. Pasang **JDK** dan **Android SDK** lalu atur path-nya di *Editor Settings → Export → Android*.
3. *Project → Export → Add… → Android*. Orientasi sudah landscape; renderer GL Compatibility sudah dipilih.
4. Di *Launcher Icons* isi: **Main Icon** `icons/icon_main_192.png`, **Adaptive Foreground** `icons/icon_adaptive_fg_432.png`,
   **Adaptive Background** `icons/icon_adaptive_bg_432.png`.

> **Catatan splash Android 12+:** sistem hanya menggambar layer *foreground* (dipotong lingkaran) di atas warna latar
> sistem. Karena itu `icon_adaptive_fg_432.png` berisi logo (gambar ilustrasi ninja) di atas latar **opaque**; foreground transparan akan membuat
> logo tampak pudar. Pastikan Adaptive Foreground 432×432 menunjuk ke berkas ini, lalu export ulang APK.

File `.nomedia` di root mencegah galeri Android memindai isi folder proyek bila disalin ke penyimpanan perangkat.

Desktop (Windows / Linux / macOS): tambahkan preset export sesuai platform; tidak ada langkah khusus.

---

## Pemecahan Masalah

| Gejala | Penyebab & solusi |
|---|---|
| Tidak ada suara / `SFX tidak ditemukan` | berkas MP3 belum di-import — buka proyek di editor sekali (atau *Project → Reload Current Project*). Cek juga volume *Music* / *Sound FX* di Settings |
| Musik latar terdengar "sintetis" | `lobby.*` / `gameplay.*` tidak ditemukan di `assets/audio/` sehingga musik prosedural bawaan dipakai |
| Tombol sentuh tidak muncul di PC | Settings → Touch Buttons → `ALWAYS ON` |
| Game berat di HP lama | matikan *Dynamic Shadows* dan *Bloom Glow* di Settings |
| Progres hilang / ingin reset | hapus `yoru_save.json` di folder `user://` |
| Error `Invalid polygon data, triangulation failed` | poligon dengan urutan titik menyilang — periksa array titik pada bentuk yang baru ditambahkan (pakai `SafeDraw.poly`) |
| Karakter hilang di lobby setelah pause saat ultimate berjalan | sudah ditangani oleh `Ninja.cancel_ultimate()` dan reset di `World.start()`; bila menambah ultimate baru pastikan state-nya ikut direset di sana |

---

## Kontribusi

Kontribusi sangat disambut — bug report, ide karakter / stage / ultimate baru, perbaikan performa, maupun terjemahan.

1. *Fork* repo, buat branch: `git checkout -b fitur/nama-fitur`.
2. Ikuti gaya kode yang ada: GDScript bertipe (`var x: float`, `-> void`), indentasi **tab**, nama berkas `snake_case.gd`,
   `class_name` `PascalCase`.
3. Pertahankan prinsip **data-driven** — letakkan angka & warna di tabel data (`Characters`, `Themes`), bukan di dalam
   logika.
4. Uji di editor (F5) minimal pada satu stage siang dan satu stage malam, lalu pastikan panel *Output* bersih dari error.
5. Buka *Pull Request* dengan deskripsi singkat dan (bila perlu) tangkapan layar / video.

Berkas `*.import` dan `*.uid` dihasilkan Godot dan ikut di-commit agar referensi aset stabil.

---

## Kredit, Lisensi, dan Atribusi Audio

**Kode & aset visual.** Seluruh kode GDScript, shader, dan visual prosedural dibuat khusus untuk proyek ini.
*Tentukan lisensi kode proyek Anda (misalnya MIT) dan tambahkan berkas `LICENSE` sebelum merilis publik.*

**Audio.**

- Efek suara (kecuali yang disebut di bawah) dibuat secara lokal lewat sintesis lapisan: noise, osilator, sapuan frekuensi,
  envelope, dan ekor reverb — bukan rekaman peristiwa nyata (ledakan, nuklir, dsb.). SFX Maou dihasilkan oleh skrip di
  `tools/maou_sfx/`; suara bicara berasal dari TTS **espeak-ng** yang diolah menjadi suara iblis.
- Rekaman **petir** (`thunder`, `ult_impact_thunder`, serta turunannya `ult_finish_thunder`, `ult_release_thunder`,
  `ult_charge_thunder`, dan `sfx/reference/lightning_storm_reference.mp3`) berasal dari berkas
  `patricksilvey-weather-lightning-2-464187.mp3` yang disediakan pemilik proyek, lalu diolah (penguatan low-end, ekor
  gema).
- `lobby.mp3` dan `gameplay.mp3` adalah musik latar eksternal, sumbernya dari Youtube:
- lobby: https://youtu.be/4C-RWFmTAbc?si=JLg82VSj-OCxxIHF
- gameplay: https://youtu.be/Ix6aZ6q8aBc?si=Mhu0s7bDNzXXEKXd
  
- Referensi gaya suara (tidak disertakan sebagai berkas; hanya inspirasi, periksa lisensi masing-masing sebelum dipakai):
  Pixabay *Lightning Spell*, *Whoosh Epic Explosion*, *Fireball Whoosh 1*, *Nuclear Explosion*,
  *Elemental Spell Impact (Wind)*, *Frost Spell Impact*, *Ice Cracking Field Recording*, *Loud Thunder*,
  *Deep Impact Sound Effect*, *Epic Cinematic Explosion*, *Ice Crash*, *Wind Gust*, *Breaking Glaciers*.
  Ringkasan lisensi: <https://pixabay.com/service/license-summary/>.

Dibuat dengan [Godot Engine](https://godotengine.org) 4.4. Oleh Zack
