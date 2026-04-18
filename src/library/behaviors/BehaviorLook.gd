@tool
class_name BehaviorLook extends FlowBehavior

## THE LOOK BEHAVIOR
## Handles looking around using state_packet.look_vec.
##
## Reads from context dict (pushed from FlowDataMap):
##   "state_packet" → StatePacket (required)
##   "camera"       → Node3D     (optional, for pitch rotation)

@export_group("Context Keys")
@export var state_packet_key: StringName = &"state_packet"
@export var camera_key: StringName = &"camera"

@export_group("Settings")
@export var rotate_actor: bool = true
@export var rotate_camera: bool = true
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

func update(_node: Node, _delta: float, actor: Node, context: Dictionary[StringName, Variant]) -> void:
	var packet: StatePacket = null
	if context.has(state_packet_key):
		var val = context[state_packet_key]
		if val is StatePacket:
			packet = val
			
	if not packet or packet.look_vec == Vector2.ZERO:
		return

	# 1. Rotate Actor (Yaw)
	if rotate_actor and actor is Node3D:
		actor.rotate_y(packet.look_vec.x)

	# 2. Rotate Camera (Pitch)
	if rotate_camera and context.has(camera_key):
		var cam = context[camera_key]
		if cam is Node3D:
			cam.rotate_x(packet.look_vec.y)
			cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	# 3. Consumption
	packet.look_vec = Vector2.ZERO
