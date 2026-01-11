@tool
class_name BehaviorAnimationPlayer extends StateBehavior

## Plays an animation on an AnimationPlayer when the state is entered.

@export var animation_name: String = ""
@export var fade_time: float = -1.0
@export var custom_speed: float = 1.0
@export var from_end: bool = false

## Optional: Path to the AnimationPlayer. If empty, searches in Actor.
@export var animation_player_path: String = "AnimationPlayer"

func enter(node: Node, actor: Node, _blackboard: Blackboard) -> void:
	if animation_name.is_empty():
		return
		
	var anim_player: AnimationPlayer = _find_animation_player(actor)
	if anim_player:
		anim_player.play(animation_name, fade_time, custom_speed, from_end)
	else:
		push_warning("BehaviorAnimationPlayer: AnimationPlayer not found on %s" % actor.name)

func _find_animation_player(actor: Node) -> AnimationPlayer:
	# 1. Try explicit path
	var p = actor.get_node_or_null(animation_player_path)
	if p and p is AnimationPlayer:
		return p
		
	# 2. Try implicit direct child
	p = actor.get_node_or_null("AnimationPlayer")
	if p and p is AnimationPlayer:
		return p
		
	# 3. Search children
	for child in actor.get_children():
		if child is AnimationPlayer:
			return child
			
	return null
