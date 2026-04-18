class_name FlowCharacter extends CharacterBody3D

## THE UNIFIED BASE
## Handles Input, Physics, and Animation syncing automatically.
## 
## Data flows DOWN: FlowCharacter resolves a FlowDataMap into a context dict
## each frame, then passes it to the root FlowState. Behaviors/Conditions
## read from context — they never reach into actor properties directly.

@export_group("References")
@export var root_state: FlowState
@export var animation_tree: AnimationTree
@export var camera: Node3D
@export var model: Node3D

@export_group("Data Context")
## Defines what data is available in the context each frame.
## Add entries like { "move_input", "camera", "is_moving" } etc.
@export var data_map: FlowDataMap

@export_group("Physics Settings")
@export var gravity: float = 20.0
@export var ground_friction: float = 0.1
@export var air_resistance: float = 0.01
@export var terminal_velocity: float = 50.0

@export_group("Animation Settings")
@export var auto_travel_states: bool = true
@export var animation_state_machine_path: String = "parameters/playback"

# Internal
var _anim_playback: AnimationNodeStateMachinePlayback

# Public State Variables (still here programmatically, but behaviors read from context)
var state_packet: StatePacket
var last_actions: Dictionary[StringName, bool] = {}

var move_input: Vector3 = Vector3.ZERO
var is_moving: bool = false
var jump_pressed: bool = false
var jump_just_pressed: bool = false

# -- VIRTUAL: INPUT --
func _poll_input() -> void:
	if state_packet:
		var move_vec := state_packet.move_vec
		move_input.x = move_vec.x
		move_input.z = move_vec.y
		is_moving = move_input.length_squared() > 0.01
		jump_pressed = state_packet.actions.get(&"jump", false)
		jump_just_pressed = jump_pressed and not last_actions.get(&"jump", false)
		return

	var input_dir := Vector3.ZERO
	var move_vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	input_dir.x = move_vec.x
	input_dir.z = move_vec.y
	move_input = input_dir
	is_moving = move_input.length_squared() > 0.01
	jump_pressed = Input.is_action_pressed("ui_accept")
	jump_just_pressed = Input.is_action_just_pressed("ui_accept")

# -- LIFECYCLE --

func _ready() -> void:
	if not root_state:
		root_state = get_node_or_null("RootState")
	if not root_state:
		push_error("FlowCharacter: No RootState found. Please assign one.")
		set_physics_process(false)
		return

	if animation_tree:
		_anim_playback = animation_tree.get(animation_state_machine_path)
		if auto_travel_states:
			_connect_state_signals(root_state)

func _physics_process(delta: float) -> void:
	_poll_input()
	
	# Build context from data_map
	var context: Dictionary[StringName, Variant] = {}
	if data_map:
		context = data_map.resolve(self)
	
	if root_state:
		root_state.process_state(delta, self, context)
	
	_apply_physics(delta)
	
	if state_packet:
		last_actions = state_packet.actions.duplicate()

# -- PHYSICS LOGIC --

func _apply_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y < -terminal_velocity:
			velocity.y = -terminal_velocity
	
	var friction = ground_friction if is_on_floor() else air_resistance
	velocity.x = move_toward(velocity.x, 0, abs(velocity.x) * friction)
	velocity.z = move_toward(velocity.z, 0, abs(velocity.z) * friction)
	move_and_slide()

# -- ANIMATION LOGIC --

func _connect_state_signals(state: Node) -> void:
	if state.has_signal("state_entered"):
		if not state.state_entered.is_connected(_on_state_entered):
			state.state_entered.connect(_on_state_entered)
	for child in state.get_children():
		_connect_state_signals(child)

func _on_state_entered(state: Node) -> void:
	if _anim_playback:
		_anim_playback.travel(state.name)
