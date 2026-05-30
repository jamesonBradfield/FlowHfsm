@tool
class_name BehaviorPhysics extends FlowBehavior

## Applies movement velocity to the host character.

@export var speed_key: String = "speed"
@export var velocity_key: String = "velocity"

func update(host: Node, data: Dictionary, _delta: float) -> void:
	var speed: float = data.get(speed_key, 5.0)
	var move := Vector3.ZERO

	if data.get("input/move_left", false):   move.x -= 1
	if data.get("input/move_right", false):  move.x += 1
	if data.get("input/move_up", false):     move.z -= 1
	if data.get("input/move_down", false):   move.z += 1

	if move.length_squared() > 0.01:
		move = move.normalized() * speed

	data[velocity_key] = move

	if host is CharacterBody3D:
		host.velocity = move
		host.move_and_slide()
		data["on_floor"] = host.is_on_floor()
