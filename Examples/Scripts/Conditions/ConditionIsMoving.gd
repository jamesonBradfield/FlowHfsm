class_name ConditionIsMoving extends StateCondition

## Checks if the character is moving.
## Returns true if input_direction in blackboard has magnitude > threshold.

@export_group("Threshold Settings")
## Minimum input magnitude to consider as "moving".
@export var input_threshold: float = 0.1
## Blackboard key to check for movement direction.
@export var blackboard_key: String = "input_direction"

func _evaluate(actor: Node) -> bool:
	var move_dir: Vector3 = Vector3.ZERO
	
	# Try to find controller or property on actor
	var controller = actor.get_node_or_null("PlayerController")
	if controller:
		move_dir = controller.get("input_direction")
	elif "input_direction" in actor:
		move_dir = actor.input_direction
		
	return move_dir.length() > input_threshold
