class_name BehaviorImpulse extends StateBehavior

## Applies an instantaneous force to the character.
## Useful for jumping, dashing, knockback, etc.

@export_group("Impulse Settings")
## The impulse vector to apply (in world space).
@export var impulse: Vector3 = Vector3.UP
## If true, the impulse is applied in the actor's local space instead of world space.
@export var is_local_space: bool = false
## Delay before applying the impulse (in seconds).
@export var delay: float = 0.0

func enter(node: Node, actor: Node, blackboard: Blackboard) -> void:
	# Check if we need to delay the impulse
	if delay > 0.0:
		# Store timer in node memory
		node.memory["impulse_timer"] = delay
		return

	# Apply impulse immediately
	_apply_impulse(actor, blackboard)

func update(node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:
	# Handle delayed impulse
	if node.memory.has("impulse_timer"):
		var timer: float = node.memory["impulse_timer"]
		timer -= delta

		if timer <= 0.0:
			# Delay is over, apply impulse
			_apply_impulse(actor, blackboard)
			node.memory.erase("impulse_timer")
		else:
			# Still waiting
			node.memory["impulse_timer"] = timer

func _apply_impulse(actor: Node, blackboard: Blackboard = null) -> void:
	var body: CharacterBody3D = actor as CharacterBody3D
	if not body:
		push_warning("BehaviorImpulse: Actor is not a CharacterBody3D")
		return

	var final_impulse: Vector3 = impulse
	
	# Harvest Pattern Override
	if blackboard and blackboard.has_value("jump_impulse"):
		var override_val = blackboard.get_value("jump_impulse")
		if override_val is float or override_val is int:
			# If float, assume it's the Y magnitude or strict vertical impulse
			# For now, let's keep the direction of 'impulse' but override magnitude
			# OR just set Y if impulse is UP
			if impulse.is_zero_approx():
				final_impulse = Vector3.UP * float(override_val)
			else:
				final_impulse = impulse.normalized() * float(override_val)
		elif override_val is Vector3:
			final_impulse = override_val

	if is_local_space:
		# Transform to local space
		final_impulse = body.global_basis * final_impulse

	# Apply the impulse (add to current velocity)
	body.velocity += final_impulse

	# Optional: Print for debugging
	print("BehaviorImpulse: Applied ", final_impulse, " to ", actor.name)
