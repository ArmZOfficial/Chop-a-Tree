# Sword Pack legacy migration map

สร้างอัตโนมัติด้วย `tools/gen_config.py` (กฎ: rarity เดิม, basePower ไม่ลด, ธาตุเดียวกันถ้ามี, 1:1).

| Legacy id | Legacy name | Rarity | Power เดิม | → Sword id | Sword name | Power ใหม่ | ธาตุ |
|---|---|---|---|---|---|---|---|
| wpn_bent_halberd | Bent Halberd | Common | 125 | swd_001 | Rusty Longsword | 125 | = |
| wpn_stone_chainsaw | Stone Chainsaw | Common | 138 | swd_005 | Copper Greatsword | 138 | = |
| wpn_stone_trident | Stone Trident | Common | 151 | swd_009 | Tin Broadsword | 152 | = |
| wpn_old_guitar | Old Guitar | Common | 164 | swd_013 | Oak Claymore | 166 | = |
| wpn_stone_chakram | Stone Chakram | Common | 177 | swd_017 | Flint Bastard Sword | 180 | = |
| wpn_copper_grimoire | Copper Grimoire | Common | 190 | swd_020 | Rookie Nodachi | 190 | = |
| wpn_oak_longbow | Oak Longbow | Common | 203 | swd_024 | Stone Crystal Blade | 204 | = |
| wpn_old_pickaxe | Old Pickaxe | Common | 216 | swd_028 | Breeze Katana | 217 | –→ลม |
| wpn_rusty_orb | Rusty Orb | Common | 228 | swd_031 | Sprout Cleaver | 228 | –→ธรรมชาติ |
| wpn_stone_lantern | Stone Lantern | Common | 241 | swd_035 | Static Scimitar | 241 | –→สายฟ้า |
| wpn_bent_umbrella | Bent Umbrella | Common | 254 | swd_039 | Sprout Machete | 255 | –→ธรรมชาติ |
| wpn_old_wand | Old Wand | Common | 267 | swd_043 | Static Falchion | 269 | –→สายฟ้า |
| wpn_iron_lance | Iron Lance | Common | 280 | swd_047 | Sprout Khopesh | 283 | –→ธรรมชาติ |
| wpn_keiko_bokuto | Keiko Bokutō 稽古木刀 | Common | 293 | swd_050 | Tidal Shortsword | 293 | –→น้ำ |
| wpn_oak_flail | Oak Flail | Common | 306 | swd_054 | Sprout Rapier | 307 | –→ธรรมชาติ |
| wpn_copper_bell | Copper Bell | Common | 319 | swd_058 | Static Gladius | 321 | –→สายฟ้า |
| wpn_iron_drill | Iron Drill | Common | 332 | swd_062 | Sprout Estoc | 334 | –→ธรรมชาติ |
| wpn_oak_war_fan | Oak War Fan | Common | 345 | swd_065 | Tidal Bastard Sword | 345 | –→น้ำ |
| wpn_rusty_battleaxe | Rusty Battleaxe | Common | 358 | swd_069 | Gleam Zweihander | 358 | –→แสง |
| wpn_iron_banner | Iron Banner | Common | 371 | swd_073 | Tidal Longsword | 372 | –→น้ำ |
| wpn_bent_anchor | Bent Anchor | Common | 384 | swd_077 | Sprout Greatsword | 386 | –→ธรรมชาติ |
| wpn_bent_lollipop | Bent Lollipop | Common | 397 | swd_081 | Static Broadsword | 400 | –→สายฟ้า |
| wpn_rusty_warhammer | Rusty Warhammer | Common | 409 | swd_084 | Gleam Tachi | 410 | –→แสง |
| wpn_iron_staff | Iron Staff | Common | 422 | swd_088 | Tidal Prism Edge | 424 | –→น้ำ |
| wpn_old_bone_club | Old Bone Club | Common | 435 | swd_092 | Gleam Nodachi | 438 | –→แสง |
| wpn_iron_boomerang | Iron Boomerang | Common | 448 | swd_095 | Ember Khopesh | 448 | –→ไฟ |
| wpn_bent_greatsword | Bent Greatsword | Common | 461 | swd_099 | Dusk Sabre | 462 | –→เงา |
| wpn_kurogane_ono | Kurogane Ono 黒鉄斧 | Common | 474 | swd_103 | Tidal Cleaver | 475 | –→น้ำ |
| wpn_rusty_gauntlets | Rusty Gauntlets | Common | 487 | swd_107 | Gleam Scimitar | 489 | –→แสง |
| wpn_bent_scythe | Bent Scythe | Common | 500 | swd_110 | Ember Estoc | 500 | –→ไฟ |
| wpn_dusk_guitar | Dusk Guitar | Rare | 375 | swd_112 | Shade Prism Edge | 386 | = |
| wpn_comet_banner | Comet Banner | Rare | 422 | swd_115 | Comet Falchion | 422 | = |
| wpn_comet_staff | Comet Staff | Rare | 469 | swd_119 | Breeze Khopesh | 470 | จักรวาล→ลม |
| wpn_sprout_flail | Sprout Flail | Rare | 516 | swd_123 | Comet Sabre | 518 | ธรรมชาติ→จักรวาล |
| wpn_thorn_bone_club | Thorn Bone Club | Rare | 562 | swd_130 | Thorn Gladius | 602 | = |
| wpn_static_warhammer | Static Warhammer | Rare | 609 | swd_134 | Volt Estoc | 650 | = |
| wpn_gale_lollipop | Gale Lollipop | Rare | 656 | swd_142 | Breeze Epee | 746 | = |
| wpn_dawn_wand | Dawn Wand | Rare | 703 | swd_144 | Gleam Crystal Blade | 769 | = |
| wpn_ginrei | Ginrei 銀嶺 | Rare | 750 | swd_148 | Tidal Katana | 817 | = |
| wpn_static_whip | Static Whip | Rare | 797 | swd_149 | Volt Greatsword | 829 | = |
| wpn_frost_grimoire | Frost Grimoire | Rare | 844 | swd_156 | Tidal Tachi | 913 | = |
| wpn_hibana_maru | Hibana-maru 火花丸 | Rare | 891 | swd_155 | Blaze Scimitar | 901 | = |
| wpn_shade_trident | Shade Trident | Rare | 938 | swd_166 | Shade Epee | 1033 | = |
| wpn_ember_greatsword | Ember Greatsword | Rare | 984 | swd_162 | Blaze Dirk | 985 | = |
| wpn_blaze_battleaxe | Blaze Battleaxe | Rare | 1031 | swd_170 | Blaze Shortsword | 1081 | = |
| wpn_lunar_mace | Lunar Mace | Rare | 1078 | swd_177 | Comet Broadsword | 1164 | = |
| wpn_gleam_drill | Gleam Drill | Rare | 1125 | swd_175 | Gleam Cleaver | 1140 | = |
| wpn_breeze_lantern | Breeze Lantern | Rare | 1172 | swd_181 | Breeze Claymore | 1212 | = |
| wpn_sprout_scythe | Sprout Scythe | Rare | 1219 | swd_183 | Thorn Machete | 1236 | = |
| wpn_tidal_umbrella | Tidal Umbrella | Rare | 1266 | swd_186 | Volt Dirk | 1272 | น้ำ→สายฟ้า |
| wpn_dusk_longbow | Dusk Longbow | Rare | 1312 | swd_196 | Shade Katana | 1392 | = |
| wpn_dawn_halberd | Dawn Halberd | Rare | 1359 | swd_194 | Volt Shortsword | 1368 | แสง→สายฟ้า |
| wpn_blaze_pickaxe | Blaze Pickaxe | Rare | 1406 | swd_200 | Blaze Shardblade | 1440 | = |
| wpn_tidal_orb | Tidal Orb | Rare | 1453 | swd_202 | Volt Gladius | 1464 | น้ำ→สายฟ้า |
| wpn_ikazuchi_zume | Ikazuchi-zume 雷爪 | Rare | 1500 | swd_205 | Shade Claymore | 1500 | สายฟ้า→เงา |
| wpn_phantom_boomerang | Phantom Boomerang | Epic | 1250 | swd_212 | Phantom Nodachi | 1534 | = |
| wpn_cyclone_bone_club | Cyclone Bone Club | Epic | 1447 | swd_211 | Cyclone Falchion | 1487 | = |
| wpn_phantom_arm_cannon | Phantom Arm Cannon | Epic | 1645 | swd_220 | Phantom Katana | 1914 | = |
| wpn_cyclone_gauntlets | Cyclone Gauntlets | Epic | 1842 | swd_219 | Cyclone Sabre | 1867 | = |
| wpn_cyclone_greatsword | Cyclone Greatsword | Epic | 2039 | swd_223 | Nebula Cleaver | 2056 | ลม→จักรวาล |
| wpn_storm_bell | Storm Bell | Epic | 2237 | swd_227 | Cyclone Scimitar | 2246 | สายฟ้า→ลม |
| wpn_thunder_halberd | Thunder Halberd | Epic | 2434 | swd_233 | Thunder Bastard Sword | 2531 | = |
| wpn_verdant_lance | Verdant Lance | Epic | 2632 | swd_237 | Bloom Zweihander | 2721 | = |
| wpn_radiant_chakram | Radiant Chakram | Epic | 2829 | swd_244 | Holy Katana | 3053 | = |
| wpn_bloom_lantern | Bloom Lantern | Epic | 3026 | swd_245 | Bloom Greatsword | 3101 | = |
| wpn_astral_banner | Astral Banner | Epic | 3224 | swd_248 | Glacier Shardblade | 3243 | จักรวาล→น้ำ |
| wpn_astral_flail | Astral Flail | Epic | 3421 | swd_261 | Nebula Zweihander | 3860 | = |
| wpn_mizuchi_soken | Mizuchi Sōken 蛟双剣 | Epic | 3618 | swd_263 | Glacier Khopesh | 3955 | = |
| wpn_inferno_umbrella | Inferno Umbrella | Epic | 3816 | swd_262 | Magma Epee | 3908 | = |
| wpn_radiant_mace | Radiant Mace | Epic | 4013 | swd_267 | Holy Sabre | 4145 | = |
| wpn_tsukikage_ogama | Tsukikage Ōgama 月影大鎌 | Epic | 4211 | swd_274 | Phantom Gladius | 4477 | = |
| wpn_inferno_guitar | Inferno Guitar | Epic | 4408 | swd_273 | Cyclone Broadsword | 4430 | ไฟ→ลม |
| wpn_thunder_anchor | Thunder Anchor | Epic | 4605 | swd_279 | Thunder Machete | 4715 | = |
| wpn_coral_chainsaw | Coral Chainsaw | Epic | 4803 | swd_281 | Phantom Bastard Sword | 4810 | น้ำ→เงา |
| wpn_coral_lollipop | Coral Lollipop | Epic | 5000 | swd_285 | Magma Zweihander | 5000 | น้ำ→ไฟ |
| wpn_arashigami | Arashigami 嵐神 | Legendary | 4000 | swd_288 | Royal Cyclone Crystal Blade | 4406 | = |
| wpn_abyssal_warlord_grimoire | Abyssal Warlord Grimoire | Legendary | 4857 | swd_294 | Warlord Glacier Rapier | 5627 | = |
| wpn_umbral_king_s_banner | Umbral King's Banner | Legendary | 5714 | swd_297 | Dragon Eclipse Broadsword | 6237 | = |
| wpn_raitei_no_hoko | Raitei no Hoko 雷帝の鉾 | Legendary | 6571 | swd_303 | Royal Tempest Machete | 7457 | = |
| wpn_cyclone_dragon_orb | Cyclone Dragon Orb | Legendary | 7429 | swd_304 | Warlord Cyclone Prism Edge | 7661 | = |
| wpn_cyclone_dragon_trident | Cyclone Dragon Trident | Legendary | 8286 | swd_312 | Dragon Cyclone Crystal Blade | 9288 | = |
| wpn_tempest_warlord_whip | Tempest Warlord Whip | Legendary | 9143 | swd_319 | Warlord Tempest Cleaver | 10711 | = |
| wpn_inferno_warlord_flail | Inferno Warlord Flail | Legendary | 10000 | swd_317 | Dragon Phoenix Greatsword | 10305 | = |
| wpn_nebula_titan_halberd | Nebula Titan Halberd | Legendary | 10857 | swd_324 | Warlord Nebula Tachi | 11728 | = |
| wpn_verdant_titan_lance | Verdant Titan Lance | Legendary | 11714 | swd_331 | Titan Elder Falchion | 13152 | = |
| wpn_abyssal_dragon_scythe | Abyssal Dragon Scythe | Legendary | 12571 | swd_334 | Warlord Glacier Epee | 13762 | = |
| wpn_storm_warlord_mace | Storm Warlord Mace | Legendary | 13429 | swd_335 | Ancient Tempest Khopesh | 13966 | = |
| wpn_holy_titan_pickaxe | Holy Titan Pickaxe | Legendary | 14286 | swd_338 | Royal Holy Shortsword | 14576 | = |
| wpn_phoenix_warlord_drill | Phoenix Warlord Drill | Legendary | 15143 | swd_341 | Titan Phoenix Greatsword | 15186 | = |
| wpn_starfall_dragon_lantern | Starfall Dragon Lantern | Legendary | 16000 | swd_345 | Ancient Eclipse Broadsword | 16000 | จักรวาล→เงา |
| wpn_celestial_sovereign_banner | Celestial Sovereign Banner | Mythic | 12500 | swd_347 | Godslayer Celestial Scimitar | 13602 | = |
| wpn_phoenix_godslayer_staff | Phoenix Godslayer Staff | Mythic | 16667 | swd_350 | Eternal Phoenix Estoc | 16911 | = |
| wpn_starfall_godslayer_gauntlets | Starfall Godslayer Gauntlets | Mythic | 20833 | swd_357 | Godslayer Galaxy Zweihander | 24632 | = |
| wpn_shuryu_to | Shuryū-tō 朱龍刀 | Mythic | 25000 | swd_358 | Primordial Phoenix Epee | 25735 | = |
| wpn_void_worldbreaker_anchor | Void Worldbreaker Anchor | Mythic | 29167 | swd_362 | Godslayer Eclipse Shortsword | 30147 | = |
| wpn_abyssal_eternal_bone_club | Abyssal Eternal Bone Club | Mythic | 33333 | swd_367 | Godslayer Leviathan Cleaver | 35661 | = |
| wpn_shuen_no_hoko | Shūen no Hoko 終焉の鉾 | Mythic | 37500 | swd_370 | Eternal Eclipse Gladius | 38970 | = |
| wpn_stormwing_worldbreaker_trident | Stormwing Worldbreaker Trident | Mythic | 41667 | swd_373 | Primordial Galaxy Claymore | 42279 | ลม→จักรวาล |
| wpn_elder_worldbreaker_grimoire | Elder Worldbreaker Grimoire | Mythic | 45833 | swd_377 | Godslayer Stormwing Bastard Sword | 46691 | ธรรมชาติ→ลม |
| wpn_thunderking_sovereign_lance | Thunderking Sovereign Lance | Mythic | 50000 | swd_380 | Eternal Elder Nodachi | 50000 | สายฟ้า→ธรรมชาติ |
