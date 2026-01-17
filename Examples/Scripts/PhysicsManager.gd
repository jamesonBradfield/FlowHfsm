class_name PhysicsManager extends Node

## Handles physics simulation for the character.
## Applies gravity, friction, and handles movement.

@export_group("Physics Settings")
## Gravity force (units per second squared).
@export var gravity: float = 20.0
## Friction applied when not moving (0-1).
@export var ground_friction: float = 0.1
## Air resistance (0-1).
@export var air_resistance: float = 0.01
## Terminal velocity (max downward speed).
@export var terminal_velocity: float = 50.0
## Rotation speed in radians per second.
@export var rotation_speed: float = 10.0

## The CharacterBody3D being managed.
var _body: CharacterBody3D

func _ready() -> void:
	_body = owner as CharacterBody3D
	if not _body:
		_body = get_parent() as CharacterBody3D

	if not _body:
		push_error("PhysicsManager: Cannot find CharacterBody3D to manage")
	else:
		# Ensure we have a snap length for stable slopes
		if _body.floor_snap_length < 0.1:
			_body.floor_snap_length = 0.1

## Adds an immediate force to the velocity.
func apply_impulse(impulse: Vector3) -> void:
	if _body:
		_body.velocity += impulse

## Adds a continuous force over time (force * delta).
func apply_force(force: Vector3, delta: float) -> void:
	if _body:
		_body.velocity += force * delta

## Overwrites X and Z velocity while preserving Y (gravity).
func set_planar_velocity(velocity: Vector3) -> void:
	if _body:
		_body.velocity.x = velocity.x
		_body.velocity.z = velocity.z

## Overwrites the full velocity vector.
func set_velocity(velocity: Vector3) -> void:
	if _body:
		_body.velocity = velocity

## Rotates the body to face the given direction on the Y axis.
func face_direction(direction: Vector3, delta: float) -> void:
	if not _body: return
	
	# Project to XZ plane
	var flat_dir: Vector3 = Vector3(direction.x, 0, direction.z)
	if flat_dir.length_squared() < 0.001:
		return
		
	var target_basis: Basis = Basis.looking_at(flat_dir, Vector3.UP)
	# Interpolate basis.y rotation (quaternion slerp is smoother/safer)
	var target_quat: Quaternion = target_basis.get_rotation_quaternion()
	var current_quat: Quaternion = _body.global_transform.basis.get_rotation_quaternion()
	
	var next_quat: Quaternion = current_quat.slerp(target_quat, rotation_speed * delta)
	_body.global_transform.basis = Basis(next_quat)

func _physics_process(delta: float) -> void:
	if not _body:
		return

	# Apply gravity (always)
	if not _body.is_on_floor():
		_body.velocity.y -= gravity * delta

	# Clamp terminal velocity
	if _body.velocity.y < -terminal_velocity:
		_body.velocity.y = -terminal_velocity

	# Apply friction/resistance
	if _body.is_on_floor():
		_body.velocity.x *= (1.0 - ground_friction)
		_body.velocity.z *= (1.0 - ground_friction)
	else:
		_body.velocity.x *= (1.0 - air_resistance)
		_body.velocity.z *= (1.0 - air_resistance)

	# Move the body
	_body.move_and_slide()
