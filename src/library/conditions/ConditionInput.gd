@tool
class_name ConditionInput extends FlowCondition

## "The Gatekeeper"
## Checks Global Input for State Transitions.
##
## Reads from context dict (pushed from FlowDataMap):
##   "state_packet" → StatePacket (optional, for puppet mode)
##   "last_actions" → Dictionary (optional, for just-pressed detection)

enum Check { IS_PRESSED, JUST_PRESSED, JUST_RELEASED }

@export_group("Context Keys")
@export var state_packet_key: StringName = &"state_packet"
@export var last_actions_key: StringName = &"last_actions"

@export_group("Settings")
@export var actions: Array[String] = ["ui_accept"]
@export var check: Check = Check.JUST_PRESSED

func _evaluate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
	# 1. Try StatePacket from context (Puppet Mode)
	if context.has(state_packet_key):
		var packet = context[state_packet_key]
		if packet is StatePacket:
			var last_actions: Dictionary = {}
			if context.has(last_actions_key):
				var val = context[last_actions_key]
				if val is Dictionary:
					last_actions = val
			
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
