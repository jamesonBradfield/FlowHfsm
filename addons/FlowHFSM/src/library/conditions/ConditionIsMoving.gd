class_name ConditionIsMoving extends FlowCondition

## Checks if the character is moving.
## Checks "is_moving" property (bool) or "move_input" (Vector3) magnitude.

@export_group("Threshold Settings")
## Minimum input magnitude to consider as "moving".
@export var input_threshold: float = 0.1

func _evaluate(actor: Node) -> bool:
	# 1. Check explicit flag
	if "is_moving" in actor:
		if actor.is_moving: return true
		# If false, check vector just in case? No, trust the flag if it exists.
		# But wait, maybe the flag is not set but velocity is?
		# The prompt implies "Input Condition", so usually it's about input.
	
	# 2. Check Input Vector
	var move_dir: Vector3 = Vector3.ZERO
	if "move_input" in actor:
		move_dir = actor.move_input
	elif "input_direction" in actor: # Backward compat
		move_dir = actor.input_direction
		
	return move_dir.length_squared() > (input_threshold * input_threshold)
