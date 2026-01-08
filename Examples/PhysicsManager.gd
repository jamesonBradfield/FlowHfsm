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

## The CharacterBody3D being managed.
var _body: CharacterBody3D

func _ready() -> void:
	_body = owner as CharacterBody3D
	if not _body:
		_body = get_parent() as CharacterBody3D

	if not _body:
		push_error("PhysicsManager: Cannot find CharacterBody3D to manage")

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
