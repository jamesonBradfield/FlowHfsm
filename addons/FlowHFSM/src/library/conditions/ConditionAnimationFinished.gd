@tool
class_name ConditionAnimationFinished extends FlowCondition

## Checks if the current animation has finished.

@export var state_machine_path: String = "parameters/playback"
@export var end_margin: float = 0.1

func evaluate(host: Node, _data: Dictionary) -> bool:
	var anim_tree: AnimationTree = null

	if host.has_node("AnimationTree"):
		anim_tree = host.get_node("AnimationTree")
	else:
		for child in host.get_children():
			if child is AnimationTree:
				anim_tree = child
				break

	if not anim_tree:
		return true

	var playback: Variant = anim_tree.get(state_machine_path)
	if playback and playback is AnimationNodeStateMachinePlayback:
		if not playback.is_playing():
			return true
		var pos: float = playback.get_current_play_position()
		var length: float = playback.get_current_length()
		return pos >= (length - end_margin)

	return true
