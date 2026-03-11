@tool
class_name BehaviorRotation extends FlowBehavior

## THE ROTATION BEHAVIOR
## "Spin me right round" Edition.
## Handles visuals/model rotation independently of physics.

@export_group("Dependency Injection")
@export var input_property: String = "move_input"
@export var camera_property: String = "camera" # Defaulting to likely name
@export var rotation_node_property: String = "model" # Defaulting to likely name

@export_group("Settings")
@export var turn_speed: float = 10.0
@export var face_movement: bool = true
@export var align_to_up: Vector3 = Vector3.UP ## The axis we rotate around (Default Y-up)

func update(_node: Node, delta: float, actor: Node) -> void:
	# 1. Fetch Input
	var input_vec = Vector3.ZERO
	if input_property and input_property in actor:
		input_vec = actor.get(input_property)
	
	# 2. Transform Input (Camera Space)
	var final_vec = input_vec
	if camera_property and camera_property in actor:
		var cam = actor.get(camera_property)
		if cam and cam is Node3D:
			var cam_basis = cam.global_transform.basis
			# We flatten the camera basis relative to our chosen Up Axis
			# so looking down doesn't make us move into the floor.
			if align_to_up == Vector3.UP:
				cam_basis.y = Vector3.ZERO
			
			cam_basis.z = cam_basis.z.normalized()
			cam_basis.x = cam_basis.x.normalized()
			final_vec = cam_basis * input_vec

	# 3. Apply Rotation
	if face_movement and final_vec.length_squared() > 0.1:
		var target_node: Node3D = actor as Node3D
		
		# Use the specific rotation node (Visuals) if defined
		if rotation_node_property and rotation_node_property in actor:
			var ref = actor.get(rotation_node_property)
			if ref is Node3D:
				target_node = ref
		
		var target_dir = final_vec.normalized()
		
		# Flatten direction on the axis we are rotating around
		if align_to_up == Vector3.UP:
			target_dir.y = 0
		elif align_to_up == Vector3.RIGHT:
			target_dir.x = 0
		elif align_to_up == Vector3.FORWARD:
			target_dir.z = 0
			
		if target_dir.length_squared() > 0.001 and target_node:
			var current_basis = target_node.global_transform.basis
			# locking up vector to our setting
			var target_basis = Basis.looking_at(target_dir, align_to_up)
			
			# Slerp it so it doesn't snap instantly like a glitch
			var new_basis = current_basis.slerp(target_basis, turn_speed * delta)
			target_node.global_transform.basis = new_basis
