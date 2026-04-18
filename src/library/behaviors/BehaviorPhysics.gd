@tool
class_name BehaviorPhysics extends FlowBehavior

## THE PHYSICS BEHAVIOR
## "Just the Body" Edition.
## MOVEMENT: Applied to the 'actor' (PhysicsBody or Node3D).
##
## Reads from context dict (pushed from FlowDataMap):
##   "move_input" → Vector3 (required)
##   "camera"     → Node3D  (optional, for camera-relative movement)

enum Mode { IMPULSE, FORCE, SET_VELOCITY }
@export var mode: Mode = Mode.SET_VELOCITY

@export_group("Context Keys")
@export var move_input_key: StringName = &"move_input"
@export var camera_key: StringName = &"camera"

@export_group("State Logic")
@export var speed: float = 5.0
@export var acceleration: float = 0.0

func update(_node: Node, delta: float, actor: Node, context: Dictionary[StringName, Variant]) -> void:
	# 1. Fetch Input from context
	var input_vec = Vector3.ZERO
	if context.has(move_input_key):
		var val = context[move_input_key]
		if val is Vector3:
			input_vec = val
	
	# 2. Transform Input (Camera Space)
	var final_vec = input_vec
	if context.has(camera_key):
		var cam = context[camera_key]
		if cam is Node3D:
			var cam_basis = cam.global_transform.basis
			cam_basis.y = Vector3.ZERO
			cam_basis.z = cam_basis.z.normalized()
			cam_basis.x = cam_basis.x.normalized()
			final_vec = cam_basis * input_vec

	final_vec = final_vec.normalized() * speed

	# 3. MOVEMENT (Physics vs Simple Node3D)
	if "velocity" in actor: # CharacterBody3D
		match mode:
			Mode.SET_VELOCITY: 
				var old_y = actor.velocity.y
				if acceleration > 0:
					var target_h = Vector2(final_vec.x, final_vec.z)
					var current_h = Vector2(actor.velocity.x, actor.velocity.z)
					current_h = current_h.move_toward(target_h, acceleration * delta)
					actor.velocity.x = current_h.x
					actor.velocity.z = current_h.y
				else:
					actor.velocity.x = final_vec.x
					actor.velocity.z = final_vec.z
				if input_vec.y == 0: actor.velocity.y = old_y
			Mode.IMPULSE: actor.velocity += final_vec
			Mode.FORCE: actor.velocity += final_vec * delta

	elif "linear_velocity" in actor: # RigidBody3D
		match mode:
			Mode.IMPULSE: 
				actor.apply_central_impulse(final_vec)
			Mode.FORCE: actor.apply_central_force(final_vec)
	
	elif actor is Node3D: # Standard Node3D (No Physics)
		actor.global_translate(final_vec * delta)
