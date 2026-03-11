@tool
class_name ConditionLookActivity extends FlowCondition

## Checks if there is any activity on the look vector.
## Useful for transitioning to "Aiming" or "Observing" states.

@export var threshold: float = 0.01

func _evaluate(actor: Node) -> bool:
	if "state_packet" in actor and actor.state_packet:
		return actor.state_packet.look_vec.length_squared() > (threshold * threshold)
	
	# Fallback: In non-packet mode, look activity is harder to track globally 
	# without a specific look input setup, so we return false.
	return false
