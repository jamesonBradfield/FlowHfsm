@tool
class_name BehaviorPhysics extends FlowBehavior

## Generic physics behavior.
## Applies forces, impulses, or sets velocity directly on a CharacterBody3D.
## Uses ValueFloat/ValueVector3 to allow binding to Blackboard variables.

const ValueFloat = preload("res://addons/FlowHFSM/src/core/values/ValueFloat.gd")
const ValueVector3 = preload("res://addons/FlowHFSM/src/core/values/ValueVector3.gd")

enum PhysicsMode {
	IMPULSE, 		## Apply instantaneous force once (Add to velocity)
	FORCE, 			## Apply continuous force (Add to velocity * delta)
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
## If true, rotates the actor to face the calculated movement direction (Only works in SET_VELOCITY).
@export var face_movement: bool = false
## Rotation speed for face_movement (radians/sec).
@export var turn_speed: float = 10.0

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
	if property.name == "planar_only" or property.name == "face_movement" or property.name == "turn_speed":
		if mode != PhysicsMode.SET_VELOCITY:
			property.usage = PROPERTY_USAGE_NONE

	if property.name == "space_node_path":
		if space != Space.RELATIVE_TO_NODE:
			property.usage = PROPERTY_USAGE_NONE

func enter(node: Node, actor: Node, blackboard: FlowBlackboard) -> void:
	if apply_on_enter:
		_execute_physics(delta_safe(actor), actor, blackboard)

func update(node: Node, delta: float, actor: Node, blackboard: FlowBlackboard) -> void:
	if not apply_on_enter:
		_execute_physics(delta, actor, blackboard)

# Helper to get a safe delta if called during enter (which might not have delta)
func delta_safe(actor: Node) -> float:
	return actor.get_process_delta_time()

func _execute_physics(delta: float, actor: Node, blackboard: FlowBlackboard) -> void:
	var body: CharacterBody3D = actor as CharacterBody3D
	if not body:
		# Fail silently in editor, warn in game
		if not Engine.is_editor_hint():
			push_warning("BehaviorPhysics: Actor '%s' is not a CharacterBody3D" % actor.name)
		return

	# 1. Resolve Magnitude
	var final_magnitude: float = 0.0
	if magnitude:
		final_magnitude = magnitude.get_value(actor, blackboard)

	# 2. Resolve Direction
	var dir: Vector3 = Vector3.ZERO
	if direction:
		dir = direction.get_value(actor, blackboard)

	# Normalize direction
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	else:
		dir = Vector3.ZERO

	# 3. Resolve Space (Rotation)
	var final_vector: Vector3 = dir * final_magnitude

	match space:
		Space.LOCAL:
			# Rotate by Actor's Y rotation
			final_vector = body.global_basis * final_vector

		Space.RELATIVE_TO_NODE:
			var ref_node: Node = actor.get_node_or_null(space_node_path)
			if ref_node and ref_node is Node3D:
				final_vector = ref_node.global_basis * final_vector

		Space.WORLD:
			pass 

	# 4. Apply to CharacterBody3D
	match mode:
		PhysicsMode.IMPULSE:
			body.velocity += final_vector

		PhysicsMode.FORCE:
			body.velocity += final_vector * delta

		PhysicsMode.SET_VELOCITY:
			# Rotation Logic (Face Movement)
			if face_movement and final_vector.length_squared() > 0.1:
				var target_dir = final_vector.normalized()
				var current_dir = -body.global_transform.basis.z # Forward is -Z in Godot

				# Planar rotation only (Y-axis)
				target_dir.y = 0
				target_dir = target_dir.normalized()

				if target_dir.length_squared() > 0.01:
					var new_basis = body.global_transform.basis
					# Smooth lookat
					var target_basis = Basis.looking_at(target_dir, Vector3.UP)
					new_basis = new_basis.slerp(target_basis, turn_speed * delta)
					body.global_transform.basis = new_basis

			# Velocity Application
			if planar_only:
				body.velocity.x = final_vector.x
				body.velocity.z = final_vector.z
			else:
				body.velocity = final_vector
