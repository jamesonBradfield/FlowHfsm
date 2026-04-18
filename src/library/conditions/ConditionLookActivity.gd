@tool
class_name ConditionLookActivity extends FlowCondition

## Checks if there is any activity on the look vector.
## Useful for transitioning to "Aiming" or "Observing" states.

@export_group("Dependency Injection")
@export var state_packet_binding: FlowBinding

func _init() -> void:
	if not state_packet_binding:
		state_packet_binding = FlowBinding.new()
		state_packet_binding.path = ^":state_packet"

@export_group("Settings")
@export var threshold: float = 0.01

func _evaluate(actor: Node) -> bool:
	if state_packet_binding:
		var packet = state_packet_binding.get_value(actor)
		if packet is StatePacket:
			return packet.look_vec.length_squared() > (threshold * threshold)
	
	# Fallback: In non-packet mode, look activity is harder to track globally 
	# without a specific look input setup, so we return false.
	return false
