@tool
class_name BehaviorAnimationTree extends StateBehavior

## Travels to a state in an AnimationTree StateMachine when entered.

@export var target_state_name: String = ""
## If empty, uses 'parameters/playback'.
@export var playback_path: String = "parameters/playback"
## Optional: Path to the AnimationTree. If empty, searches in Actor.
@export var animation_tree_path: String = "AnimationTree"

func enter(node: Node, actor: Node, _blackboard: Blackboard) -> void:
	var tree: AnimationTree = _find_animation_tree(actor)
	if not tree:
		push_warning("BehaviorAnimationTree: AnimationTree not found on %s" % actor.name)
		return
		
	if not tree.active:
		tree.active = true
		
	var playback = tree.get(playback_path)
	if playback and (playback is AnimationNodeStateMachinePlayback or playback.has_method("travel")):
		var state_name = target_state_name
		if state_name.is_empty():
			# Default to the name of the State Node using this behavior
			state_name = node.name
			
		playback.travel(state_name)
	else:
		push_warning("BehaviorAnimationTree: Playback not found at '%s'" % playback_path)

func _find_animation_tree(actor: Node) -> AnimationTree:
	# 1. Try explicit path
	var t = actor.get_node_or_null(animation_tree_path)
	if t and t is AnimationTree:
		return t
		
	# 2. Try implicit direct child
	t = actor.get_node_or_null("AnimationTree")
	if t and t is AnimationTree:
		return t
		
	# 3. Search children
	for child in actor.get_children():
		if child is AnimationTree:
			return child
			
	return null
