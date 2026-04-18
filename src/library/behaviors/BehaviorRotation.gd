@tool
class_name BehaviorRotation extends FlowBehavior

## THE ROTATION BEHAVIOR
## "Spin me right round" Edition.
## Handles visuals/model rotation independently of physics.
##
## Reads from context dict (pushed from FlowDataMap):
##   "move_input"    → Vector3 (required)
##   "camera"         → Node3D  (optional, for camera-relative rotation)
##   "model"          → Node3D  (optional, visual rotation target)

@export_group("Context Keys")
@export var move_input_key: StringName = &"move_input"
@export var camera_key: StringName = &"camera"
@export var model_key: StringName = &"model"

@export_group("Settings")
@export var turn_speed: float = 10.0
@export var face_movement: bool = true
@export var align_to_up: Vector3 = Vector3.UP

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
			if align_to_up == Vector3.UP:
				cam_basis.y = Vector3.ZERO
			cam_basis.z = cam_basis.z.normalized()
			cam_basis.x = cam_basis.x.normalized()
			final_vec = cam_basis * input_vec

	# 3. Apply Rotation
	if face_movement and final_vec.length_squared() > 0.1:
		var target_node: Node3D = actor as Node3D
		
		if context.has(model_key):
			var ref = context[model_key]
			if ref is Node3D:
				target_node = ref
		
		var target_dir = final_vec.normalized()
		
		if align_to_up == Vector3.UP:
			target_dir.y = 0
		elif align_to_up == Vector3.RIGHT:
			target_dir.x = 0
		elif align_to_up == Vector3.FORWARD:
			target_dir.z = 0
			
		if target_dir.length_squared() > 0.001 and target_node:
			var current_basis = target_node.global_transform.basis
			var target_basis = Basis.looking_at(target_dir, align_to_up)
			var new_basis = current_basis.slerp(target_basis, turn_speed * delta)
			target_node.global_transform.basis = new_basis
