@tool
class_name BehaviorPhysics extends StateBehavior

## Generic physics behavior using Smart Values (Blender Driver pattern).
## Applies forces, impulses, or sets velocity based on ValueFloat/ValueVector3 sources.

const ValueFloat = preload("res://addons/FlowHFSM/runtime/values/ValueFloat.gd")
const ValueVector3 = preload("res://addons/FlowHFSM/runtime/values/ValueVector3.gd")

enum PhysicsMode {
	IMPULSE, 		## Apply instantaneous force once on enter (Add to velocity)
	FORCE, 			## Apply continuous force every frame (Add to velocity * delta)
	SET_VELOCITY 	## Overwrite velocity (Planar or Full)
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
## If true, rotates the actor to face the calculated movement direction.
@export var face_movement: bool = false

@export_group("Inputs")
## The magnitude of the force/velocity.
@export var magnitude: ValueFloat = ValueFloat.new()
## The direction vector (will be normalized).
@export var direction: ValueVector3 = ValueVector3.new()

@export_group("Space")
@export var space: Space = Space.WORLD:
	set(value):
		space = value
		notify_property_list_changed()
## Path to node used for RELATIVE_TO_NODE space.
@export var space_node_path: String = "Camera3D"

func _validate_property(property: Dictionary) -> void:
	if property.name == "planar_only":
		if mode != PhysicsMode.SET_VELOCITY:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "space_node_path":
		if space != Space.RELATIVE_TO_NODE:
			property.usage = PROPERTY_USAGE_NONE

func enter(node: Node, actor: Node, blackboard: Blackboard) -> void:
	# Cache PhysicsManager in memory
	if node is RecursiveState:
		var pm = _find_physics_manager(actor)
		if pm:
			node.memory["_physics_manager"] = pm
		else:
			push_warning("BehaviorPhysics: PhysicsManager not found on actor " + actor.name)

	if apply_on_enter:
		_execute_physics(node, 0.0, actor, blackboard)

func update(node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:
	if not apply_on_enter:
		_execute_physics(node, delta, actor, blackboard)

func _find_physics_manager(actor: Node) -> Node:
	# 1. Direct child
	var pm: Node = actor.get_node_or_null("PhysicsManager")
	if pm: return pm

	# 2. Via PlayerController (if exists)
	var pc: Node = actor.get_node_or_null("PlayerController")
	if pc and "physics_manager" in pc and pc.physics_manager:
		return pc.physics_manager

	# 3. Search children for type (slow but robust)
	for child: Node in actor.get_children():
		if child is PhysicsManager: # Assuming PhysicsManager is a class_name
			return child
		if child.name == "PhysicsManager": # Fallback if class_name not registered/loaded
			return child

	return null

func _execute_physics(_node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:
	var body: CharacterBody3D = actor as CharacterBody3D
	if not body:
		push_warning("BehaviorPhysics: Actor is not a CharacterBody3D")
		return

	# Get PhysicsManager (Cached or Find)
	var physics_manager: Node = null
	if _node is RecursiveState and _node.memory.has("_physics_manager"):
		physics_manager = _node.memory["_physics_manager"]
	
	if not physics_manager:
		physics_manager = _find_physics_manager(actor)
		# Cache it if we found it now
		if physics_manager and _node is RecursiveState:
			_node.memory["_physics_manager"] = physics_manager

	if not physics_manager:
		# Warning already pushed in enter() or find()
		return

	# 1. Resolve Magnitude
	var final_magnitude: float = 0.0
	if magnitude:
		final_magnitude = magnitude.get_value(actor, blackboard)
	else:
		push_warning("BehaviorPhysics: No magnitude resource assigned")

	# 2. Resolve Direction
	var dir: Vector3 = Vector3.ZERO
	if direction:
		dir = direction.get_value(actor, blackboard)
	else:
		push_warning("BehaviorPhysics: No direction resource assigned")

	# Normalize direction (unless it's zero, to avoid NaN)
	if dir.length_squared() > 0.001:
		dir = dir.normalized()

	# 3. Resolve Space (Rotation)
	var final_vector: Vector3 = dir * final_magnitude

	match space:
		Space.LOCAL:
			# Rotate by Actor's Y rotation (assuming Y-up character)
			final_vector = body.global_basis * final_vector

		Space.RELATIVE_TO_NODE:
			var ref_node: Node = actor.get_node_or_null(space_node_path)
			if ref_node and ref_node is Node3D:
				final_vector = ref_node.global_basis * final_vector
			else:
				push_warning("BehaviorPhysics: Reference node '%s' not found for RELATIVE_TO_NODE space, using world space" % space_node_path)

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
			if face_movement:
				if physics_manager.has_method("face_direction"):
					physics_manager.face_direction(final_vector, delta)

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
