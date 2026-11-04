class_name Skills
extends RefCounted

const GY := 216.0
const NUKE_STEP := 90.0

# ---- WORLD END (Maou) timeline, detik sejak ultimate dimulai ----
# I  HUSH      0.0  - 7.0   : hening, sigil menyala, jantung berdetak
# II IGNITE    7.0  - 19.0  : aura api emas menyala, tanah retak
# III BURST    19.0 - 27.4  : gelombang kejut, mata Maou terbuka
# IV PRISM     27.4 - 31.0  : badai tebasan warna-warni
# V  HALO      31.0 - 43.0  : cincin pita emas, pilar cahaya, Maou naik
# VI ASCEND    43.0 - 51.6  : langit malam kota, pilar cahaya emas, awan cahaya berlubang, petir biru
# VII SWORD    51.6 - 58.0  : pedang emas turun dari atas lalu menggantung
# VIII FALL    58.0 - 66.0  : pedang jatuh, sinar & puing
# IX IMPACT    66.0 -       : benturan, dunia pecah, teks
const WE_IGNITE := 7.0
const WE_BURST := 19.0
const WE_EYE0 := 21.0
const WE_GLOW := 22.6
const WE_EYE1 := 24.6
const WE_PRISM := 27.4
const WE_PRISM_END := 31.0
const WE_HALO := 31.0
const WE_PILLAR := 33.0
const WE_ASCEND := 43.0
const WE_SKY := 44.6
const WE_CPILLAR := 47.3  # pilar cahaya emas dari gedung ke langit
const WE_BOLT0 := 50.6    # petir biru tunggal
const WE_SWORD := 51.6    # ujung pedang muncul dari atas, turun
const WE_FALL := 58.0
const WE_CONTACT := 62.0
const WE_IMPACT := 66.0
const WE_SHATTER := 67.5
const WE_TEXT := 69.1
const WE_LEN := 71.7
const WE_DX := 0.0       # pilar, sigil, cincin, pedang: tepat di karakter
const WE_EYE_DX := 84.0  # hanya mata yang tetap digeser dari karakter


static func enemies(w: World) -> Array[Hazard]:
	var out: Array[Hazard] = []
	for n in w.ent_root.get_children():
		if n is Hazard:
			var h := n as Hazard
			if h.shurikenable and not h.dying:
				out.append(h)
	return out


static func dash_begin(p: Ninja, kind: String) -> void:
	var dash_sfx := "shadow_dash"
	match kind:
		"gale": dash_sfx = "skill_dash_gale"
		"fire": dash_sfx = "skill_dash_fire"
		"ice": dash_sfx = "skill_dash_ice"
		"plasma": dash_sfx = "skill_dash_plasma"
		"eclipse": dash_sfx = "skill_dash_eclipse"
	Sfx.play(dash_sfx, 1.0, -3.0)
	var w := p.world as World
	p._dash_hit.clear()
	match kind:
		"gale":
			p.jumps_left = 2
			Fx.ring(w.fx_root, p.global_position + Vector2(0, -14), Color(0.6, 1.0, 0.8, 0.9), 4.0, 34.0, 0.3, 3.0)
			Fx.burst(w.fx_root, p.global_position + Vector2(0, -12), Color(0.7, 1.0, 0.85), 14, 120.0, 0.35, 0.0, "spark", true, 40.0, Vector2.LEFT, 2.0)
		"fire":
			Fx.ring(w.fx_root, p.global_position + Vector2(0, -14), Color(1.0, 0.55, 0.15, 0.9), 4.0, 36.0, 0.3, 3.0)
			Fx.burst(w.fx_root, p.global_position + Vector2(0, -12), Color(1.0, 0.6, 0.2), 16, 130.0, 0.4, -40.0, "spark", true, 50.0, Vector2.LEFT, 2.2)
		"plasma":
			Fx.ring(w.fx_root, p.global_position + Vector2(0, -14), Color(0.7, 1.0, 0.25, 0.95), 5.0, 48.0, 0.35, 4.0)
			Fx.ring(w.fx_root, p.global_position + Vector2(0, -14), Color(1.0, 0.4, 0.15, 0.8), 3.0, 30.0, 0.3, 3.0)
			Fx.burst(w.fx_root, p.global_position + Vector2(0, -12), Color(0.75, 1.0, 0.3), 24, 170.0, 0.45, -30.0, "spark", true, 60.0, Vector2.LEFT, 2.4)
			w.shake(3.0, 0.15)
		"eclipse":
			var c0 := p.global_position + Vector2(0, -14)
			Fx.ring(w.fx_root, c0, Color(0.55, 0.25, 1.0, 0.95), 5.0, 58.0, 0.4, 5.0)
			Fx.ring(w.fx_root, c0, Color(1.0, 0.85, 0.35, 0.95), 3.0, 40.0, 0.32, 3.0)
			Fx.burst(w.fx_root, c0, Color(0.65, 0.35, 1.0), 22, 190.0, 0.5, -20.0, "spark", true, 80.0, Vector2.LEFT, 2.4)
			Fx.burst(w.fx_root, c0, Color(1.0, 0.85, 0.35), 22, 190.0, 0.5, -20.0, "spark", true, 80.0, Vector2.LEFT, 2.4)
			w.shake(4.0, 0.18)
		"ice":
			var dur := 2.5 + 0.6 * float(GameState.upgrade_level("unique"))
			var c := p.global_position + Vector2(100.0, -10.0)
			for h in enemies(w):
				if h.global_position.distance_to(c) <= 120.0:
					h.freeze(dur)
			Fx.ring(w.fx_root, c, Color(0.7, 0.95, 1.0, 0.9), 6.0, 120.0, 0.35, 3.0)
			Fx.burst(w.fx_root, p.global_position + Vector2(0, -10), Color(0.8, 0.95, 1.0), 16, 130.0, 0.4, 20.0, "spark", true, 60.0, Vector2.LEFT, 2.0)


static func dash_tick(p: Ninja, kind: String) -> void:
	var w := p.world as World
	var feet := p.global_position + Vector2(-6.0, -4.0)
	match kind:
		"gale":
			Fx.burst(w.fx_root, feet, Color(0.6, 1.0, 0.8), 3, 60.0, 0.3, 0.0, "spark", true, 40.0, Vector2.LEFT, 1.6)
		"fire":
			Fx.burst(w.fx_root, feet, Color(1.0, 0.55, 0.15), 5, 70.0, 0.4, -60.0, "spark", true, 60.0, Vector2.LEFT, 2.0)
			for h in enemies(w):
				if p._dash_hit.has(h.get_instance_id()):
					continue
				if absf(h.global_position.x - p.global_position.x) < 34.0 and absf(h.global_position.y - p.global_position.y) < 40.0:
					p._dash_hit[h.get_instance_id()] = true
					Fx.burst(w.fx_root, h.global_position + Vector2(0, -10), Color(1.0, 0.6, 0.2), 10, 120.0, 0.35, 60.0, "spark", true, 360.0, Vector2.UP, 2.0)
					h.take_damage(2, "fire")
		"ice":
			Fx.burst(w.fx_root, feet, Color(0.75, 0.95, 1.0), 4, 50.0, 0.4, 30.0, "spark", true, 50.0, Vector2.LEFT, 1.8)
		"plasma":
			Fx.burst(w.fx_root, feet, Color(0.7, 1.0, 0.25), 6, 90.0, 0.4, -40.0, "spark", true, 70.0, Vector2.LEFT, 2.4)
			Fx.burst(w.fx_root, feet + Vector2(0, -8), Color(1.0, 0.45, 0.15), 3, 70.0, 0.3, -20.0, "orb", true, 70.0, Vector2.LEFT, 1.8)
			for h in enemies(w):
				if absf(h.global_position.x - p.global_position.x) < 50.0 and absf(h.global_position.y - p.global_position.y) < 60.0:
					Fx.burst(w.fx_root, h.global_position + Vector2(0, -10), Color(0.75, 1.0, 0.3), 14, 150.0, 0.4, 40.0, "spark", true, 360.0, Vector2.UP, 2.2)
					h.kill("plasma")
		"eclipse":
			Fx.burst(w.fx_root, feet, Color(0.6, 0.3, 1.0), 5, 100.0, 0.45, -30.0, "spark", true, 70.0, Vector2.LEFT, 2.6)
			Fx.burst(w.fx_root, feet + Vector2(0, -8), Color(1.0, 0.84, 0.35), 5, 100.0, 0.45, -30.0, "spark", true, 70.0, Vector2.LEFT, 2.6)
			Fx.burst(w.fx_root, feet + Vector2(0, -4), Color(0.2, 0.05, 0.35, 0.9), 2, 60.0, 0.5, -10.0, "orb", false, 60.0, Vector2.LEFT, 3.0)
			_sweep(w, p.global_position + Vector2(14.0, -18.0), 58.0, 66.0, "eclipse")


static func special(p: Ninja, kind: String) -> void:
	var special_sfx := "skill_special_gale"
	match kind:
		"fireball": special_sfx = "skill_special_fireball"
		"frost_nova": special_sfx = "skill_special_frost_nova"
		"nuke_blast": special_sfx = "skill_special_nuke_blast"
		"judgement": special_sfx = "skill_special_judgement"
	Sfx.play(special_sfx, 0.95, -3.0)
	p.shadow_attack_cd = GameState.special_cooldown()
	match kind:
		"gale": _gale(p)
		"fireball": _fireball(p)
		"frost_nova": _frost_nova(p)
		"nuke_blast": _nuke_blast(p)
		"judgement": _judgement(p)


static func _gale(p: Ninja) -> void:
	var w := p.world as World
	var proj := SkillProj.new()
	proj.kind = "wave"
	proj.world = w
	proj.position = p.global_position + Vector2(16.0, -16.0)
	proj.life = 0.9 + 0.22 * float(GameState.upgrade_level("unique"))
	w.ent_root.add_child(proj)
	p.throw_t = 0.25
	p.invuln = maxf(p.invuln, 0.2)
	Fx.ring(w.fx_root, p.global_position + Vector2(14, -16), Color(0.7, 1.0, 0.85, 0.95), 4.0, 30.0, 0.3, 3.0)
	Fx.slash(w.fx_root, p.global_position + Vector2(20, -16), Color(0.7, 1.0, 0.85, 1.0), 34.0)
	w.shake(2.5, 0.12)


static func _fireball(p: Ninja) -> void:
	var w := p.world as World
	var lvl := GameState.upgrade_level("unique")
	var count := 3 + lvl / 2
	var blast := 1.0 + 0.15 * float(lvl)
	p.throw_t = 0.3
	p.invuln = maxf(p.invuln, 0.3)
	var muzzle := p.global_position + Vector2(18.0, -22.0)
	Fx.ring(w.fx_root, muzzle, Color(1.0, 0.6, 0.15, 0.95), 4.0, 42.0, 0.3, 4.0)
	Fx.slash(w.fx_root, muzzle + Vector2(6, 0), Color(1.0, 0.8, 0.3, 1.0), 40.0)
	Fx.burst(w.fx_root, muzzle, Color(1.0, 0.55, 0.15), 26, 220.0, 0.45, 40.0, "spark", true, 70.0, Vector2.RIGHT, 2.4)
	w.shake(3.5, 0.15)
	for i in count:
		var delay := 0.08 * float(i)
		var ang := lerpf(-0.22, 0.10, float(i) / float(maxi(1, count - 1))) if count > 1 else -0.05
		if delay <= 0.0:
			_shoot_fireball(p, ang, blast)
		else:
			w.get_tree().create_timer(delay, true, false, false).timeout.connect(func(): _shoot_fireball(p, ang, blast))


static func _shoot_fireball(p: Ninja, ang: float, blast: float) -> void:
	if not is_instance_valid(p) or p.dead:
		return
	var w := p.world as World
	if w == null:
		return
	var f := SkillProj.new()
	f.kind = "fireball"
	f.world = w
	f.vel = Vector2(cos(ang), sin(ang)) * 560.0
	f.life = 1.4
	f.radius = 56.0
	f.blast_mult = blast
	f.position = p.global_position + Vector2(20.0, -22.0)
	w.ent_root.add_child(f)
	Sfx.play("fireball_launch", 1.0, -5.0)


static func _frost_nova(p: Ninja) -> void:
	var w := p.world as World
	var dur := 3.0 + 0.6 * float(GameState.upgrade_level("unique"))
	var r := 230.0
	var c := p.global_position + Vector2(0.0, -14.0)
	p.invuln = maxf(p.invuln, 0.35)
	for h in enemies(w):
		if h.global_position.distance_to(c) <= r:
			h.freeze(dur)
	Fx.ring(w.fx_root, c, Color(0.7, 0.95, 1.0, 0.95), 8.0, r, 0.5, 5.0)
	Fx.ring(w.fx_root, c, Color(1, 1, 1, 0.9), 4.0, r * 0.75, 0.4, 2.0)
	Fx.ring(w.fx_root, c, Color(0.5, 0.8, 1.0, 0.7), 12.0, r * 1.1, 0.65, 2.0)
	Fx.burst(w.fx_root, c, Color(0.8, 0.95, 1.0), 50, 240.0, 0.7, 60.0, "spark", true, 360.0, Vector2.UP, 2.4)
	Fx.burst(w.fx_root, c, Color(1, 1, 1, 0.9), 24, 120.0, 0.9, 40.0, "dust", true, 360.0, Vector2.UP, 2.4)
	w.shake(3.0, 0.2)
	w.big_flash(0.25)
	Sfx.play("skill_impact_frost", 0.9, -3.0)


static func radiation_pulse(p: Ninja) -> void:
	var w := p.world as World
	if w == null or p.dead:
		return
	var r := float(p.cdata.get("passive_radius", 70.0))
	var c := p.global_position + Vector2(0.0, -14.0)
	var hit := false
	for h in enemies(w):
		if h.global_position.distance_to(c) <= r:
			hit = true
			h.take_damage(1, "radiation")
	if hit:
		Fx.ring(w.fx_root, c, Color(0.7, 1.0, 0.25, 0.5), 10.0, r, 0.3, 2.0)


static func _wipe(p: Ninja, w: World, center: Vector2, enemy_r: float, obstacle_r: float, by: String) -> void:
	for n in w.ent_root.get_children():
		if not (n is Hazard):
			continue
		var h := n as Hazard
		if h.dying:
			continue
		var d := h.global_position.distance_to(center)
		if h.shurikenable:
			if d <= enemy_r:
				Fx.burst(w.fx_root, h.global_position + Vector2(0, -10), Color(0.75, 1.0, 0.3), 14, 170.0, 0.4, 60.0, "spark", true, 360.0, Vector2.UP, 2.2)
				h.kill(by)
		elif d <= obstacle_r:
			Fx.burst(w.fx_root, h.global_position + Vector2(0, -6), Color(1.0, 0.6, 0.2), 8, 110.0, 0.35, 120.0, "spark", true, 360.0, Vector2.UP, 2.0)
			h.queue_free()


static func _nuke_blast(p: Ninja) -> void:
	var w := p.world as World
	var r := 320.0 * (1.0 + 0.12 * float(GameState.upgrade_level("unique")))
	var c := p.global_position + Vector2(0.0, -14.0)
	p.invuln = maxf(p.invuln, 0.8)
	var after_key := "ult_after_storm"
	match p.ult_kind:
		"meteor": after_key = "ult_after_meteor"
		"blizzard": after_key = "ult_after_blizzard"
		"nuke": after_key = "ult_after_nuke"
	Sfx.play(after_key, 0.8, -9.0)
	_wipe(p, w, c, r, r * 0.6, "nuke")
	var dome := UltAura.new()
	dome.kind = "blast"
	dome.follow = false
	dome.radius = r
	dome.p = p
	dome.world = w
	dome.life = 0.8
	dome.position = Vector2(c.x, GY)
	w.fx_root.add_child(dome)
	Fx.ring(w.fx_root, c, Color(0.75, 1.0, 0.25, 0.95), 10.0, r, 0.5, 6.0)
	Fx.ring(w.fx_root, c, Color(1.0, 0.55, 0.15, 0.9), 6.0, r * 0.8, 0.4, 4.0)
	Fx.ring(w.fx_root, c, Color(1, 1, 1, 0.9), 4.0, r * 0.55, 0.3, 3.0)
	Fx.burst(w.fx_root, c, Color(0.75, 1.0, 0.3), 80, 320.0, 0.8, 100.0, "spark", true, 360.0, Vector2.UP, 2.8)
	Fx.burst(w.fx_root, c, Color(1.0, 0.5, 0.15), 40, 220.0, 0.7, 160.0, "orb", true, 360.0, Vector2.UP, 2.4)
	for k in 5:
		Fx.smoke(w.fx_root, Vector2(c.x + randf_range(-r * 0.5, r * 0.5), GY - 2.0), Color(0.3, 0.35, 0.2, 0.8))
	w.big_flash(0.8)
	w.shake(14.0, 0.5)
	w.hitstop(0.08)
	_aberration(w)
	Sfx.play("skill_impact_nuke", 0.9, -2.0)


static func _aberration(w: World) -> void:
	w.fx_ab = 1.0
	var tw := w.create_tween()
	tw.tween_property(w, "fx_ab", 0.0, 0.8)


static func _nuke_detonate(p: Ninja) -> void:
	var w := p.world as World
	var lvl := float(GameState.upgrade_level("unique"))
	var rr := 720.0 * (1.0 + 0.12 * lvl)
	var c := Vector2(p.global_position.x, GY)
	_wipe(p, w, Vector2(p.global_position.x, GY - 20.0), rr, rr, "nuke")
	var cloud := UltAura.new()
	cloud.kind = "mushroom"
	cloud.follow = false
	cloud.p = p
	cloud.world = w
	cloud.life = 3.8
	cloud.position = c
	w.fx_root.add_child(cloud)
	for k in 4:
		Fx.ring(w.fx_root, c + Vector2(0, -6), Color(0.75, 1.0, 0.25, 0.9 - 0.15 * k), 12.0, 380.0 + 90.0 * k, 0.5 + 0.12 * k, 8.0 - 1.5 * k)
	Fx.ring(w.fx_root, c + Vector2(0, -60), Color(1, 1, 1, 0.95), 20.0, 300.0, 0.45, 10.0)
	Fx.burst(w.fx_root, c + Vector2(0, -30), Color(1.0, 0.95, 0.6), 120, 420.0, 0.9, 40.0, "spark", true, 360.0, Vector2.UP, 4.0)
	Fx.burst(w.fx_root, c + Vector2(0, -20), Color(1.0, 0.45, 0.12), 90, 300.0, 1.1, 120.0, "orb", true, 360.0, Vector2.UP, 3.4)
	Fx.burst(w.fx_root, c, Color(0.7, 1.0, 0.3), 70, 360.0, 1.0, 200.0, "spark", true, 180.0, Vector2.UP, 3.0)
	for k in 8:
		Fx.smoke(w.fx_root, Vector2(c.x + randf_range(-260.0, 260.0), GY - 2.0), Color(0.35, 0.38, 0.2, 0.85))
	w.big_flash(0.8)
	w.shake(28.0, 1.0)
	w.zoom_punch = 0.14
	_aberration(w)
	w.bonus += 500
	w.popup.emit(p.global_position + Vector2(0, -50), "ZERO HOUR", Color(0.75, 1.0, 0.25))


static func _ts(v: float) -> void:
	Engine.time_scale = v


static func audio_lead() -> float:
	return clampf(AudioServer.get_output_latency(), 0.0, 0.15)


static func _cue(p: Ninja, key: String, t: float, at: float, sfx: String, pitch: float = 1.0, vol: float = 0.0) -> void:
	if _once(p, "a_" + key, t >= at - audio_lead()):
		Sfx.play(sfx, pitch, vol)


static func _once(p: Ninja, key: String, cond: bool) -> bool:
	if cond and not p._cine.has(key):
		p._cine[key] = true
		return true
	return false


static func _ghosts(p: Ninja, cols: Array) -> void:
	var w := p.world as World
	for i in cols.size():
		var g := p.pivot.duplicate() as Node2D
		g.position = Vector2.ZERO
		g.rotation = 0.0
		g.scale = Vector2.ONE
		g.modulate = cols[i]
		g.z_index = 24 + i
		w.fx_root.add_child(g)
		p.ultimate_ghosts.append(g)
		p.ultimate_ghost_origins.append(p.global_position)


static func _orbit(p: Ninja, t: float, jump_y: float, rx: float, ry: float, spd: float, alpha: float) -> void:
	var n := p.ultimate_ghosts.size()
	for i in n:
		var g := p.ultimate_ghosts[i]
		if not is_instance_valid(g):
			continue
		var ang := t * spd + float(i) * TAU / float(maxi(1, n))
		g.global_position = p.global_position + Vector2(cos(ang) * rx, sin(ang) * ry) + Vector2(0.0, -14.0 + jump_y)
		g.rotation = p.pivot.rotation + float(i) * 0.16
		g.modulate.a = alpha


static func _pose_charge(p: Ninja, t: float) -> void:
	p._limb(p.arm_a, Vector2(-2.0, -20.0), -2.4, 0.2)
	p._limb(p.arm_b, Vector2(3.0, -20.0), -1.9 + sin(t * 10.0) * 0.1, 0.2)
	p._limb(p.leg_a, Vector2(-2.0, -9.0), 0.7, -1.0)
	p._limb(p.leg_b, Vector2(2.0, -9.0), -0.5, -0.9)


static func _pose_cast(p: Ninja, t: float) -> void:
	p._limb(p.arm_a, Vector2(-2.0, -20.0), -2.5, 0.1)
	p._limb(p.arm_b, Vector2(3.0, -20.0), -2.85 + sin(t * 9.0) * 0.06, 0.08)
	p._limb(p.leg_a, Vector2(-2.0, -9.0), 1.5 + sin(t * 12.0) * 0.2, -0.2)
	p._limb(p.leg_b, Vector2(2.0, -9.0), 1.1 - sin(t * 12.0) * 0.2, -0.1)


static func _pose_run(p: Ninja, t: float) -> void:
	var s := sin(t * 30.0)
	var c := cos(t * 30.0)
	p._limb(p.arm_a, Vector2(-0.5, -20.0), -2.0, -0.15)
	p._limb(p.arm_b, Vector2(-0.5, -20.0), -1.8, -0.15)
	p._limb(p.leg_a, Vector2(0.0, -9.0), s * 1.1, -0.4 - maxf(0.0, c) * 1.1)
	p._limb(p.leg_b, Vector2(0.0, -9.0), -s * 1.1, -0.4 - maxf(0.0, -c) * 1.1)


static func _sweep(w: World, center: Vector2, rx: float, ry: float, by: String) -> void:
	for n in w.ent_root.get_children():
		if not (n is Hazard):
			continue
		var h := n as Hazard
		if h.dying:
			continue
		if absf(h.global_position.x - center.x) > rx or absf(h.global_position.y - center.y) > ry:
			continue
		if h.shurikenable:
			Fx.burst(w.fx_root, h.global_position + Vector2(0, -10), Color(1, 1, 1), 12, 150.0, 0.35, 80.0, "spark", true, 360.0, Vector2.UP, 2.0)
			h.kill(by)
		else:
			Fx.burst(w.fx_root, h.global_position + Vector2(0, -6), Color(1.0, 0.8, 0.5), 8, 110.0, 0.35, 120.0, "spark", true, 360.0, Vector2.UP, 2.0)
			h.queue_free()


static func _clear_props(w: World, col: Color) -> void:
	for n in w.prop_root.get_children():
		Fx.burst(w.fx_root, n.global_position + Vector2(0, -20), col, 10, 140.0, 0.45, 180.0)
		n.queue_free()


static func _finale_slashes(w: World, center: Vector2, c1: Color, c2: Color) -> void:
	for ang in [-0.78, 0.78, 0.0, 1.57]:
		var slash := FxShape.new()
		slash.kind = "slash"
		slash.col = c1 if ang == 0.0 else c2
		slash.r0 = 72.0
		slash.r1 = 220.0
		slash.life = 0.42
		slash.width = 8.0 if ang == 0.0 else 5.0
		slash.angle0 = -1.25
		slash.angle1 = 1.25
		slash.position = center
		slash.rotation = ang
		w.fx_root.add_child(slash)


static func cine_begin(p: Ninja, kind: String) -> void:
	var w := p.world as World
	p.ult_acc = 0.0
	p.ult_acc2 = 0.0
	p.shadow_attack_active = false
	var c := p.global_position + Vector2(0.0, -14.0)
	var col := Color(0.6, 1.0, 0.8)
	match kind:
		"storm":
			col = Color(0.6, 1.0, 0.8)
			w.fx_tint = Color(0.8, 1.12, 0.95)
			w.fx_raycol = Color(0.3, 1.0, 0.6)
		"meteor":
			col = Color(1.0, 0.5, 0.15)
			w.fx_tint = Color(1.2, 0.92, 0.78)
			w.fx_raycol = Color(1.0, 0.45, 0.1)
		"blizzard":
			col = Color(0.7, 0.95, 1.0)
			w.fx_tint = Color(0.85, 1.0, 1.25)
			w.fx_raycol = Color(0.6, 0.9, 1.0)
		"nuke":
			col = Color(0.75, 1.0, 0.25)
			w.fx_tint = Color(1.0, 1.1, 0.8)
			w.fx_raycol = Color(0.7, 1.0, 0.2)
		"worldend":
			col = Color(1.0, 0.84, 0.36)
			w.fx_tint = Color(0.92, 0.86, 1.14)
			w.fx_raycol = Color(0.85, 0.55, 1.0)
	var dir_paths := {
		"storm": "res://scripts/fx/ult_hayate.gd",
		"meteor": "res://scripts/fx/ult_honoo.gd",
		"blizzard": "res://scripts/fx/ult_kori.gd",
		"nuke": "res://scripts/fx/ult_kakuou.gd",
		"worldend": "res://scripts/fx/ult_maou.gd",
	}
	var d := load(String(dir_paths.get(kind, "res://scripts/fx/ult_hayate.gd"))) as GDScript
	if d:
		var dir := d.new() as Node2D
		dir.call("setup", w, p, kind)
		w.fx_root.add_child(dir)
	Fx.ring(w.fx_root, c, Color(col.r, col.g, col.b, 0.95), 8.0, 90.0, 0.5, 5.0)
	Fx.ring(w.fx_root, c, Color(1, 1, 1, 0.8), 4.0, 56.0, 0.35, 3.0)
	Fx.burst(w.fx_root, c, col, 30, 160.0, 0.6, -10.0, "spark", true, 360.0, Vector2.UP, 2.6)
	w.popup.emit(p.global_position + Vector2(0, -44), String(GameState.char_def()["skills"]["ultimate"]["name"]), col)


static func cine_update(p: Ninja, delta: float, rd: float, t: float) -> void:
	match p.ult_kind:
		"storm": _storm(p, delta, rd, t)
		"meteor": _inferno(p, delta, rd, t)
		"blizzard": _blizzard(p, delta, rd, t)
		"nuke": _nuke_ult(p, delta, rd, t)
		"worldend": _worldend(p, delta, rd, t)
	p.pivot.position = Vector2(0.0, -14.0 + float(p._cine.get("jy", 0.0)))


static func cine_end(p: Ninja) -> void:
	var w := p.world as World
	var x := p.global_position.x
	var tries := 0
	while tries < 60 and not (w.ground_at(x) and w.ground_at(x + 16.0)):
		x += 8.0
		tries += 1
	p.global_position.x = x
	for g in p.ultimate_ghosts:
		if is_instance_valid(g):
			g.queue_free()
	p.ultimate_ghosts.clear()
	p.ultimate_ghost_origins.clear()
	p._cine.clear()
	w.fx_tint = Color(0.78, 0.86, 1.18)
	w.fx_raycol = Color(0.30, 0.55, 1.0)
	p.invuln = maxf(p.invuln, 0.8)


static func _storm(p: Ninja, delta: float, rd: float, t: float) -> void:
	var w := p.world as World
	_cue(p, "tornado", t, 0.9, "ult_tornado", 0.72, -5.0)
	_cue(p, "rush", t, 1.7, "ult_rush_storm", 0.82, -3.0)
	_cue(p, "impact", t, 3.7, "ult_impact_storm", 0.95, -1.0)
	var bc := p.pivot.global_position
	var jy := 0.0
	if t < 0.9:
		_ts(0.24)
		_pose_charge(p, t)
		if int(t * 10.0) != int((t - rd) * 10.0):
			w.shake(1.0 + t * 3.0, 0.1)
	elif t < 1.7:
		_ts(0.4)
		var u := clampf((t - 0.9) / 0.8, 0.0, 1.0)
		jy = -90.0 * sin(u * PI * 0.5)
		p.pivot.rotation = -(t - 0.9) * 18.0
		_pose_cast(p, t)
		if _once(p, "ascend", true):
			Fx.ring(w.fx_root, bc, Color(0.6, 1.0, 0.8, 0.95), 10.0, 220.0, 0.55, 7.0)
			Fx.ring(w.fx_root, bc, Color(1, 1, 1, 0.9), 6.0, 140.0, 0.4, 4.0)
			Fx.burst(w.fx_root, bc, Color(0.7, 1.0, 0.85), 40, 260.0, 0.7, 0.0, "spark", true, 360.0, Vector2.UP, 3.0)
			w.big_flash(0.22)
			w.shake(6.0, 0.4)
	elif t < 3.7:
		_ts(1.0)
		if _once(p, "rush", true):
			w.ult_zoom = 1.45
			w.big_flash(0.3)
			w.shake(12.0, 0.5)
			Fx.ring(w.fx_root, bc, Color(0.7, 1.0, 0.9, 0.95), 10.0, 260.0, 0.45, 8.0)
			p.magnet_t = maxf(p.magnet_t, 6.0)
		var land := clampf((t - 1.7) / 0.25, 0.0, 1.0)
		jy = lerpf(-90.0, 0.0, land)
		p.pivot.rotation = lerpf(p.pivot.rotation, 0.32, 0.3)
		_pose_run(p, t)
		p.global_position.x += 780.0 * delta
		w.fx_dash = 0.8
		w.fx_ab = maxf(w.fx_ab, 0.25)
		_sweep(w, p.global_position + Vector2(10.0, -20.0), 70.0, 90.0, "ultimate")
		p.ult_acc += delta
		if p.ult_acc >= 0.2:
			p.ult_acc = 0.0
			var wv := SkillProj.new()
			wv.kind = "wave"
			wv.world = w
			wv.vel = Vector2(1000.0, 0.0)
			wv.life = 0.55
			wv.position = p.global_position + Vector2(40.0, -18.0 + randf_range(-26.0, 26.0))
			w.ent_root.add_child(wv)
		p.ult_acc2 += delta
		if p.ult_acc2 >= 0.04:
			p.ult_acc2 = 0.0
			p._spawn_afterimage()
			Fx.burst(w.fx_root, p.global_position + Vector2(-8.0, -6.0), Color(0.6, 1.0, 0.8), 3, 80.0, 0.3, 0.0, "spark", true, 50.0, Vector2.LEFT, 2.0)
	else:
		_ts(0.3)
		jy = 0.0
		p.pivot.rotation = lerpf(p.pivot.rotation, 0.0, 0.2)
		_pose_cast(p, t)
		w.fx_dash = 0.0
		if _once(p, "final", true):
			w.ult_zoom = 1.9
			var c := p.global_position + Vector2(40.0, -16.0)
			_sweep(w, c, 560.0, 200.0, "ultimate")
			_clear_props(w, Color(0.6, 1.0, 0.8))
			_finale_slashes(w, c, Color(0.9, 1.0, 0.95), Color(0.5, 1.0, 0.75))
			for k in 4:
				Fx.ring(w.fx_root, c, Color(0.6 + 0.1 * k, 1.0, 0.85, 0.95 - 0.12 * k), 12.0, 260.0 + 80.0 * k, 0.5 + 0.1 * k, 8.0 - 1.5 * k)
			Fx.burst(w.fx_root, c, Color(0.8, 1.0, 0.9), 100, 340.0, 0.75, -20.0, "spark", true, 360.0, Vector2.UP, 3.8)
			Fx.burst(w.fx_root, c, Color(0.4, 0.95, 0.65), 40, 240.0, 0.8, 40.0, "orb", true, 360.0, Vector2.UP, 3.0)
			w.big_flash(0.6)
			w.shake(22.0, 0.8)
			w.fx_ab = 0.6
	p._cine["jy"] = jy


static func _inferno(p: Ninja, delta: float, rd: float, t: float) -> void:
	var w := p.world as World
	_cue(p, "fire", t, 1.1, "ult_fire", 0.78, -5.0)
	_cue(p, "barrage", t, 1.7, "ult_meteor_barrage", 0.8, -4.0)
	var bc := p.pivot.global_position
	var jy := 0.0
	if t < 1.1:
		_ts(0.24)
		_pose_charge(p, t)
		if _once(p, "stomp", true):
			Fx.ring(w.fx_root, Vector2(p.global_position.x, GY - 2.0), Color(1.0, 0.55, 0.15, 0.95), 8.0, 150.0, 0.5, 6.0)
			Fx.burst(w.fx_root, Vector2(p.global_position.x, GY - 2.0), Color(1.0, 0.55, 0.15), 50, 260.0, 0.6, 300.0, "spark", true, 120.0, Vector2.UP, 3.0)
		if int(t * 7.0) != int((t - rd) * 7.0):
			w.shake(1.5 + t * 3.0, 0.12)
			Fx.burst(w.fx_root, Vector2(p.global_position.x + randf_range(-70.0, 70.0), GY - 2.0), Color(1.0, 0.55, 0.15), 12, 160.0, 0.5, 200.0, "spark", true, 60.0, Vector2.UP, 2.4)
	elif t < 1.7:
		_ts(0.4)
		var u := clampf((t - 1.1) / 0.6, 0.0, 1.0)
		jy = -70.0 * sin(u * PI * 0.5)
		_pose_cast(p, t)
		if _once(p, "rise", true):
			Fx.ring(w.fx_root, bc, Color(1.0, 0.55, 0.15, 0.95), 10.0, 240.0, 0.6, 7.0)
			Fx.ring(w.fx_root, bc, Color(1.0, 0.95, 0.6, 0.9), 6.0, 150.0, 0.4, 4.0)
			Fx.burst(w.fx_root, bc, Color(1.0, 0.7, 0.25), 70, 280.0, 0.8, 80.0, "spark", true, 360.0, Vector2.UP, 3.2)
			w.big_flash(0.25)
			w.shake(7.0, 0.5)
	elif t < 3.5:
		_ts(0.5)
		jy = -70.0 + sin(t * 3.0) * 6.0
		_pose_cast(p, t)
		if _once(p, "barrage", true):
			w.ult_zoom = 1.7
			w.big_flash(0.3)
		p.ult_acc += rd
		while p.ult_acc >= 0.055:
			p.ult_acc -= 0.055
			_spawn_meteor(p, randf_range(1.0, 1.7))
		if int(t * 5.0) != int((t - rd) * 5.0):
			w.shake(4.0, 0.15)
	else:
		_ts(0.3 if t < 4.1 else 0.6)
		var dsc := clampf((t - 3.8) / 0.6, 0.0, 1.0)
		jy = lerpf(-70.0, 0.0, dsc)
		_pose_cast(p, t)
		if _once(p, "mega", true):
			var mx := p.global_position.x + 130.0
			p._cine["mega_x"] = mx
			var m := SkillProj.new()
			m.kind = "meteor"
			m.mega = true
			m.world = w
			m.scale = Vector2(3.0, 3.0)
			m.vel = Vector2(200.0, 1500.0)
			var start_y := w.cam.position.y - 210.0
			var fall_t := (GY - start_y) / m.vel.y
			m.position = Vector2(mx - m.vel.x * fall_t, start_y)
			w.ent_root.add_child(m)
			_mark(p, m, mx, 3.0, true)
			_ts(0.2)
	p._cine["jy"] = jy


static func _spawn_meteor(p: Ninja, size: float) -> void:
	var w := p.world as World
	var x := p.global_position.x + randf_range(-170.0, 470.0)
	if randf() < 0.5:
		var best: Hazard = null
		var best_d := 99999.0
		for h in enemies(w):
			var dx := h.global_position.x - p.global_position.x
			if dx > -100.0 and dx < 500.0 and dx < best_d:
				best_d = dx
				best = h
		if best != null:
			x = best.global_position.x + randf_range(-12.0, 12.0)
	var m := SkillProj.new()
	m.kind = "meteor"
	m.world = w
	m.scale = Vector2(size, size)
	m.vel = Vector2(170.0, 640.0)
	var start_y := w.cam.position.y - 210.0
	var fall_t := (GY - start_y) / m.vel.y
	m.position = Vector2(x - m.vel.x * fall_t, start_y)
	w.ent_root.add_child(m)
	_mark(p, m, x, size, false)


static func _mark(p: Ninja, node: Node2D, x: float, size: float, mega: bool) -> void:
	var arr: Array = p._cine.get("marks", [])
	for i in range(arr.size() - 1, -1, -1):
		if not is_instance_valid((arr[i] as Dictionary).get("node")):
			arr.remove_at(i)
	arr.append({"node": node, "x": x, "size": size, "mega": mega})
	p._cine["marks"] = arr


static func inferno_mega(w: World, x: float) -> void:
	var p := w.player
	var c := Vector2(x, GY)
	_sweep(w, Vector2(x, GY - 60.0), 700.0, 260.0, "ultimate")
	_clear_props(w, Color(1.0, 0.6, 0.2))
	p._cine["mega_x"] = x
	p._cine["mega_t"] = p.ultimate_elapsed
	var dome := UltAura.new()
	dome.kind = "blast"
	dome.follow = false
	dome.radius = 560.0
	dome.tint = Color(1.0, 0.6, 0.15)
	dome.p = p
	dome.world = w
	dome.life = 1.1
	dome.position = c
	w.fx_root.add_child(dome)
	for k in 4:
		Fx.ring(w.fx_root, c + Vector2(0, -6), Color(1.0, 0.5 + 0.1 * k, 0.15, 0.95 - 0.12 * k), 12.0, 380.0 + 90.0 * k, 0.5 + 0.12 * k, 8.0 - 1.5 * k)
	Fx.ring(w.fx_root, c + Vector2(0, -50), Color(1, 1, 0.9, 0.95), 20.0, 300.0, 0.45, 10.0)
	Fx.burst(w.fx_root, c + Vector2(0, -30), Color(1.0, 0.95, 0.6), 120, 440.0, 0.9, 40.0, "spark", true, 360.0, Vector2.UP, 4.0)
	Fx.burst(w.fx_root, c + Vector2(0, -20), Color(1.0, 0.45, 0.12), 100, 320.0, 1.1, 150.0, "orb", true, 360.0, Vector2.UP, 3.4)
	for k in 6:
		Fx.smoke(w.fx_root, Vector2(c.x + randf_range(-240.0, 240.0), GY - 2.0), Color(0.4, 0.25, 0.2, 0.85))
	_finale_slashes(w, c + Vector2(0, -40), Color(1.0, 0.95, 0.7), Color(1.0, 0.5, 0.15))
	w.big_flash(0.7)
	w.shake(26.0, 0.9)
	w.zoom_punch = 0.12
	_aberration(w)
	Sfx.play("ult_impact_meteor", 0.95, -1.0)


static func _blizzard(p: Ninja, delta: float, rd: float, t: float) -> void:
	var w := p.world as World
	_cue(p, "ice", t, 1.0, "ult_ice", 0.5, -3.0)
	_cue(p, "freeze", t, 1.8, "ult_freeze_wave", 0.75, -2.0)
	_cue(p, "shatter", t, 3.1, "ult_impact_blizzard", 0.95, -1.5)
	var bc := p.pivot.global_position
	var jy := 0.0
	var lvl := float(GameState.upgrade_level("unique"))
	if t < 1.0:
		_ts(0.24)
		_pose_charge(p, t)
		if _once(p, "start", true):
			Fx.burst(w.fx_root, Vector2(p.global_position.x, w.cam.position.y - 110.0), Color(0.9, 0.97, 1.0), 40, 90.0, 1.4, 90.0, "dust", true, 200.0, Vector2.DOWN, 2.4)
		if int(t * 8.0) != int((t - rd) * 8.0):
			w.shake(1.0 + t * 2.0, 0.1)
			Fx.burst(w.fx_root, Vector2(p.global_position.x + randf_range(-110.0, 110.0), GY - 2.0), Color(0.8, 0.95, 1.0), 8, 90.0, 0.6, -40.0, "spark", true, 60.0, Vector2.UP, 2.2)
	elif t < 1.8:
		_ts(0.35)
		var u := clampf((t - 1.0) / 0.8, 0.0, 1.0)
		jy = -80.0 * sin(u * PI * 0.5)
		_pose_cast(p, t)
		if _once(p, "rise", true):
			Fx.ring(w.fx_root, bc, Color(0.7, 0.95, 1.0, 0.95), 10.0, 230.0, 0.55, 7.0)
			Fx.ring(w.fx_root, bc, Color(1, 1, 1, 0.9), 6.0, 150.0, 0.4, 4.0)
			Fx.burst(w.fx_root, bc, Color(0.8, 0.96, 1.0), 70, 270.0, 0.8, 40.0, "spark", true, 360.0, Vector2.UP, 3.0)
			w.big_flash(0.25)
			w.shake(6.0, 0.4)
	elif t < 3.1:
		_ts(0.3)
		jy = -80.0 + sin(t * 3.0) * 5.0
		_pose_cast(p, t)
		if _once(p, "freeze", true):
			w.ult_zoom = 1.8
			var fz := 9.0 + 0.6 * lvl
			for h in enemies(w):
				if absf(h.global_position.x - p.global_position.x) < 760.0:
					h.freeze(fz)
			for k in 4:
				Fx.ring(w.fx_root, bc, Color(0.75 + 0.05 * k, 0.95, 1.0, 0.95 - 0.15 * k), 12.0, 420.0 + 110.0 * k, 0.6 + 0.12 * k, 8.0 - 1.5 * k)
			Fx.burst(w.fx_root, bc, Color(0.85, 0.97, 1.0), 110, 340.0, 0.9, 30.0, "spark", true, 360.0, Vector2.UP, 3.4)
			w.big_flash(0.4)
			w.shake(10.0, 0.6)
			w.fx_ab = 0.5
		p.ult_acc += rd
		if p.ult_acc >= 0.3:
			p.ult_acc = 0.0
			for h in enemies(w):
				if h.frozen_t <= 0.0 and absf(h.global_position.x - p.global_position.x) < 760.0:
					h.freeze(7.0)
			Fx.burst(w.fx_root, Vector2(w.cam_x + randf_range(-300.0, 300.0), w.cam.position.y - 120.0), Color(0.92, 0.98, 1.0), 14, 80.0, 1.2, 110.0, "dust", true, 90.0, Vector2.DOWN, 2.2)
	else:
		_ts(0.15 if t < 3.5 else 0.6)
		var dsc := clampf((t - 3.5) / 0.6, 0.0, 1.0)
		jy = lerpf(-80.0, 0.0, dsc)
		_pose_cast(p, t)
		if _once(p, "shatter", true):
			var c := p.global_position + Vector2(40.0, -16.0)
			for h in enemies(w):
				if absf(h.global_position.x - p.global_position.x) < 800.0:
					Fx.burst(w.fx_root, h.global_position + Vector2(0, -12), Color(0.85, 0.97, 1.0), 22, 230.0, 0.7, 260.0, "spark", true, 360.0, Vector2.UP, 2.6)
					Fx.ring(w.fx_root, h.global_position + Vector2(0, -12), Color(0.9, 0.98, 1.0, 0.9), 4.0, 38.0, 0.3, 2.5)
					h.kill("shatter")
			_sweep(w, c, 640.0, 220.0, "shatter")
			_clear_props(w, Color(0.8, 0.95, 1.0))
			_finale_slashes(w, c, Color(0.95, 1.0, 1.0), Color(0.55, 0.85, 1.0))
			for k in 4:
				Fx.ring(w.fx_root, c, Color(0.8 + 0.05 * k, 0.96, 1.0, 0.95 - 0.12 * k), 12.0, 280.0 + 90.0 * k, 0.5 + 0.1 * k, 8.0 - 1.5 * k)
			Fx.burst(w.fx_root, c, Color(0.9, 0.98, 1.0), 140, 380.0, 0.9, 260.0, "spark", true, 360.0, Vector2.UP, 4.0)
			Fx.burst(w.fx_root, c, Color(0.6, 0.85, 1.0), 70, 260.0, 1.0, 180.0, "orb", true, 360.0, Vector2.UP, 3.0)
			w.big_flash(0.65)
			w.shake(22.0, 0.9)
			w.fx_ab = 0.6
	p._cine["jy"] = jy


static func _nuke_ult(p: Ninja, delta: float, rd: float, t: float) -> void:
	var w := p.world as World
	_cue(p, "cd3", t, 0.2, "ult_nuke_countdown", 1.0, -1.0)
	_cue(p, "cd2", t, 0.65, "ult_nuke_countdown", 1.0, -1.0)
	_cue(p, "cd1", t, 1.1, "ult_nuke_countdown", 1.0, -1.0)
	_cue(p, "boom", t, 1.5, "ult_impact_nuke", 0.9, -1.0)
	_cue(p, "nova", t, 4.2, "ult_finish_nuke", 0.95, -1.0)
	var bc := p.pivot.global_position
	var jy := 0.0
	var green := Color(0.75, 1.0, 0.25)
	if not p._cine.has("x0"):
		p._cine["x0"] = p.global_position.x
	var x0 := float(p._cine["x0"])
	p.global_position.x = x0 + NUKE_STEP * smoothstep(0.1, 1.3, t)
	if t < 1.5:
		_ts(0.24)
		jy = -26.0 * smoothstep(0.2, 1.2, t)
		_pose_cast(p, t)
		for entry in [[0.2, "3"], [0.65, "2"], [1.1, "1"]]:
			if _once(p, "cd" + String(entry[1]), t >= float(entry[0])):
				Fx.ring(w.fx_root, Vector2(x0 + NUKE_STEP, GY - 2.0), Color(1.0, 0.4, 0.2, 0.9), 6.0, 70.0, 0.3, 3.0)
		if int(t * 10.0) != int((t - rd) * 10.0):
			w.shake(2.0 + t * 5.0, 0.12)
		w.fx_ab = 0.2 + 0.2 * (0.5 + 0.5 * sin(t * 22.0))
	elif t < 4.2:
		_ts(0.2 if t < 2.4 else 0.5)
		jy = -26.0 + sin(t * 2.5) * 4.0
		_pose_cast(p, t)
		if _once(p, "boom", true):
			w.ult_zoom = 1.25
			_nuke_detonate(p)
		if t >= 2.4:
			p.ult_acc += rd
			if p.ult_acc >= 0.14:
				p.ult_acc = 0.0
				var bx := p.global_position.x + randf_range(-330.0, 470.0)
				Fx.bolt(w.fx_root, Vector2(bx, w.cam.position.y - 180.0), Vector2(bx + randf_range(-20.0, 20.0), GY), Color(0.8, 1.0, 0.4, 0.95))
				Fx.burst(w.fx_root, Vector2(bx, GY - 4.0), Color(0.75, 1.0, 0.3), 12, 150.0, 0.4, 200.0, "spark", true, 120.0, Vector2.UP, 2.2)
				_sweep(w, Vector2(bx, GY - 30.0), 60.0, 120.0, "nuke")
				w.shake(3.0, 0.1)
	else:
		_ts(0.25 if t < 4.8 else 0.6)
		var dsc := clampf((t - 4.7) / 0.7, 0.0, 1.0)
		jy = lerpf(-26.0, 0.0, dsc)
		_pose_cast(p, t)
		if _once(p, "nova", true):
			var c := Vector2(p.global_position.x, GY - 20.0)
			_sweep(w, c, 760.0, 260.0, "nuke")
			for k in 5:
				Fx.ring(w.fx_root, c, Color(0.75, 1.0, 0.25, 0.95 - 0.12 * k), 14.0, 420.0 + 120.0 * k, 0.55 + 0.12 * k, 9.0 - 1.5 * k)
			Fx.ring(w.fx_root, c, Color(1, 1, 1, 0.95), 20.0, 360.0, 0.4, 12.0)
			Fx.burst(w.fx_root, c, Color(0.85, 1.0, 0.5), 140, 420.0, 0.9, 40.0, "spark", true, 360.0, Vector2.UP, 4.0)
			_finale_slashes(w, c, Color(1, 1, 0.9), Color(0.75, 1.0, 0.25))
			w.big_flash(0.6)
			w.shake(20.0, 0.8)
			w.fx_ab = 0.7
	p._cine["jy"] = jy


static func eclipse_pulse(p: Ninja) -> void:
	var w := p.world as World
	if w == null or p.dead:
		return
	var r := float(p.cdata.get("passive_radius", 96.0))
	var c := p.global_position + Vector2(0.0, -14.0)
	var hit := false
	for h in enemies(w):
		if h.global_position.distance_to(c) <= r:
			hit = true
			Fx.burst(w.fx_root, h.global_position + Vector2(0, -10), Color(0.62, 0.32, 1.0), 8, 130.0, 0.4, 60.0, "spark", true, 360.0, Vector2.UP, 2.2)
			Fx.burst(w.fx_root, h.global_position + Vector2(0, -10), Color(1.0, 0.84, 0.36), 8, 130.0, 0.4, 60.0, "spark", true, 360.0, Vector2.UP, 2.2)
			h.kill("eclipse")
	if hit:
		Fx.ring(w.fx_root, c, Color(0.62, 0.32, 1.0, 0.55), 10.0, r, 0.3, 2.0)
		Fx.ring(w.fx_root, c, Color(1.0, 0.84, 0.36, 0.45), 6.0, r * 0.8, 0.26, 1.5)


static func _judgement(p: Ninja) -> void:
	var w := p.world as World
	var lvl := GameState.upgrade_level("unique")
	var reach := 1.0 + 0.15 * float(lvl)
	var count := 7
	var spacing := 70.0 * reach
	var c := p.global_position + Vector2(0.0, -14.0)
	p.throw_t = 0.35
	p.invuln = maxf(p.invuln, 0.5)
	_sweep(w, c, 74.0, 60.0, "eclipse")
	Fx.ring(w.fx_root, c, Color(0.6, 0.28, 1.0, 0.95), 6.0, 90.0, 0.45, 5.0)
	Fx.ring(w.fx_root, c, Color(1.0, 0.85, 0.36, 0.95), 4.0, 64.0, 0.35, 3.0)
	Fx.burst(w.fx_root, c, Color(0.65, 0.35, 1.0), 30, 220.0, 0.6, 40.0, "spark", true, 360.0, Vector2.UP, 2.6)
	Fx.burst(w.fx_root, c, Color(1.0, 0.85, 0.36), 30, 220.0, 0.6, 40.0, "spark", true, 360.0, Vector2.UP, 2.6)
	w.shake(5.0, 0.25)
	w.big_flash(0.25)
	for i in count:
		var pil := MaouPillar.new()
		pil.world = w
		pil.position = Vector2(p.global_position.x + 64.0 + float(i) * spacing, GY)
		pil.delay = 0.07 * float(i)
		pil.flip = (i % 2) == 1
		pil.loud = (i % 3) == 0
		w.ent_root.add_child(pil)


static func _we_screen(w: World, pos: Vector2) -> Vector2:
	return (pos - w.cam.position) * w.cam.zoom.x + Vector2(320.0, 144.0)


const WE_BEATS := [1.0, 2.3, 3.5, 4.6, 5.6, 6.4, 6.75, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0, 15.5, 16.25, 16.47, 16.664, 16.834, 16.984, 17.116, 17.236, 17.356, 17.476, 17.596, 17.716, 17.836, 17.956, 18.076, 18.196, 18.316, 18.436, 18.556, 18.676, 18.796]


static func _we_ts(t: float) -> float:
	if t < WE_IGNITE:
		return 0.36
	if t < WE_BURST:
		return 0.46
	if t < WE_BURST + 0.28:
		return 0.08
	if t < WE_EYE0:
		return 0.5
	if t < WE_PRISM:
		return 0.46
	if t < WE_PRISM_END + 0.6:
		return 0.7
	if t < WE_ASCEND:
		return 0.55
	if t < WE_FALL:
		return 0.8
	if t < WE_IMPACT - 0.5:
		return 0.62
	if t < WE_IMPACT:
		return 0.9
	if t < WE_IMPACT + 0.5:
		return 0.12
	if t < WE_SHATTER:
		return 0.5
	if t < WE_TEXT:
		return 0.7
	return 1.0


static func _worldend(p: Ninja, _delta: float, rd: float, t: float) -> void:
	var w := p.world as World
	var bc := p.pivot.global_position
	var gold := Color(1.0, 0.84, 0.36)
	var viol := Color(0.62, 0.32, 1.0)
	if not p._cine.has("x0"):
		p._cine["x0"] = p.global_position.x
		p._cine["mesh"] = WEMesh.build(11)
	var ix: float = bc.x + WE_DX
	var ground_pt := Vector2(ix, GY - 3.0)
	var sweep_c := Vector2(w.cam_x, GY - 70.0)

	_ts(_we_ts(t))

	# semua efek berpola (detak jantung, taiko, bell, riser, dll.) adalah file MP3 sendiri; jadwal di maou_cues.gd
	var cue_i := p._cine.get("cue_i", 0) as int
	while cue_i < MaouCues.CUES.size() and t >= float(MaouCues.CUES[cue_i][0]) - audio_lead():
		var cu: Array = MaouCues.CUES[cue_i]
		Sfx.play(String(cu[1]), float(cu[3]), float(cu[2]))
		cue_i += 1
	p._cine["cue_i"] = cue_i

	var z := lerpf(1.9, 1.55, smoothstep(0.0, WE_IGNITE, t))
	z = lerpf(z, 1.25, smoothstep(WE_IGNITE, WE_BURST, t))
	z = lerpf(z, 1.05, smoothstep(WE_BURST, WE_EYE1, t))
	w.ult_zoom = z

	var jy := -18.0 * smoothstep(0.3, 3.0, t) - 22.0 * smoothstep(WE_IGNITE, WE_BURST, t) - 14.0 * smoothstep(WE_PILLAR, WE_ASCEND, t)
	jy += sin(t * 2.2) * 2.0 * smoothstep(1.6, 3.0, t)
	# Maou turun ke tanah saat layar tertutup langit malam, supaya pedang menancap tepat di tempatnya berdiri
	jy *= 1.0 - smoothstep(WE_ASCEND + 0.3, WE_ASCEND + 1.0, t)
	if t < WE_IGNITE:
		_pose_charge(p, t)
	else:
		_pose_cast(p, t)

	if _once(p, "begin", true):
		var fp := Vector2(p.global_position.x, GY - 2.0)
		Fx.ring(w.fx_root, fp, Color(0.55, 0.25, 1.0, 0.95), 8.0, 150.0, 0.7, 6.0)
		Fx.ring(w.fx_root, fp, Color(1.0, 0.85, 0.36, 0.95), 5.0, 110.0, 0.55, 4.0)
		Fx.burst(w.fx_root, fp, viol, 50, 240.0, 0.9, 200.0, "spark", true, 70.0, Vector2.UP, 3.0)
		Fx.burst(w.fx_root, fp, gold, 50, 240.0, 0.9, 200.0, "spark", true, 70.0, Vector2.UP, 3.0)

	# --- detak jantung (sinkron dengan musik) : cincin + getar kecil ---
	var beat_i := p._cine.get("beat", 0) as int
	while beat_i < WE_BEATS.size() and t >= float(WE_BEATS[beat_i]):
		var u := float(beat_i) / float(WE_BEATS.size())
		var odd := (beat_i % 2) == 1
		Fx.ring(w.fx_root, bc, (viol if odd else gold) * Color(1, 1, 1, 0.8), 6.0, 70.0 + 70.0 * u, 0.7, 3.0 + 3.0 * u)
		w.shake(0.7 + 5.0 * u, 0.12)
		w.fx_ab = maxf(w.fx_ab, 0.1 + 0.4 * u)
		beat_i += 1
	p._cine["beat"] = beat_i

	# =============== ACT I : HUSH ===============
	if _once(p, "voice_go", t >= 2.4 - audio_lead()):
		Sfx.play_voice("ult_maou_voice", 1.0, 0.0)
	_cue(p, "riser", t, WE_IGNITE - 2.45, "ult_charge_worldend", 0.95, -2.0)

	# =============== ACT II : IGNITE ===============
	_cue(p, "ignite_s", t, WE_IGNITE - 0.35, "ult_maou_ignite", 1.0, 0.0)
	if _once(p, "ignite", t >= WE_IGNITE):
		var hp0 := bc  # ledakan keluar dari tubuh karakter (bukan dari tanah)
		Fx.ring(w.fx_root, hp0, Color(1.0, 0.85, 0.36, 0.95), 10.0, 260.0, 0.8, 8.0)
		Fx.ring(w.fx_root, hp0, Color(0.6, 0.28, 1.0, 0.95), 6.0, 190.0, 0.65, 5.0)
		Fx.burst(w.fx_root, hp0, gold, 70, 280.0, 1.0, 150.0, "spark", true, 60.0, Vector2.UP, 3.2)
		Fx.burst(w.fx_root, hp0, Color(1, 1, 1), 30, 200.0, 0.7, 100.0, "spark", true, 60.0, Vector2.UP, 2.4)
		_sweep(w, sweep_c, 460.0, 320.0, "eclipse")
		w.big_flash(0.6)
		w.shake(9.0, 0.6)
		w.fx_ab = maxf(w.fx_ab, 0.6)
	if t >= WE_IGNITE and t < WE_BURST:
		var iu := (t - WE_IGNITE) / (WE_BURST - WE_IGNITE)
		if int(t * 6.0) != int((t - rd) * 6.0):
			w.shake(1.5 + 8.0 * iu * iu, 0.14)
			Fx.burst(w.fx_root, bc + Vector2(randf_range(-20.0, 20.0), 12.0), gold, 6, 140.0 + 120.0 * iu, 0.8, -40.0, "spark", true, 40.0, Vector2.UP, 2.4)
		p.ult_acc2 += rd
		if p.ult_acc2 >= 1.2:
			p.ult_acc2 = 0.0
			_sweep(w, sweep_c, 480.0, 320.0, "eclipse")
		if int(t * 1.0) != int((t - rd) * 1.0):
			var gx := w.cam_x + randf_range(-260.0, 260.0)
			Fx.burst(w.fx_root, Vector2(gx, GY - 2.0), Color(0.5, 0.42, 0.55, 0.9), 6 + int(iu * 8.0), 80.0 + 80.0 * iu, 0.8, 240.0, "dust", false, 60.0, Vector2.UP, 2.4)

	# =============== ACT III : BURST + MATA ===============
	_cue(p, "shock_s", t, WE_BURST - 0.3, "ult_maou_shock", 1.0, 0.0)
	if _once(p, "burst", t >= WE_BURST):
		for k in 5:
			var rc := gold if k % 2 == 0 else viol
			Fx.ring(w.fx_root, bc, Color(rc.r, rc.g, rc.b, 0.95 - 0.1 * float(k)), 12.0, 280.0 + 130.0 * float(k), 0.6 + 0.12 * float(k), 9.0 - 1.4 * float(k))
		Fx.ring(w.fx_root, bc, Color(1, 1, 1, 0.95), 16.0, 340.0, 0.4, 11.0)
		Fx.burst(w.fx_root, bc, Color(1.0, 0.95, 0.7), 120, 460.0, 1.0, 260.0, "spark", true, 100.0, Vector2.UP, 4.0)
		for k in 6:
			Fx.smoke(w.fx_root, Vector2(ix + randf_range(-220.0, 220.0), GY - 2.0), Color(0.3, 0.2, 0.4, 0.85))
		_sweep(w, sweep_c, 640.0, 340.0, "eclipse")
		w.big_flash(1.0)
		w.shake(32.0, 0.9)
		w.zoom_punch = 0.14
		w.fx_ab = 1.0
	if t >= WE_BURST and t < WE_EYE0 and int(t * 5.0) != int((t - rd) * 5.0):
		w.shake(lerpf(10.0, 3.0, (t - WE_BURST) / (WE_EYE0 - WE_BURST)), 0.14)
	if _once(p, "eye", t >= WE_EYE0):
		Sfx.play("ult_maou_eye", 1.0, -2.0)
		w.shake(5.0, 0.6)
		w.big_flash(0.5)
	if _once(p, "gaze", t >= WE_GLOW):
		var hp := bc + Vector2(2.8, -12.6)
		Fx.ring(w.fx_root, hp, Color(1.0, 0.9, 0.5, 0.95), 3.0, 40.0, 0.5, 3.0)
		Fx.burst(w.fx_root, hp, gold, 20, 150.0, 0.6, 0.0, "spark", true, 360.0, Vector2.UP, 2.4)
		w.big_flash(0.3)
		w.fx_ab = maxf(w.fx_ab, 0.5)
		Sfx.play("skill_ready", 0.6, -2.0)

	# =============== ACT IV : PRISM ===============
	_cue(p, "prism_s", t, WE_PRISM, "ult_maou_prism", 1.0, 0.0)
	if t >= WE_PRISM and t < WE_PRISM_END + 0.6:
		var si := p._cine.get("slash", 0) as int
		while si < 16 and t >= WE_PRISM + float(si) * 0.21 + 0.15:
			w.shake(7.0, 0.12)
			w.fx_ab = maxf(w.fx_ab, 0.55)
			w.big_flash(0.12)
			si += 1
		p._cine["slash"] = si
	if _once(p, "prism_end", t >= WE_PRISM_END):
		w.big_flash(0.9)
		w.shake(12.0, 0.4)
		_sweep(w, sweep_c, 640.0, 340.0, "eclipse")

	# =============== ACT V : HALO ===============
	_cue(p, "halo_s", t, WE_HALO + 0.2, "ult_maou_halo", 1.0, 0.0)
	if _once(p, "pillar", t >= WE_PILLAR):
		Sfx.play("ult_maou_pillar", 1.0, -1.0)
		_sweep(w, sweep_c, 460.0, 320.0, "eclipse")
		Fx.ring(w.fx_root, ground_pt, Color(1.0, 0.85, 0.36, 0.95), 10.0, 240.0, 0.7, 7.0)
		Fx.ring(w.fx_root, ground_pt, Color(0.6, 0.28, 1.0, 0.95), 6.0, 180.0, 0.6, 5.0)
		Fx.ring(w.fx_root, ground_pt, Color(1, 1, 1, 0.9), 4.0, 110.0, 0.4, 3.0)
		Fx.burst(w.fx_root, ground_pt, gold, 60, 260.0, 0.9, 140.0, "spark", true, 40.0, Vector2.UP, 3.0)
		Fx.burst(w.fx_root, ground_pt, viol, 60, 260.0, 0.9, 140.0, "spark", true, 40.0, Vector2.UP, 3.0)
		w.big_flash(0.7)
		w.shake(14.0, 0.7)
		w.fx_ab = maxf(w.fx_ab, 0.7)
	if t >= WE_HALO and t < WE_ASCEND:
		var hu := (t - WE_HALO) / (WE_ASCEND - WE_HALO)
		if int(t * 4.0) != int((t - rd) * 4.0):
			w.shake(1.5 + 5.0 * hu, 0.12)
		if int(t * 0.8) != int((t - rd) * 0.8):
			_sweep(w, sweep_c, 480.0, 320.0, "eclipse")
			Fx.ring(w.fx_root, ground_pt, (gold if int(t) % 2 == 0 else viol) * Color(1, 1, 1, 0.8), 8.0, 200.0, 0.8, 5.0)

	# =============== ACT VI : ASCEND -> LANGIT MALAM ===============
	_cue(p, "suck_s", t, WE_ASCEND - 2.3, "ult_maou_suck", 1.0, -2.0)
	if t >= WE_ASCEND - 2.3 and t < WE_ASCEND:
		var au := (t - (WE_ASCEND - 2.3)) / 2.3
		if int(t * 6.0) != int((t - rd) * 6.0):
			w.shake(2.0 + 10.0 * au * au, 0.12)
		w.fx_ab = maxf(w.fx_ab, 0.15 + 0.5 * au)
	if _once(p, "ascend", t >= WE_ASCEND):
		Sfx.play("ult_maou_hit", 0.8, 0.0)
		w.big_flash(1.0)
		w.shake(16.0, 0.6)
		w.zoom_punch = 0.1
		w.fx_ab = 1.0
		w.fx_tint = Color(0.75, 0.9, 1.2)
		w.fx_raycol = Color(0.35, 0.6, 1.0)
	_cue(p, "cpillar_s", t, WE_CPILLAR - 0.1, "ult_maou_citypillar", 1.0, 0.0)
	_cue(p, "thunder_s", t, WE_BOLT0, "ult_maou_thunder", 1.0, 0.0)
	if t >= WE_BOLT0 and t < WE_BOLT0 + 1.2:
		var bi := p._cine.get("bolt", 0) as int
		var bat := [0.0, 0.2, 0.9]
		while bi < bat.size() and t >= WE_BOLT0 + float(bat[bi]):
			w.shake(12.0 if bi == 0 else 6.0, 0.25)
			w.fx_ab = maxf(w.fx_ab, 0.7 if bi == 0 else 0.4)
			bi += 1
		p._cine["bolt"] = bi
	_cue(p, "summon_s", t, WE_SWORD - 3.4, "ult_maou_summon", 1.0, 0.0)
	if t >= WE_SWORD - 3.4 and t < WE_SWORD and int(t * 5.0) != int((t - rd) * 5.0):
		w.shake(0.8, 0.12)
	if _once(p, "cpillar", t >= WE_CPILLAR):
		w.big_flash(0.35)
		w.shake(5.0, 0.5)

	# =============== ACT VII : SWORD ===============
	if _once(p, "sword", t >= WE_SWORD):
		Sfx.play("ult_maou_hit", 0.7, 0.0)
		w.big_flash(0.5)
		w.shake(10.0, 0.8)
		w.fx_ab = maxf(w.fx_ab, 0.6)
	# denyut cincin asap + percikan listrik di ujung pedang (sinkron dengan ult_maou.gd::_wind_ring)
	for k in 5:
		_cue(p, "wp%d" % k, t, WE_SWORD + 1.0 + float(k) * 2.2 - 0.15, "ult_maou_windpulse", 1.0, -3.0)
	if t >= WE_SWORD and t < WE_FALL and int(t * 3.0) != int((t - rd) * 3.0):
		w.shake(1.2 + 0.4 * (t - WE_SWORD), 0.15)

	# =============== ACT VIII : FALL ===============
	_cue(p, "fall_s", t, WE_FALL, "ult_maou_fall", 1.0, 0.0)
	if t >= WE_FALL and t < WE_CONTACT and int(t * 8.0) != int((t - rd) * 8.0):
		var fu := (t - WE_FALL) / (WE_CONTACT - WE_FALL)
		w.shake(2.0 + 8.0 * fu * fu, 0.12)
	if _once(p, "contact", t >= WE_CONTACT):
		w.big_flash(0.85)
		w.shake(24.0, 1.0)
		w.zoom_punch = 0.1
		w.fx_ab = 1.0
	if t >= WE_CONTACT and t < WE_IMPACT - 0.5:
		var cu := (t - WE_CONTACT) / (WE_IMPACT - 0.5 - WE_CONTACT)
		if int(t * 9.0) != int((t - rd) * 9.0):
			w.shake(lerpf(6.0, 20.0, cu), 0.12)
		if int(t * 3.0) != int((t - rd) * 3.0):
			w.fx_ab = maxf(w.fx_ab, 0.3 + 0.5 * cu)
	if _once(p, "whiteout", t >= WE_IMPACT - 0.5):
		w.big_flash(1.0)
		w.fx_tint = Color(0.92, 0.86, 1.14)
		w.fx_raycol = Color(0.85, 0.55, 1.0)

	# =============== ACT IX : IMPACT ===============
	if _once(p, "impact", t >= WE_IMPACT):
		Sfx.play("ult_maou_impact", 1.0, 0.0)
		Sfx.play("ult_maou_quake", 1.0, -3.0)
		_sweep(w, Vector2(ix, GY - 60.0), 700.0, 320.0, "eclipse")
		for k in 5:
			var rc2 := gold if k % 2 == 0 else viol
			Fx.ring(w.fx_root, ground_pt, Color(rc2.r, rc2.g, rc2.b, 0.95 - 0.1 * float(k)), 12.0, 260.0 + 120.0 * float(k), 0.55 + 0.12 * float(k), 9.0 - 1.4 * float(k))
		Fx.ring(w.fx_root, ground_pt, Color(1, 1, 1, 0.95), 16.0, 330.0, 0.4, 11.0)
		Fx.burst(w.fx_root, ground_pt, Color(1.0, 0.95, 0.7), 140, 480.0, 1.0, 260.0, "spark", true, 100.0, Vector2.UP, 4.0)
		Fx.burst(w.fx_root, ground_pt, viol, 90, 380.0, 1.0, 240.0, "spark", true, 100.0, Vector2.UP, 3.4)
		for k in 6:
			Fx.smoke(w.fx_root, Vector2(ix + randf_range(-200.0, 200.0), GY - 2.0), Color(0.25, 0.15, 0.35, 0.85))
		w.big_flash(1.0)
		w.shake(40.0, 1.1)
		w.zoom_punch = 0.14
		w.fx_ab = 1.0
	if t >= WE_IMPACT and t < WE_SHATTER:
		var u2 := (t - WE_IMPACT) / (WE_SHATTER - WE_IMPACT)
		if int(t * 10.0) != int((t - rd) * 10.0):
			w.shake(lerpf(8.0, 20.0, u2), 0.12)
		if int(t * 6.0) != int((t - rd) * 6.0):
			Fx.burst(w.fx_root, Vector2(ix + randf_range(-260.0, 260.0), GY - 2.0), gold, 8, 200.0, 0.6, 200.0, "spark", true, 120.0, Vector2.UP, 2.6)
	if _once(p, "crack", t >= WE_IMPACT + 0.4):
		Sfx.play("ult_maou_crack", 1.0, -1.0)
	if _once(p, "shatter", t >= WE_SHATTER):
		_worldend_shatter(p, w, ix)
	if _once(p, "end", t >= WE_TEXT):
		Sfx.play("ult_maou_end", 1.0, -1.0)
		w.shake(6.0, 0.5)
	p._cine["jy"] = jy


static func _worldend_shatter(p: Ninja, w: World, ix: float) -> void:
	var tex: ImageTexture = null
	var vp := w.get_viewport()
	if vp != null:
		var vt := vp.get_texture()
		if vt != null:
			var img := vt.get_image()
			if img != null and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
	var fxo := WorldEndFx.new()
	fxo.setup(w, tex, _we_screen(w, Vector2(ix, GY)), w.cam.zoom.x, p._cine["mesh"])
	w.fx_root.add_child(fxo)
	Sfx.play("ult_maou_shatter", 1.0, 0.0)
	Sfx.play("ult_maou_suck", 1.0, -3.0)
	w.big_flash(0.9)
	w.shake(26.0, 0.9)
	w.fx_ab = 1.0
