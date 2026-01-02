class_name BehaviorJump extends StateBehavior

@export var jump_force: float = 10.0
@export var jump_impulse_vector: Vector3 = Vector3.UP

func enter(node: RecursiveState, actor: Node, blackboard: Dictionary):
	# Apply immediate impulse
	var phys: PhysicsManager = blackboard.get("physics_manager")
	if phys:
		# We need to access the body directly or add a method to PhysicsManager
		# PhysicsManager has apply_impulse but that adds to external forces.
		# Jump is usually an immediate velocity change.
		
		# Let's add a jump method to PhysicsManager or access body
		if phys.body:
			phys.body.velocity += jump_impulse_vector * jump_force
	
	super.enter(node, actor, blackboard)
