@tool
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

enum MagnitudeMode {
	FIXED, 			## Use the 'magnitude' export
	BLACKBOARD_KEY, 	## Read a float from the blackboard
	STATE_VARIABLE  ## Use a StateVariable resource
}

enum Space {
	WORLD, 			## Apply in global world coordinates
	LOCAL, 			## Rotate by the Actor's rotation
	RELATIVE_TO_NODE ## Rotate by a specific Node's rotation
}

@export_group("Operation")
@export var mode: PhysicsMode = PhysicsMode.IMPULSE:
	set(value):
		mode = value
		notify_property_list_changed()

## If true, SET_VELOCITY only affects X/Z (planar), preserving gravity (Y).
@export var planar_only: bool = false
## If true, applies the force/impulse immediately on Enter. If false, applies every Update.
@export var apply_on_enter: bool = true

@export_group("Magnitude")
@export var magnitude_mode: MagnitudeMode = MagnitudeMode.FIXED:
	set(value):
		magnitude_mode = value
		notify_property_list_changed()

@export var magnitude: float = 10.0
## Optional: Blackboard key to override static magnitude (reads float).
@export var magnitude_blackboard_key: String = ""
## Optional: StateVariable to use for magnitude (reads value from blackboard using variable name).
@export var magnitude_variable: StateVariable

@export_group("Direction")
@export var direction_mode: DirectionMode = DirectionMode.VECTOR:
	set(value):
		direction_mode = value
		notify_property_list_changed()

@export var direction_vector: Vector3 = Vector3.UP
## Path to node used for NODE_FORWARD or RELATIVE_TO_NODE space.
@export var direction_node_path: String = "Camera3D"
## Optional: Blackboard key to override direction (reads Vector3).
@export var direction_blackboard_key: String = ""

@export_group("Space")
@export var space: Space = Space.WORLD:
	set(value):
		space = value
		notify_property_list_changed()


func _validate_property(property: Dictionary) -> void:
	if property.name == "planar_only":
		if mode != PhysicsMode.SET_VELOCITY:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "magnitude":
		if magnitude_mode != MagnitudeMode.FIXED:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "magnitude_blackboard_key":
		if magnitude_mode != MagnitudeMode.BLACKBOARD_KEY:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "magnitude_variable":
		if magnitude_mode != MagnitudeMode.STATE_VARIABLE:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "direction_vector":
		if direction_mode != DirectionMode.VECTOR:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "direction_node_path":
		var needed = (direction_mode == DirectionMode.NODE_FORWARD) or (space == Space.RELATIVE_TO_NODE)
		if not needed:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "direction_blackboard_key":
		if direction_mode != DirectionMode.BLACKBOARD_KEY:
			property.usage = PROPERTY_USAGE_NONE


func enter(node: Node, actor: Node, blackboard: Blackboard) -> void:
	if apply_on_enter:
		_execute_physics(node, 0.0, actor, blackboard)

func update(node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:
	if not apply_on_enter:
		_execute_physics(node, delta, actor, blackboard)

func _find_physics_manager(actor: Node) -> Node:
	# 1. Direct child
	var pm = actor.get_node_or_null("PhysicsManager")
	if pm: return pm
	
	# 2. Via PlayerController (if exists)
	var pc = actor.get_node_or_null("PlayerController")
	if pc and "physics_manager" in pc and pc.physics_manager:
		return pc.physics_manager
		
	# 3. Search children for type (slow but robust)
	for child in actor.get_children():
		if child is PhysicsManager: # Assuming PhysicsManager is a class_name
			return child
		if child.name == "PhysicsManager": # Fallback if class_name not registered/loaded
			return child
			
	return null

func _execute_physics(_node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:
	var body = actor as CharacterBody3D
	if not body:
		push_warning("BehaviorPhysics: Actor is not a CharacterBody3D")
		return
	
	# Get PhysicsManager
	var physics_manager = _find_physics_manager(actor)
	if not physics_manager:
		push_warning("BehaviorPhysics: PhysicsManager not found on actor " + actor.name)
		return

	# 1. Resolve Magnitude
	var final_magnitude: float = magnitude
	
	match magnitude_mode:
		MagnitudeMode.FIXED:
			final_magnitude = magnitude
		
		MagnitudeMode.BLACKBOARD_KEY:
			if not magnitude_blackboard_key.is_empty() and blackboard.has_value(magnitude_blackboard_key):
				var bb_val = blackboard.get_value(magnitude_blackboard_key)
				if bb_val is float or bb_val is int:
					final_magnitude = float(bb_val)
					
		MagnitudeMode.STATE_VARIABLE:
			if magnitude_variable:
				var key = magnitude_variable.variable_name
				if not key.is_empty() and blackboard.has_value(key):
					var bb_val = blackboard.get_value(key)
					if bb_val is float or bb_val is int:
						final_magnitude = float(bb_val)
				else:
					# Fallback to initial_value if not in blackboard yet (or logic choice?)
					# Usually Blackboard is authoritative. If missing, use initial.
					var init_val = magnitude_variable.initial_value
					if init_val is float or init_val is int:
						final_magnitude = float(init_val)

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
