shader_type canvas_item;

uniform float vignette = 0.5;
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(0.85, 0.9, 1.0, 1.0);
uniform float fade = 0.0;
uniform vec4 fade_color : source_color = vec4(0.8, 0.85, 1.0, 1.0);
uniform float aberration = 0.0;
uniform float damage = 0.0;
uniform float dash = 0.0;
uniform float grain = 0.035;
uniform float sat = 1.05;
uniform vec4 grade : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float scan = 0.06;
uniform float cine = 0.0;
uniform float rays = 0.0;
uniform vec3 cine_tint = vec3(0.78, 0.86, 1.18);
uniform vec3 rays_col = vec3(0.30, 0.55, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 d = uv - 0.5;
	float ab = aberration * (0.004 + dot(d, d) * 0.03) + 0.0002;
	vec3 col;
	col.r = texture(TEXTURE, uv + vec2(ab, 0.0)).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - vec2(ab, 0.0)).b;
	if (dash > 0.01) {
		vec3 acc = col;
		for (int i = 1; i < 6; i++) {
			acc += texture(TEXTURE, uv - d * dash * 0.011 * float(i)).rgb;
		}
		col = acc / 6.0;
		col += vec3(0.05, 0.12, 0.16) * dash * smoothstep(0.2, 0.8, length(d));
	}
	if (rays > 0.01) {
		float ang = atan(d.y, d.x);
		float s1 = pow(abs(sin(ang * 14.0 + TIME * 0.7)), 18.0);
		float s2 = pow(abs(sin(ang * 31.0 - TIME * 1.3)), 30.0);
		float rr = smoothstep(0.08, 0.75, length(d * vec2(1.0, 0.8)));
		col += rays_col * (s1 * 0.22 + s2 * 0.16) * rr * rays;
	}
	col = mix(col, col * cine_tint + vec3(0.0, 0.0, 0.015), cine * 0.7);
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, sat) * grade.rgb;
	float v = 1.0 - smoothstep(0.30, 0.92, length(d * vec2(1.25, 1.0))) * (vignette + cine * 0.35);
	col *= v;
	col = mix(col, vec3(0.95, 0.1, 0.15), damage * 0.7 * smoothstep(0.25, 0.85, length(d)));
	col += flash * flash_color.rgb;

	float sl = 0.5 + 0.5 * sin(UV.y * 288.0 * 3.14159);
	col *= 1.0 - scan * (1.0 - sl);

	float wipe = smoothstep(0.0, 1.0, clamp(fade * 1.6 - uv.x * 0.6, 0.0, 1.0));
	col = mix(col, fade_color.rgb, wipe);

	float bar = 0.075 * cine;
	float edge = (1.0 - smoothstep(bar - 0.004, bar, uv.y)) + smoothstep(1.0 - bar, 1.0 - bar + 0.004, uv.y);
	col = mix(col, vec3(0.0), clamp(edge, 0.0, 1.0));
	float n = fract(sin(dot(uv * vec2(640.0, 288.0) + vec2(TIME * 13.0, TIME * 7.0), vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * grain;
	COLOR = vec4(col, 1.0);
}
