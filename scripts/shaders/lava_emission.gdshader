shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.98, 0.38, 0.08);
uniform vec3 hot_color  : source_color = vec3(1.0, 0.86, 0.24);
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.35;
uniform float noise_scale  : hint_range(0.1, 8.0) = 3.2;
uniform float emission_strength : hint_range(0.0, 8.0) = 3.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 flow_uv = UV * noise_scale + vec2(TIME * scroll_speed, TIME * scroll_speed * 0.5);
	float n = noise(flow_uv);
	float hotspot = smoothstep(0.35, 0.85, n);
	vec3 col = mix(base_color, hot_color, hotspot);
	ALBEDO = col;
	EMISSION = col * emission_strength * (0.6 + hotspot * 0.7);
	ROUGHNESS = 0.8;
	METALLIC = 0.0;
}
