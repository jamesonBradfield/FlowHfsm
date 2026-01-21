@tool
class_name BehaviorPhysics extends FlowBehavior

## THE PHYSICS BEHAVIOR
## "Separate Body & Mind" Edition.
## 
## MOVEMENT: Applied to the 'actor' (PhysicsBody or Node3D).
## ROTATION: Applied to the 'rotation_node' (Visuals) IF defined, else 'actor'.
## 
## DATA: Fetched from Actor properties (Dependency Injection).

enum Mode { IMPULSE, FORCE, SET_VELOCITY }
@export var mode: Mode = Mode.SET_VELOCITY

@export_group("Dependency Injection")
@export var input_property: String = "move_input"
@export var camera_property: String = ""
## Optional: The Node to rotate (e.g., "Skin", "Model"). 
## If defined, we rotate THIS instead of the Actor.
@export var rotation_node_property: String = ""

@export_group("State Logic")
@export var speed: float = 5.0
@export var acceleration: float = 0.0

@export_group("Rotation")
@export var face_movement: bool = true
@export var turn_speed: float = 10.0

func update(_node: Node, delta: float, actor: Node) -> void:
	# 1. Fetch Dependencies
	var input_vec = Vector3.ZERO
	if input_property and input_property in actor:
		input_vec = actor.get(input_property)
	
	# 2. Transform Input (Camera Space)
	var final_vec = input_vec
	if camera_property and camera_property in actor:
		var cam = actor.get(camera_property)
		if cam and cam is Node3D:
			var cam_basis = cam.global_transform.basis
			cam_basis.y = Vector3.ZERO
			cam_basis.z = cam_basis.z.normalized()
			cam_basis.x = cam_basis.x.normalized()
			final_vec = cam_basis * input_vec

	final_vec = final_vec.normalized() * speed

	# 3. ROTATION (Visuals vs Actor)
	if face_movement and final_vec.length_squared() > 0.1:
		var target_node: Node3D = actor as Node3D
		
		# If a separate rotation node is defined, use it!
		if rotation_node_property and rotation_node_property in actor:
			var ref = actor.get(rotation_node_property)
			if ref is Node3D:
				target_node = ref
		
		var target_dir = final_vec.normalized()
		target_dir.y = 0 
		if target_dir.length_squared() > 0.001 and target_node:
			var current_basis = target_node.global_transform.basis
			var target_basis = Basis.looking_at(target_dir, Vector3.UP)
			var new_basis = current_basis.slerp(target_basis, turn_speed * delta)
			target_node.global_transform.basis = new_basis

	# 4. MOVEMENT (Physics vs Simple Node3D)
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
			Mode.IMPULSE: actor.apply_central_impulse(final_vec)
			Mode.FORCE: actor.apply_central_force(final_vec)
	
	elif actor is Node3D: # Standard Node3D (No Physics)
		# Just translate it!
		actor.global_translate(final_vec * delta)
