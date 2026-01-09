class_name BehaviorMove extends StateBehavior

## Movement behavior for characters.
## Reads input from blackboard and applies velocity to the actor.
## Supports both INPUT (WASD) and FIXED direction sources.

enum DirectionSource { INPUT, FIXED }

@export_group("Movement Settings")
## Speed of movement in units per second.
@export var speed: float = 5.0
## Source of movement direction.
@export_enum("INPUT", "FIXED") var direction_source: int = DirectionSource.INPUT
## Fixed direction vector (only used when direction_source = FIXED).
@export var fixed_direction: Vector3 = Vector3.FORWARD
## Minimum input magnitude to consider as "moving".
@export var input_threshold: float = 0.1

@export_group("Orientation Settings")
## If true, character will face movement direction.
@export var face_movement_direction: bool = true
## Rotation speed for turning towards movement direction (degrees per second).
@export var rotation_speed: float = 360.0

func update(node: RecursiveState, delta: float, actor: Node) -> void:
	# Get the character body
	var body: CharacterBody3D = actor as CharacterBody3D
	if not body:
		push_warning("BehaviorMove: Actor is not a CharacterBody3D")
		return

	# Determine movement direction
	var move_dir: Vector3 = Vector3.ZERO

	match direction_source:
		DirectionSource.INPUT:
			# Try to find input on a Controller node
			var controller = actor.get_node_or_null("PlayerController")
			if controller:
				move_dir = controller.get("input_direction")
			elif "input_direction" in actor:
				move_dir = actor.input_direction

		DirectionSource.FIXED:
			move_dir = fixed_direction

	# Check if we're moving
	var is_moving: bool = move_dir.length() > input_threshold

	# Note: is_moving property is managed by PlayerController now, we don't write back.

	if is_moving:
		# Normalize and apply speed
		move_dir = move_dir.normalized()
		var velocity: Vector3 = move_dir * speed

		# Apply velocity
		body.velocity.x = velocity.x
		body.velocity.z = velocity.z

		# Handle orientation
		if face_movement_direction:
			# Smoothly rotate towards movement direction
			var target_rotation: float = atan2(-move_dir.x, -move_dir.z)
			var current_rotation: float = body.rotation.y

			# Smooth interpolation
			var angle_diff: float = wrapf(target_rotation - current_rotation, -PI, PI)
			var rotation_amount: float = deg_to_rad(rotation_speed) * delta

			if abs(angle_diff) < rotation_amount:
				body.rotation.y = target_rotation
			else:
				body.rotation.y += sign(angle_diff) * rotation_amount
	else:
		# Stop horizontal movement
		body.velocity.x = 0.0
		body.velocity.z = 0.0
