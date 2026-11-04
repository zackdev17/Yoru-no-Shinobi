# Daftar SFX WORLD END (Maou)

Semua suara adalah **file MP3 terpisah** di `assets/audio/sfx/`. Jadwal pemutaran ada di `scripts/entities/maou_cues.gd`
(efek berulang/berpola) dan `Skills._worldend` di `scripts/entities/skills.gd` (efek tunggal). Untuk mengganti suara, timpa file dengan nama yang sama.

## Efek tunggal (dipicu langsung oleh Skills._worldend)

| File | Dipicu | Fungsi |
|---|---|---|
| ult_maou_voice | 2,4 dtk | suara "The world will end" |
| ult_charge_worldend | 4,55 dtk | riser pengisian menuju Ignite |
| ult_maou_ignite | 6,65 dtk | aura api emas menyala |
| ult_maou_shock | 18,7 dtk | gelombang kejut |
| ult_maou_eye | 21,0 dtk | mata terbuka |
| ult_maou_prism | 27,4 dtk | 16 tebasan warna-warni |
| ult_maou_halo | 31,2 dtk | cincin pita emas |
| ult_maou_pillar | 33,0 dtk | pilar cahaya di karakter |
| ult_maou_suck | 40,7 dtk | tarikan sebelum layar putih |
| ult_maou_citypillar | 47,2 dtk | pilar cahaya emas di kota |
| ult_maou_thunder | 50,6 dtk | petir biru |
| ult_maou_summon | 48,2 dtk | pedang muncul (puncak di 51,6) |
| ult_maou_windpulse | 52,45 dtk dst (tiap 2,2 dtk) | denyut kabut dan percikan listrik |
| ult_maou_fall | 58,0 dtk | pedang jatuh, kontak di 62,0 |
| ult_maou_hit | 43,0 dan 51,6 dtk | dentuman gong |
| ult_maou_impact / quake / crack / shatter / end | 66,0 - 69,1 dtk | benturan, retakan, dunia pecah, teks |

## Efek berpola (jadwal di maou_cues.gd)

| File | Jumlah pemicu | Pemicu pertama | Fungsi |
|---|---|---|---|
| ult_maou_bell | 20 | 7.0 dtk | bell panjang (pitch diubah per momen) |
| ult_maou_chime | 8 | 44.6 dtk | denting dingin di langit malam |
| ult_maou_crackle | 3 | 52.0 dtk | percikan listrik |
| ult_maou_downer | 6 | 19.0 dtk | ekor rumble rendah setelah hantaman |
| ult_maou_glass | 1 | 67.5 dtk | pecahan kaca |
| ult_maou_heartbeat | 44 | 1.0 dtk | detak jantung (volume naik) |
| ult_maou_riser_ascend | 1 | 40.6 dtk | riser menuju layar putih |
| ult_maou_riser_burst | 1 | 16.0 dtk | riser menuju Burst |
| ult_maou_riser_fall | 1 | 58.0 dtk | riser pedang jatuh |
| ult_maou_riser_ignite | 1 | 4.6 dtk | riser menuju Ignite |
| ult_maou_riser_sword | 1 | 51.6 dtk | riser saat pedang menggantung |
| ult_maou_roar | 1 | 66.1 dtk | gemuruh benturan + puing |
| ult_maou_taiko | 15 | 31.4 dtk | taiko sedang (ritme halo) |
| ult_maou_taiko_l | 6 | 19.0 dtk | taiko besar (momen utama) |
| ult_maou_taiko_s | 63 | 27.6 dtk | taiko pendek (tebasan prisma, ritme jatuh) |
| ult_maou_wind_end | 1 | 68.0 dtk | angin setelah dunia pecah |
| ult_maou_wind_sky | 1 | 44.6 dtk | angin langit malam |

## Musik latar

`ult_maou_bgm_long.mp3` (71,7 dtk) hanya berisi bed musik: paduan suara, senar, drone, dan desis udara. Diputar saat ultimate dimulai.
