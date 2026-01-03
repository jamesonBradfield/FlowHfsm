class_name PhysicsManager extends Node

## The Motor Component
## Responsible for executing movement intents, applying gravity, and handling external forces.
## It does NOT decide "when" to move, only "how" to move.

# Frame of Reference for inputs
enum Frame { 
	## Absolute Vector (1,0,0) is always World East. Good for 2D/Isometric.
	WORLD,  
	## Relative to Camera View (Up is Forward). Good for Third-Person/FPS.
	CAMERA, 
	## Relative to Character Model (Up is Local Forward). Good for Tank Controls/Vehicles.
	ACTOR   
}

# Add a signal for debuggers
signal intent_changed(velocity: Vector3)

@export_group("Settings")
## Gravity applied when not on the floor (m/s^2).
@export var gravity: float = 9.8
## Friction applied when on the floor. Higher values mean snappier stopping.
@export var default_friction: float = 6.0
## Drag applied when in the air. Lower values allow more drift.
@export var air_drag: float = 2.0

# The Parent Body
## The CharacterBody3D node that this manager controls.
@onready var body: CharacterBody3D = get_parent()

# Accumulators
var _intent_velocity: Vector3 = Vector3.ZERO
var _external_forces: Vector3 = Vector3.ZERO
var _snap_vector: Vector3 = Vector3.DOWN

## Main physics loop.
## Applies gravity, resolves movement intent, applies external forces, and calls `move_and_slide`.
func _physics_process(delta: float) -> void:
	if not body: return

	# 1. Apply Gravity
	if not body.is_on_floor():
		body.velocity.y -= gravity * delta

	# 2. Resolve Intent (Movement Requests)
	# We interpret the requested velocity against the current velocity
	# to apply friction/acceleration smoothing if desired, or set directly.
	# For crisp movement, we just set x/z directly from intent.
	
	# Horizontal Movement Preservation (Don't kill gravity)
	var target_vel = _intent_velocity
	target_vel.y = body.velocity.y 
	
	# Apply Friction / Smoothing
	var current_friction = default_friction if body.is_on_floor() else air_drag
	body.velocity = body.velocity.lerp(target_vel, current_friction * delta)
	
	# 3. Apply External Forces (Knockback, Wind)
	body.velocity += _external_forces * delta
	_external_forces = _external_forces.lerp(Vector3.ZERO, 5.0 * delta) # Decay forces

	# 4. Execution
	body.move_and_slide()
	
	# 5. Reset Intent for next frame
	# States must request movement *every frame*. If they stop asking, we stop moving.
	_intent_velocity = Vector3.ZERO

# --- PUBLIC API FOR STATES ---

## Called by States to request movement. 
## Calculates the 3D velocity vector based on the input direction and frame of reference.
##
## @param input_dir: Normalized Vector2 from Input (x=Right, y=Down/Back).
## @param speed: Desired speed in meters/sec.
## @param frame: The frame of reference for the input direction (WORLD, CAMERA, or ACTOR).
func move_intent(input_dir: Vector2, speed: float, frame: Frame = Frame.CAMERA) -> void:
	if input_dir.length_squared() < 0.01:
		_intent_velocity = Vector3.ZERO
		return

	var move_dir: Vector3 = Vector3.ZERO
	
	match frame:
		Frame.WORLD:
			move_dir = Vector3(input_dir.x, 0, input_dir.y).normalized()
			
		Frame.CAMERA:
			var cam = get_viewport().get_camera_3d()
			if cam:
				var cam_basis = cam.global_transform.basis
				var forward = -cam_basis.z
				var right = cam_basis.x
				
				# Flatten to horizontal plane so looking up doesn't slow us down
				forward.y = 0
				right.y = 0
				forward = forward.normalized()
				right = right.normalized()
				
				move_dir = (forward * input_dir.y + right * input_dir.x).normalized()
			else:
				# Fallback if no camera
				move_dir = Vector3(input_dir.x, 0, input_dir.y).normalized()
				
		Frame.ACTOR:
			var actor_basis = body.global_transform.basis
			move_dir = (actor_basis.z * input_dir.y + actor_basis.x * input_dir.x).normalized()

	_intent_velocity = move_dir * speed
	intent_changed.emit(_intent_velocity)

## Applies an external impulse (force * time) to the character.
## Used for knockback, explosions, etc.
##
## @param force: The force vector to apply (Direction * Strength).
func apply_impulse(force: Vector3) -> void:
	_external_forces += force
