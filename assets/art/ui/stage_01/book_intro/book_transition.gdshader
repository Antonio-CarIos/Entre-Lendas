shader_type canvas_item;

uniform sampler2D next_texture : source_color;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float glow : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_tex : filter_nearest;
uniform vec4 edge_color : source_color = vec4(0.85, 0.45, 0.1, 1.0);
uniform float edge_width = 0.08;

varying vec4 item_tint;

void vertex() {
	item_tint = COLOR;
}

void fragment() {
	vec4 tex = mix(texture(TEXTURE, UV), texture(next_texture, UV), progress);
	float n = texture(noise_tex, UV).r;

	// A frente do efeito varre o ruído de 0 até 1 (+ largura da borda)
	float threshold = dissolve * (1.0 + edge_width);

	float visivel = step(threshold - edge_width, n);          // 0 = já sumiu
	float na_borda = visivel * (1.0 - step(threshold, n));    // faixa queimada

	vec3 cor = mix(tex.rgb, edge_color.rgb, na_borda);
	cor = mix(cor, vec3(0.96, 0.92, 0.84), glow * 0.4);
	COLOR = vec4(cor, tex.a * visivel) * item_tint;
}
