class_name ConditionInput extends StateCondition

## Checks if a specific input action is pressed.

## The name of the input action (defined in Input Map).
@export var action_name: String = "ui_accept"
## If true, checks if the button is pressed. If false, checks if it is released.
@export var required_state: bool = true
## If true, uses is_action_just_pressed/released instead of continuous check.
## CRITICAL: Use this for Jumps to prevent "bunny hopping" or re-entry issues.
@export var just_changed: bool = false

func _evaluate(_actor: Node, blackboard: Dictionary) -> bool:
	# Note: Blackboard inputs are usually booleans (is_pressed). 
	# They don't capture "just_pressed" unless the controller explicitly handles it.
	# For "Just Changed" logic, we strongly prefer direct Input singleton checks 
	# to ensure frame-perfect accuracy.
	
	if just_changed:
		if required_state:
			return Input.is_action_just_pressed(action_name)
		else:
			return Input.is_action_just_released(action_name)
	
	# Fallback to direct Input check if not in blackboard (robustness)
	if blackboard.has("inputs") and blackboard["inputs"].has(action_name):
		return blackboard["inputs"][action_name] == required_state
		
	# Direct Input check (if blackboard isn't fully set up or we want real-time)
	if required_state:
		return Input.is_action_pressed(action_name)
	else:
		return not Input.is_action_pressed(action_name)
