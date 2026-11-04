class_name UITheme
extends RefCounted

const GOLD := Color("#e8b84a")
const INK := Color(0.05, 0.06, 0.16, 0.86)
const PINK := Color("#ff7ab0")

static var _theme: Theme


static func box(bg: Color, border: Color = GOLD, bw: int = 2, radius: int = 10, pad: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad + 6
	s.content_margin_right = pad + 6
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 6
	return s


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 22
	t.set_stylebox("normal", "Button", box(Color(0.12, 0.1, 0.28, 0.92), GOLD.darkened(0.2)))
	t.set_stylebox("hover", "Button", box(Color(0.22, 0.16, 0.42, 0.97), GOLD))
	t.set_stylebox("pressed", "Button", box(Color(0.4, 0.15, 0.3, 1.0), PINK))
	t.set_stylebox("focus", "Button", box(Color(0.22, 0.16, 0.42, 0.97), Color.WHITE, 3))
	t.set_stylebox("disabled", "Button", box(Color(0.1, 0.1, 0.16, 0.8), Color(0.3, 0.3, 0.4)))
	t.set_color("font_color", "Button", Color("#f4ecd8"))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.6))
	t.set_font_size("font_size", "Button", 26)
	t.set_stylebox("panel", "PanelContainer", box(INK, GOLD, 3, 14, 18))
	t.set_color("font_color", "Label", Color("#f4ecd8"))
	t.set_color("font_outline_color", "Label", Color(0.02, 0.02, 0.08))
	t.set_constant("outline_size", "Label", 4)
	_theme = t
	return t


static func label(text: String, size: int = 22, col: Color = Color("#f4ecd8"), align: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align as HorizontalAlignment
	return l


static func button(text: String, min_w: float = 260.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 46)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func(): Sfx.play("click"))
	return b
