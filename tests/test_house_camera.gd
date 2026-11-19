extends GutTest
## Confere o enquadramento real da câmera, inclusive nas bordas e ao redimensionar.

const HOUSE: PackedScene = preload("res://stages/stage_01_saci/house_interior.tscn")

var _viewport: SubViewport
var _house: Node2D
var _player: Player


func before_each() -> void:
	WorldState.reset()
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(640, 360)
	_viewport.world_2d = World2D.new()
	add_child_autofree(_viewport)
	_house = HOUSE.instantiate() as Node2D
	_viewport.add_child(_house)
	_player = _house.get_node("YSortRoot/Player") as Player
	_player.set_movement_enabled(false)


func after_each() -> void:
	WorldState.reset()


func test_player_camera_is_the_only_enabled_camera_in_the_house() -> void:
	assert_eq(_viewport.get_camera_2d(), _player.camera)
	assert_false((_house.get_node("Camera2D") as Camera2D).enabled)
	assert_false(_player.camera.position_smoothing_enabled)
	assert_eq(_player.camera.zoom, Vector2.ONE)
	var floor_layer: TileMapLayer = _house.get_node("FloorLayer") as TileMapLayer
	var cells: Rect2i = floor_layer.get_used_rect()
	var size: Vector2i = floor_layer.tile_set.tile_size
	assert_eq(_room_bounds(), Rect2(Vector2(cells.position * size), Vector2(cells.size * size)))
	_player.camera.force_update_scroll()
	_assert_frame_inside_the_room()


func test_camera_stops_at_each_edge_and_follows_inside_the_room() -> void:
	for point: Vector2 in [Vector2(-32, 224), Vector2(672, 224), Vector2(-32, 672), Vector2(672, 672)]:
		_player.position = point
		_player.camera.force_update_scroll()
		_assert_frame_inside_the_room()
	_player.position = Vector2(300, 440)
	_player.camera.force_update_scroll()
	var first_center: Vector2 = _player.camera.get_screen_center_position()
	_player.position = Vector2(340, 480)
	_player.camera.force_update_scroll()
	assert_eq(_player.camera.get_screen_center_position() - first_center, Vector2(40, 40))
	_player.position = Vector2(640, 640)
	_player.camera.force_update_scroll()
	var edge_center: Vector2 = _player.camera.get_screen_center_position()
	_player.position += Vector2(100, 100)
	_player.camera.force_update_scroll()
	assert_eq(_player.camera.get_screen_center_position(), edge_center)


func test_resizing_never_exposes_the_outside_or_stretches_the_art() -> void:
	for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 540), Vector2i(360, 640), Vector2i(640, 360)]:
		_viewport.size = viewport_size
		await wait_process_frames(2)
		assert_eq(_player.camera.zoom.x, _player.camera.zoom.y)
		assert_eq(_player.camera.zoom.x, ceilf(_player.camera.zoom.x))
		for point: Vector2 in [Vector2(36, 392), Vector2(496, 608), Vector2(320, 440)]:
			_player.position = point
			_player.camera.force_update_scroll()
			_assert_frame_inside_the_room()
	assert_eq(_player.camera.zoom, Vector2.ONE, "A janela original recupera a escala 1:1.")


func test_both_arrivals_are_framed_immediately_before_the_fade_reveals_them() -> void:
	for spawn_name: String in ["FromBedroom", "FromBackyard"]:
		var spawn: Marker2D = _house.get_node("SpawnPoints/" + spawn_name) as Marker2D
		_player.global_position = spawn.global_position
		# Mesmas chamadas usadas pelo serviço de transição sob a tela preta.
		_player.camera.reset_smoothing()
		_player.camera.force_update_scroll()
		_assert_frame_inside_the_room()
		assert_true(_visible_bounds().has_point(spawn.global_position))


func test_empty_map_cutouts_have_an_opaque_dark_backdrop_behind_the_tiles() -> void:
	var backdrop: Polygon2D = _house.get_node("OutsideDarkness") as Polygon2D
	var floor_layer: TileMapLayer = _house.get_node("FloorLayer") as TileMapLayer
	assert_true(backdrop.visible)
	assert_eq(backdrop.color.a, 1.0)
	assert_lt(backdrop.color.get_luminance(), 0.1)
	assert_lt(backdrop.get_index(), floor_layer.get_index())
	for point: Vector2 in [Vector2(-31, 225), Vector2(671, 225), Vector2(-31, 671), Vector2(671, 671)]:
		assert_true(Geometry2D.is_point_in_polygon(point, backdrop.polygon))


func _room_bounds() -> Rect2:
	var camera: Camera2D = _player.camera
	return Rect2(camera.limit_left, camera.limit_top,
		camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)


func _visible_bounds() -> Rect2:
	return _viewport.canvas_transform.affine_inverse() * Rect2(Vector2.ZERO, Vector2(_viewport.size))


func _assert_frame_inside_the_room() -> void:
	assert_true(_room_bounds().grow(0.01).encloses(_visible_bounds()),
		"Enquadramento %s dentro do mapa %s." % [_visible_bounds(), _room_bounds()])
