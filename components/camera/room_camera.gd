extends Camera2D
## Limita o enquadramento ao piso e preserva a escala uniforme da pixel art.

@export_node_path("TileMapLayer") var floor_layer_path: NodePath
@export_range(1.0, 8.0, 1.0) var minimum_zoom: float = 1.0


func _ready() -> void:
	var floor_layer: TileMapLayer = get_node(floor_layer_path) as TileMapLayer
	var cells: Rect2i = floor_layer.get_used_rect()
	var tile_size: Vector2i = floor_layer.tile_set.tile_size
	var bounds: Rect2 = floor_layer.global_transform * Rect2(
		Vector2(cells.position * tile_size), Vector2(cells.size * tile_size)
	)
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
	get_viewport().size_changed.connect(_fit_viewport)
	_fit_viewport()


func _fit_viewport() -> void:
	var room_size: Vector2 = Vector2(limit_right - limit_left, limit_bottom - limit_top)
	var viewport_size: Vector2 = get_viewport_rect().size
	# Se a janela ultrapassar o cômodo, aproxima em passos inteiros, sem distorção.
	var required_zoom: float = maxf(viewport_size.x / room_size.x, viewport_size.y / room_size.y)
	var scale_factor: float = maxf(minimum_zoom, ceilf(required_zoom))
	zoom = Vector2.ONE * scale_factor
	reset_smoothing()
	force_update_scroll()
