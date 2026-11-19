class_name BookIntroLetters
extends Control
## Letras desenhadas com a fonte do jogo, sem criar ou recortar novos assets.

@export var font: Font
@export var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()

const WORDS: String = "LENDAS DO BRASIL SACI PERERÊ VENTO"


func _draw() -> void:
	if font == null:
		return
	var alpha: float = sin(clampf(progress, 0.0, 1.0) * PI)
	for index: int in range(WORDS.length()):
		var column: int = index % 16
		var row: int = int(float(index) / 16.0)
		var phase: float = float(index) * 0.7
		var at: Vector2 = Vector2(size.x * 0.5 - 112.0 + float(column) * 14.0,
			size.y * 0.35 + float(row) * 22.0)
		at += Vector2(sin(phase + progress * 3.0) * progress * 32.0,
			progress * size.y * (0.35 + float(index % 5) * 0.08))
		draw_string(font, at, WORDS[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color(0.96, 0.92, 0.84, alpha))
