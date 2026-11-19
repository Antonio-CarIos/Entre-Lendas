class_name ThresholdDoor
extends SceneDoor
## Pede confirmação uma vez por entrada; cancelar exige sair da área para rearmar.

signal confirmation_requested(door: SceneDoor, traveler: Player)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var traveler: Player = body as Player
		# A chegada sob o fade não dispara uma nova viagem.
		if traveler.movement_enabled:
			confirmation_requested.emit(self, traveler)
