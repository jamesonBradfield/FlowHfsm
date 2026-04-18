@tool
class_name ConditionAnimationFinished extends FlowCondition

## Checks if the current animation in the linked AnimationTree has finished.
## Useful for "Blocking" states like Attacks or Interactions.

@export_group("Dependency Injection")
@export var animation_tree_binding: FlowBinding

func _init() -> void:
	if not animation_tree_binding:
		animation_tree_binding = FlowBinding.new()
		animation_tree_binding.path = ^"AnimationTree"

@export_group("Settings")
@export var state_machine_path: String = "parameters/playback"
@export var end_margin: float = 0.1 # Seconds before end to consider finished

func _evaluate(actor: Node) -> bool:
	var anim_tree: AnimationTree = null
	
	if animation_tree_binding:
		var val = animation_tree_binding.get_value(actor)
		if val is AnimationTree:
			anim_tree = val
	
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
