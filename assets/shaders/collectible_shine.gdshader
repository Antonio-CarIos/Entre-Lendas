shader_type canvas_item;

uniform vec4 shine_light : source_color = vec4(0.960784, 0.921569, 0.839216, 1.0);
uniform vec4 shine_gold : source_color = vec4(0.878431, 0.658824, 0.274510, 1.0);
uniform float period : hint_range(1.0, 10.0) = 3.5;
uniform float sweep_duration : hint_range(0.1, 1.0) = 0.7;
uniform float band_width : hint_range(0.01, 0.3) = 0.14;

void fragment() {
	vec4 base_color = COLOR;
	if (base_color.a > 0.0) {
		float sweep_time = mod(TIME, period);
		float progress = clamp(sweep_time / sweep_duration, 0.0, 1.0);
		float diagonal = UV.x + UV.y;
		float center = mix(-0.3, 2.3, progress);
		float band = 1.0 - smoothstep(0.0, band_width, abs(diagonal - center));
		band *= 1.0 - step(sweep_duration, sweep_time);
		vec3 shine = mix(shine_gold.rgb, shine_light.rgb, band);
		base_color.rgb = mix(base_color.rgb, shine, band * 0.8);
	}
	COLOR = base_color;
}
