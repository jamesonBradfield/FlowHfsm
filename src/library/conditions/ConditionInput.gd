@tool
class_name ConditionInput extends FlowCondition

## "The Gatekeeper"
## Checks Global Input for State Transitions.

@export_group("Dependency Injection")
@export var state_packet_binding: FlowBinding
@export var last_actions_binding: FlowBinding

func _init() -> void:
	if not state_packet_binding:
		state_packet_binding = FlowBinding.new()
		state_packet_binding.path = ^":state_packet"
	if not last_actions_binding:
		last_actions_binding = FlowBinding.new()
		last_actions_binding.path = ^":last_actions"

@export_group("Settings")
enum Check { IS_PRESSED, JUST_PRESSED, JUST_RELEASED }
@export var actions: Array[String] = ["ui_accept"]
@export var check: Check = Check.JUST_PRESSED

func _evaluate(actor: Node) -> bool:
	# 1. Try to use StatePacket from FlowCharacter if it exists
	var packet: StatePacket = null
	if state_packet_binding:
		var val = state_packet_binding.get_value(actor)
		if val is StatePacket:
			packet = val
			
	if packet:
		var last_actions: Dictionary = {}
		if last_actions_binding:
			var val = last_actions_binding.get_value(actor)
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
