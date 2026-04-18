@tool
class_name ConditionAnimationFinished extends FlowCondition

## Checks if the current animation in the linked AnimationTree has finished.
## Reads "animation_tree" from context.

@export_group("Context Keys")
@export var animation_tree_key: StringName = &"animation_tree"

@export_group("Settings")
@export var state_machine_path: String = "parameters/playback"
@export var end_margin: float = 0.1

func _evaluate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
	var anim_tree: AnimationTree = null
	
	if context.has(animation_tree_key):
		var val = context[animation_tree_key]
		if val is AnimationTree:
			anim_tree = val
	
	if not anim_tree:
		return true # Fail safe
	
	var playback: Variant = anim_tree.get(state_machine_path)
	if playback and playback is AnimationNodeStateMachinePlayback:
		if not playback.is_playing():
			return true
		var current_pos: float = playback.get_current_play_position()
		var length: float = playback.get_current_length()
		return current_pos >= (length - end_margin)
		
	return true
