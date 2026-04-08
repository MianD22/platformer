extends Area2D
class_name CameraZoneArea2D

@export var zoom: Vector2 = Vector2.ONE

@export var follow_player: bool = false
@export var fixed_position: Vector2 = Vector2.ZERO

@export var limit_camera: bool = false
@export var limit_left: float = -10000
@export var limit_top: float = -10000
@export var limit_right: float = 10000
@export var limit_bottom: float = 10000

var collisionshape: CollisionShape2D
var cam_node: Camera2D

func _ready() -> void:
	collisionshape = get_child(0)
	monitorable = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if !cam_node:
			cam_node = get_tree().get_first_node_in_group("RoomZoneCamera")
		if !cam_node:
			print("[CameraZone] ERROR: cam_node not found in group 'RoomZoneCamera'!")
			return
		print("[CameraZone] Player entered zone: ", name)
		cam_node.overlapping_zones.append(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if !cam_node:
			cam_node = get_tree().get_first_node_in_group("RoomZoneCamera")
		if !cam_node:
			return
		print("[CameraZone] Player exited zone: ", name)
		cam_node.overlapping_zones.erase(self)
