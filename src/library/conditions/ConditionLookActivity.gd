@tool
class_name ConditionLookActivity extends FlowCondition

## Checks if there is any activity on the look vector.
## Reads "state_packet" from context.

@export_group("Context Keys")
@export var state_packet_key: StringName = &"state_packet"

@export_group("Settings")
@export var threshold: float = 0.01

func _evaluate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
	if context.has(state_packet_key):
		var packet = context[state_packet_key]
		if packet is StatePacket:
			return packet.look_vec.length_squared() > (threshold * threshold)
	return false
