@tool
class_name BehaviorRotation extends FlowBehavior

## THE ROTATION BEHAVIOR
## "Spin me right round" Edition.
## Handles visuals/model rotation independently of physics.

@export_group("Dependency Injection")
@export var input_binding: FlowBinding
@export var camera_binding: FlowBinding
@export var rotation_node_binding: FlowBinding

func _init() -> void:
	if not input_binding:
		input_binding = FlowBinding.new()
		input_binding.path = ^":move_input"
	if not camera_binding:
		camera_binding = FlowBinding.new()
		camera_binding.path = ^":camera"
	if not rotation_node_binding:
		rotation_node_binding = FlowBinding.new()
		rotation_node_binding.path = ^":model"

@export_group("Settings")
@export var turn_speed: float = 10.0
@export var face_movement: bool = true
@export var align_to_up: Vector3 = Vector3.UP ## The axis we rotate around (Default Y-up)

func update(_node: Node, delta: float, actor: Node) -> void:
	# 1. Fetch Input
	var input_vec = Vector3.ZERO
	if input_binding:
		var val = input_binding.get_value(actor)
		if val is Vector3:
			input_vec = val
	
	# 2. Transform Input (Camera Space)
	var final_vec = input_vec
	if camera_binding:
		var cam = camera_binding.get_value(actor)
		if cam is Node3D:
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
		if rotation_node_binding:
			var ref = rotation_node_binding.get_value(actor)
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
