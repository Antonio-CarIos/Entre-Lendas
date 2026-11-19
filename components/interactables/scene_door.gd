class_name SceneDoor
extends Area2D
## Dados da porta; o HUD confirma e o mapa solicita a transição.

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &"PlayerEntrySpawn"
@export_multiline var question: String = "Deseja sair e ir para o quintal?"
## Opcional: o controlador do mapa valida/realiza a viagem ao concluir o roteiro.
@export var narrative: Stage01Narrative
@export var entry_id: StringName = &""
