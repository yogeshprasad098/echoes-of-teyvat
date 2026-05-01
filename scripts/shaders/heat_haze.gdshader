shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.008;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.4;
uniform float web_fallback_strength : hint_range(0.0, 0.2) = 0.03;

void fragment() {
	vec2 sample_uv = SCREEN_UV;
#ifdef WEB_BUILD
	float wave = sin(UV.y * 24.0 + TIME * scroll_speed) * web_fallback_strength;
	COLOR = texture(TEXTURE, UV + vec2(wave, 0.0));
#else
	float dx = sin(sample_uv.y * 18.0 + TIME * scroll_speed) * distortion_strength;
	float dy = cos(sample_uv.x * 12.0 + TIME * scroll_speed * 0.6) * distortion_strength * 0.5;
	vec2 distorted = sample_uv + vec2(dx, dy);
	vec4 screen_col = texture(SCREEN_TEXTURE, distorted);
	COLOR = mix(texture(TEXTURE, UV), screen_col, 0.75);
#endif
}
