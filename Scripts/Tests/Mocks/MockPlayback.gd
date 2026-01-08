extends Node
class_name MockPlayback

## Mock for AnimationNodeStateMachinePlayback

var current_node: StringName = ""
var traveling_to: StringName = ""

func travel(to_node: StringName, reset_on_teleport: bool = true) -> void:
	traveling_to = to_node
	current_node = to_node

func get_current_node() -> StringName:
	return current_node

func get_travel_path() -> Array[StringName]:
	return []

func is_playing() -> bool:
	return true

func get_current_play_position() -> float:
	return 0.0

func get_current_length() -> float:
	return 1.0
