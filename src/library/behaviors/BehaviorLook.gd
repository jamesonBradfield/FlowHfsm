@tool
class_name BehaviorLook extends FlowBehavior

## THE LOOK BEHAVIOR
## Handles looking around using state_packet.look_vec.
## Typically applied to the body (Y-axis) and a camera/head (X-axis).

@export_group("Dependency Injection")
@export var state_packet_binding: FlowBinding
@export var camera_binding: FlowBinding

func _init() -> void:
	if not state_packet_binding:
		state_packet_binding = FlowBinding.new()
		state_packet_binding.path = ^":state_packet"
	if not camera_binding:
		camera_binding = FlowBinding.new()
		camera_binding.path = ^":camera"

@export_group("Settings")
## If true, look_vec.x rotates the actor (body) around the Y axis.
@export var rotate_actor: bool = true
## If true, look_vec.y rotates the camera around the X axis.
@export var rotate_camera: bool = true
## Vertical look limits in degrees.
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

func update(_node: Node, _delta: float, actor: Node) -> void:
	var packet: StatePacket = null
	if state_packet_binding:
		var val = state_packet_binding.get_value(actor)
		if val is StatePacket:
			packet = val
			
	if not packet or packet.look_vec == Vector2.ZERO:
		return

	# 1. Rotate Actor (Yaw)
	if rotate_actor and actor is Node3D:
		actor.rotate_y(packet.look_vec.x)

	# 2. Rotate Camera (Pitch)
	if rotate_camera and camera_binding:
		var cam = camera_binding.get_value(actor)
		if cam is Node3D:
			cam.rotate_x(packet.look_vec.y)
			cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	# 3. Consumption: Look vectors are usually relative/delta-based in this project.
	# We clear it after processing to avoid continuous rotation if the packet isn't updated.
	packet.look_vec = Vector2.ZERO
