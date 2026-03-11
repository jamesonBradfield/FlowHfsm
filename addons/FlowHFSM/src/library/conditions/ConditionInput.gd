@tool
class_name ConditionInput extends FlowCondition

## "The Gatekeeper"
## Checks Global Input for State Transitions.

enum Check { IS_PRESSED, JUST_PRESSED, JUST_RELEASED }
@export var actions: Array[String] = ["ui_accept"]
@export var check: Check = Check.JUST_PRESSED

func _evaluate(actor: Node) -> bool:
	# 1. Try to use StatePacket from FlowCharacter if it exists
	if "state_packet" in actor and actor.state_packet:
		var packet: StatePacket = actor.state_packet
		var last_actions: Dictionary = actor.get("last_actions") if "last_actions" in actor else {}
		
		for action in actions:
			var action_name = StringName(action)
			var is_pressed: bool = packet.actions.get(action_name, false)
			var was_pressed: bool = last_actions.get(action_name, false)
			
			match check:
				Check.IS_PRESSED:
					if is_pressed: return true
				Check.JUST_PRESSED:
					if is_pressed and not was_pressed: return true
				Check.JUST_RELEASED:
					if not is_pressed and was_pressed: return true
		return false

	# 2. Fallback to Global Input (Non-Puppet Mode)
	for action in actions:
		match check:
			Check.IS_PRESSED:
				if Input.is_action_pressed(action): return true
			Check.JUST_PRESSED:
				if Input.is_action_just_pressed(action): return true
			Check.JUST_RELEASED:
				if Input.is_action_just_released(action): return true
	return false
