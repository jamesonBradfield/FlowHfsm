class_name BehaviorImpulse extends StateBehavior

## Applies an immediate impulse when entered.

## The impulse applied to the body.
@export var impulse: Vector3 = Vector3(0, 10, 0)
## If true, resets vertical velocity before applying the impulse (useful for consistent jumps).
@export var reset_vertical_velocity: bool = true

func enter(node: RecursiveState, actor: Node, blackboard: Dictionary):
	var phys: PhysicsManager = blackboard.get("physics_manager")
	if phys and phys.body:
		if reset_vertical_velocity:
			phys.body.velocity.y = 0 
		phys.apply_impulse(impulse)
	
	super.enter(node, actor, blackboard)
