class_name PhysicsManager extends Node

## The Motor Component
## Responsible for executing movement intents, applying gravity, and handling external forces.
## It does NOT decide "when" to move, only "how" to move.

# Frame of Reference for inputs
enum Frame { 
	WORLD,  # Absolute Vector (1,0,0) is always World East
	CAMERA, # Relative to Camera View (Up is Forward)
	ACTOR   # Relative to Character Model (Up is Local Forward)
}

@export_group("Settings")
@export var gravity: float = 9.8
@export var default_friction: float = 6.0
@export var air_drag: float = 2.0

# The Parent Body
@onready var body: CharacterBody3D = get_parent()

# Accumulators
var _intent_velocity: Vector3 = Vector3.ZERO
var _external_forces: Vector3 = Vector3.ZERO
var _snap_vector: Vector3 = Vector3.DOWN

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
## input_dir: Normalized Vector2 from Input (x, y)
## speed: Desired speed in meters/sec
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

## Called by Enemies or Hazards
func apply_impulse(force: Vector3) -> void:
	_external_forces += force
