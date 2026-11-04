class_name Water
extends ColorRect

const SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform vec4 c_top : source_color = vec4(0.1,0.2,0.5,1.0);
uniform vec4 c_bot : source_color = vec4(0.02,0.05,0.2,1.0);
uniform vec4 shine : source_color = vec4(0.7,0.8,1.0,1.0);
varying vec2 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	float t = UV.y;
	vec3 col = mix(c_top.rgb, c_bot.rgb, clamp(t * 1.4, 0.0, 1.0));
	float w1 = sin(wpos.x * 0.22 + TIME * 2.2 + t * 14.0) * 0.5 + 0.5;
	float w2 = sin(wpos.x * 0.09 - TIME * 1.3 + t * 7.0) * 0.5 + 0.5;
	col += step(0.82, w1 * w2 + 0.1) * (1.0 - t) * 0.30 * shine.rgb;
	col += step(t, 0.05) * 0.35 * (0.6 + 0.4 * sin(wpos.x * 0.5 + TIME * 4.0));
	COLOR = vec4(col, 1.0);
}
"""

static var _shader: Shader


func setup(x0: float, x1: float, theme: Dictionary) -> void:
	position = Vector2(x0, Ground.GROUND_Y + 2.0)
	size = Vector2(x1 - x0, 80.0)
	z_index = -4
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	var w: Array = theme["water"]
	m.set_shader_parameter("c_top", w[1])
	m.set_shader_parameter("c_bot", w[0])
	m.set_shader_parameter("shine", (theme["moon"]["glow"] as Color).lightened(0.4))
	material = m

	for side in 2:
		var cliff := ColorRect.new()
		cliff.color = Color(0.03, 0.03, 0.1, 0.85)
		if theme.get("day", false):
			cliff.color = (w[0] as Color).darkened(0.55)
		cliff.size = Vector2(5, 80)
		cliff.position = Vector2(-1 if side == 0 else size.x - 4, -2)
		add_child(cliff)
