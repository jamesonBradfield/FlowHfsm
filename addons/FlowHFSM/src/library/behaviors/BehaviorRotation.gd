@tool
class_name BehaviorRotation extends FlowBehavior

## Rotates the host or a model child to face the movement direction.

@export var model_node_path: String = "model"
@export var turn_speed: float = 10.0

func update(host: Node, data: Dictionary, delta: float) -> void:
	var move := Vector3.ZERO
	if data.get("input/move_left", false):   move.x -= 1
	if data.get("input/move_right", false):  move.x += 1
	if data.get("input/move_up", false):     move.z -= 1
	if data.get("input/move_down", false):   move.z += 1

	if move.length_squared() < 0.01:
		return

	var target_node: Node3D = host as Node3D
	if model_node_path and host.has_node(model_node_path):
		var ref = host.get_node(model_node_path)
		if ref is Node3D:
			target_node = ref

	if not target_node:
		return

	var target_dir := move.normalized()
	target_dir.y = 0

	if target_dir.length_squared() > 0.001:
		var current := target_node.global_transform.basis
		var target := Basis.looking_at(target_dir, Vector3.UP)
		target_node.global_transform.basis = current.slerp(target, turn_speed * delta)
