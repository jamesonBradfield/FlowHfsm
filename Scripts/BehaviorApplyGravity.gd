class_name BehaviorApplyGravity extends StateBehavior

## Applies gravity to the character.
## Used primarily for falling/airborne states.

@export_group("Gravity Settings")
## Gravity force in units per second squared.
@export var gravity: float = 9.8

func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary) -> void:
	var body: CharacterBody3D = actor as CharacterBody3D
	if not body:
		push_warning("BehaviorApplyGravity: Actor is not a CharacterBody3D")
		return

	# Apply gravity (accumulate downward velocity)
	body.velocity.y -= gravity * delta
