
extends Control

# ==========================================
# IMAGENS
# ==========================================

@export var imagens_do_livro: Array[Texture2D]

@export_file("*.tscn") var proxima_cena: String = ""

# ==========================================
# NÓS
# ==========================================

@onready var desfoque = $Desfoque
@onready var livro = $Livro
@onready var tela_preta = $TelaPreta

# ==========================================
# VARIÁVEIS
# ==========================================

var clique_atual: int = -1
var rasgo_atual: int = -1

var trocando_pagina: bool = false
var encerrando: bool = false
var etapa_rasgo: bool = false


# ==========================================
# INICIALIZAÇÃO
# ==========================================

func _ready():

	desfoque.modulate.a = 0.0
	livro.modulate.a = 0.0
	tela_preta.modulate.a = 0.0

	# Garante que a tela preta fique na frente
	tela_preta.z_index = 100

	if livro.material is ShaderMaterial:
		livro.material.set_shader_parameter("progress", 0.0)


# ==========================================
# DETECTAR CLIQUES
# ==========================================

func _input(event):

	if trocando_pagina or encerrando:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			avancar_animacao()


# ==========================================
# CONTROLE DA SEQUÊNCIA
# ==========================================

func avancar_animacao():

	if encerrando or trocando_pagina:
		return

	# PRIMEIRO CLIQUE: MOSTRA O LIVRO
	if clique_atual == -1:

		if imagens_do_livro.is_empty():
			return

		clique_atual = 0
		livro.texture = imagens_do_livro[0]

		trocando_pagina = true

		var tween = create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			desfoque, "modulate:a", 1.0, 0.3
		)

		tween.tween_property(
			livro, "modulate:a", 1.0, 0.3
		)

		tween.chain().tween_callback(func():
			trocando_pagina = false
		)

		return

	# PÁGINAS NORMAIS DO LIVRO
	if not etapa_rasgo:

		if clique_atual < imagens_do_livro.size() - 1:

			clique_atual += 1
			virar_pagina(imagens_do_livro[clique_atual])
			return

		# Terminou o livro: começa a sequência de rasgos
		etapa_rasgo = true

		# ACABARAM TODAS AS IMAGENS: TELA PRETA
		escurecer_tela()


# ==========================================
# ANIMAÇÃO DAS PÁGINAS
# ==========================================

func virar_pagina(proxima_imagem: Texture2D):

	if not livro.material is ShaderMaterial:
		push_error("O Livro precisa possuir um ShaderMaterial.")
		return

	trocando_pagina = true

	var material_livro: ShaderMaterial = livro.material

	material_livro.set_shader_parameter(
		"next_texture", proxima_imagem
	)

	material_livro.set_shader_parameter(
		"progress", 0.0
	)

	var tween = create_tween()

	tween.tween_property(
		material_livro,
		"shader_parameter/progress",
		1.0,
		0.3
	)

	tween.tween_callback(func():

		livro.texture = proxima_imagem

		material_livro.set_shader_parameter(
			"progress", 0.0
		)

		trocando_pagina = false
	)


# ==========================================
# TELA PRETA
# ==========================================

func escurecer_tela():

	if encerrando:
		return

	encerrando = true
	trocando_pagina = true

	# Garante que o ColorRect esteja visível
	tela_preta.visible = true
	tela_preta.color = Color.BLACK
	tela_preta.modulate.a = 0.0

	var tween = create_tween()

	# Faz o livro desaparecer
	tween.set_parallel(true)

	tween.tween_property(
		livro,
		"modulate:a",
		0.0,
		0.5
	)

	# Deixa a tela completamente preta
	tween.tween_property(
		tela_preta,
		"modulate:a",
		1.0,
		1.0
	)

	tween.chain().tween_callback(func():

		print("TELA PRETA - FIM DO TUTORIAL")

		if proxima_cena != "":
			get_tree().change_scene_to_file(proxima_cena)
	)
