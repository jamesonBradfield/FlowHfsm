class_name BehaviorPhysics extends StateBehavior

## Generic physics behavior for applying forces, impulses, or setting velocity.
## Flexible direction and magnitude sources allow for diverse use cases (Jump, Dash, Knockback, etc).

enum PhysicsMode {
	IMPULSE, 		## Apply instantaneous force once on enter (Add to velocity)
	FORCE, 			## Apply continuous force every frame (Add to velocity * delta)
	SET_VELOCITY 	## Overwrite velocity (Planar or Full)
}

enum DirectionMode {
	VECTOR, 		## Use the 'direction_vector' export
	NODE_FORWARD, 	## Use the forward vector of a specific node (e.g. Camera)
	INPUT, 			## Use input vector from PlayerController or Actor
	BLACKBOARD_KEY 	## Read a Vector3 from the blackboard
}

enum Space {
	WORLD, 			## Apply in global world coordinates
	LOCAL, 			## Rotate by the Actor's rotation
	RELATIVE_TO_NODE ## Rotate by a specific Node's rotation
}

@export_group("Operation")
@export var mode: PhysicsMode = PhysicsMode.IMPULSE
## If true, SET_VELOCITY only affects X/Z (planar), preserving gravity (Y).
@export var planar_only: bool = false
## If true, applies the force/impulse immediately on Enter. If false, applies every Update.
@export var apply_on_enter: bool = true

@export_group("Magnitude")
@export var magnitude: float = 10.0
## Optional: Blackboard key to override static magnitude (reads float).
@export var magnitude_blackboard_key: String = ""

@export_group("Direction")
@export var direction_mode: DirectionMode = DirectionMode.VECTOR
@export var direction_vector: Vector3 = Vector3.UP
## Path to node used for NODE_FORWARD or RELATIVE_TO_NODE space.
@export var direction_node_path: String = "Camera3D"
## Optional: Blackboard key to override direction (reads Vector3).
@export var direction_blackboard_key: String = ""

@export_group("Space")
@export var space: Space = Space.WORLD


func enter(node: RecursiveState, actor: Node, blackboard) -> void:
	if apply_on_enter:
		_execute_physics(node, 0.0, actor, blackboard)

func update(node: RecursiveState, delta: float, actor: Node, blackboard) -> void:
	if not apply_on_enter:
		_execute_physics(node, delta, actor, blackboard)

func _execute_physics(_node: RecursiveState, delta: float, actor: Node, blackboard) -> void:
	var body = actor as CharacterBody3D
	if not body:
		push_warning("BehaviorPhysics: Actor is not a CharacterBody3D")
		return
	
	# Get PhysicsManager
	var physics_manager = actor.get_node_or_null("PhysicsManager")
	if not physics_manager:
		# Fallback: Try to find it via owner or children if not direct child
		# But usually it's a sibling or child. Let's assume standard setup or fail gracefully.
		push_warning("BehaviorPhysics: PhysicsManager not found on actor.")
		return

	# 1. Resolve Magnitude
	var final_magnitude: float = magnitude
	if not magnitude_blackboard_key.is_empty() and blackboard.has_value(magnitude_blackboard_key):
		var bb_val = blackboard.get_value(magnitude_blackboard_key)
		if bb_val is float or bb_val is int:
			final_magnitude = float(bb_val)

	# 2. Resolve Direction (Unit Vector)
	var dir: Vector3 = Vector3.ZERO
	
	match direction_mode:
		DirectionMode.VECTOR:
			dir = direction_vector.normalized()
			
		DirectionMode.NODE_FORWARD:
			var ref_node = actor.get_node_or_null(direction_node_path)
			if ref_node and ref_node is Node3D:
				dir = -ref_node.global_transform.basis.z # Forward is -Z in Godot
			else:
				# Fallback
				dir = direction_vector.normalized()
				
		DirectionMode.INPUT:
			# Try PlayerController first
			var controller = actor.get_node_or_null("PlayerController")
			if controller and controller.get("input_direction") != null:
				dir = controller.input_direction
			elif "input_direction" in actor:
				dir = actor.input_direction
				
		DirectionMode.BLACKBOARD_KEY:
			if not direction_blackboard_key.is_empty() and blackboard.has_value(direction_blackboard_key):
				var val = blackboard.get_value(direction_blackboard_key)
				if val is Vector3:
					dir = val
	
	# Normalize direction (unless it's zero, to avoid NaN)
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	
	# 3. Resolve Space (Rotation)
	# Note: INPUT is usually already in world space (if from controller) or camera space.
	# If DirectionMode is VECTOR, we typically want to rotate it.
	
	var final_vector: Vector3 = dir * final_magnitude
	
	match space:
		Space.LOCAL:
			# Rotate by Actor's Y rotation (assuming Y-up character)
			final_vector = body.global_basis * final_vector
			
		Space.RELATIVE_TO_NODE:
			var ref_node = actor.get_node_or_null(direction_node_path)
			if ref_node and ref_node is Node3D:
				final_vector = ref_node.global_basis * final_vector

		Space.WORLD:
			pass # Already world space

	# 4. Apply to PhysicsManager
	match mode:
		PhysicsMode.IMPULSE:
			if physics_manager.has_method("apply_impulse"):
				physics_manager.apply_impulse(final_vector)
			else:
				# Fallback legacy
				body.velocity += final_vector
				
		PhysicsMode.FORCE:
			if physics_manager.has_method("apply_force"):
				physics_manager.apply_force(final_vector, delta)
			else:
				# Fallback legacy
				body.velocity += final_vector * delta
				
		PhysicsMode.SET_VELOCITY:
			if planar_only:
				if physics_manager.has_method("set_planar_velocity"):
					physics_manager.set_planar_velocity(final_vector)
				else:
					body.velocity.x = final_vector.x
					body.velocity.z = final_vector.z
			else:
				if physics_manager.has_method("set_velocity"):
					physics_manager.set_velocity(final_vector)
				else:
					body.velocity = final_vector
