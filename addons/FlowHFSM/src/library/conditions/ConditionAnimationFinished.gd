class_name ConditionAnimationFinished extends FlowCondition

## Checks if the current animation in the linked AnimationTree has finished.
## Useful for "Blocking" states like Attacks or Interactions.

@export var state_machine_path: String = "parameters/playback"
@export var end_margin: float = 0.1 # Seconds before end to consider finished

func _evaluate(actor: Node) -> bool:
	var anim_tree: AnimationTree = null
	
	# Try to find AnimationTree on actor
	if actor.has_node("AnimationTree"):
		anim_tree = actor.get_node("AnimationTree")
	else:
		# Search children
		for child in actor.get_children():
			if child is AnimationTree:
				anim_tree = child
				break
	
	if not anim_tree:
		return true # Fail safe
	
	var playback: Variant = anim_tree.get(state_machine_path)
	if playback and playback is AnimationNodeStateMachinePlayback:
		# Check if playing
		if not playback.is_playing():
			return true
			
		var current_pos: float = playback.get_current_play_position()
		var length: float = playback.get_current_length()
		
		return current_pos >= (length - end_margin)
		
	return true # Default to finished if something is wrong
