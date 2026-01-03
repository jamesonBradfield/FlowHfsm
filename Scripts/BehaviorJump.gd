class_name BehaviorJump extends StateBehavior

## Applies an immediate jump impulse when entered.

## The force of the jump.
@export var jump_force: float = 10.0
## The direction of the jump impulse (usually UP).
@export var jump_impulse_vector: Vector3 = Vector3.UP

func enter(node: RecursiveState, actor: Node, blackboard: Dictionary):
	# Apply immediate impulse
	var phys: PhysicsManager = blackboard.get("physics_manager")
	if phys:
		# Use the physics manager to apply the jump (assuming it exposes functionality or body)
		if phys.body:
			# Reset vertical velocity to ensure consistent jump height regardless of falling speed
			# This might feel "gamey" but is usually desired for platformers
			phys.body.velocity.y = 0 
			
			# Apply the jump force
			phys.body.velocity += jump_impulse_vector * jump_force
	
	super.enter(node, actor, blackboard)
