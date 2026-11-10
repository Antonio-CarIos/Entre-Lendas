shader_type canvas_item;

uniform sampler2D next_texture; // A imagem da próxima página
uniform sampler2D noise_texture; // A textura que cria o formato do rasgo
uniform float progress : hint_range(0.0, 1.0) = 0.0; // O controle da animação

void fragment() {
	vec4 current_color = texture(TEXTURE, UV);
	vec4 next_color = texture(next_texture, UV);
	
	// Pega o valor do ruído (vai de 0.0 a 1.0 dependendo da área da imagem)
	float noise_val = texture(noise_texture, UV).r;
	
	// Se a nossa animação passou do valor do ruído, mostra a próxima página
	if (progress > noise_val) {
		COLOR = next_color;
	} else {
		COLOR = current_color;
	}
}