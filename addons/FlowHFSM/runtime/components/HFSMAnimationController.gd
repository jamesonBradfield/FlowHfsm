class_name HFSMAnimationController extends Node

## Connects the HFSM logic to a Godot AnimationTree.
## Listens to state changes and drives the AnimationNodeStateMachine.
## Syncs Smart Values (Drivers) to AnimationTree properties.

const AnimationDriver = preload("res://addons/FlowHFSM/runtime/values/AnimationDriver.gd")

@export_group("References")
## The AnimationTree to control.
@export var animation_tree: AnimationTree
## The root of the HFSM.
@export var root_state: RecursiveState

@export_group("Configuration")
## Path to the playback object in the AnimationTree.
@export var state_machine_path: String = "parameters/playback"
## Optional mapping from HFSM State Name to Animation State Name.
## If a state is not in this map, it defaults to using the HFSM State Name directly.
@export var state_to_animation_map: Dictionary = {}
## If true, only Leaf States (states with no children) will drive the animation.
## Prevents Container States (like "Grounded") from interrupting their children's animations.
@export var ignore_containers: bool = true

## List of drivers to sync values to the AnimationTree.
@export var drivers: Array[AnimationDriver] = []

## Cache the playback object
var _playback: Variant
var _blackboard: Blackboard

func _ready() -> void:
	if not animation_tree:
		push_warning("HFSMAnimationController: No AnimationTree assigned.")
	
	if not root_state:
		# Try to auto-find RootState on parent
		var parent: Node = get_parent()
		if parent:
			root_state = parent.get_node_or_null("RootState")
	
	if root_state:
		# Connect to all states in the hierarchy
		_connect_signals_recursive(root_state)
		
		if root_state.has_method("get_blackboard"):
			_blackboard = root_state.get_blackboard()
	else:
		push_warning("HFSMAnimationController: No RootState found.")

func _process(_delta: float) -> void:
	# 1. Cache playback object if needed
	if animation_tree and animation_tree.active and not _playback:
		var playback_obj: Variant = animation_tree.get(state_machine_path)
		# Allow duck typing for mocks
		if playback_obj and (playback_obj is AnimationNodeStateMachinePlayback or playback_obj.has_method("travel")):
			_playback = playback_obj
		
	# 2. Sync Drivers
	if animation_tree and not drivers.is_empty():
		# Determine actor (usually the owner or parent)
		var actor = owner if owner else get_parent()
		
		for driver in drivers:
			if driver:
				driver.apply(actor, _blackboard, animation_tree)

## Recursively connects to state_entered signals
func _connect_signals_recursive(state: RecursiveState) -> void:
	if not state.state_entered.is_connected(_on_state_entered):
		state.state_entered.connect(_on_state_entered)
	
	for child in state.get_children():
		if child is RecursiveState:
			_connect_signals_recursive(child)

## Triggered when ANY state in the HFSM is entered
func _on_state_entered(state: RecursiveState) -> void:
	if not animation_tree:
		return
		
	# Auto-activate if needed
	if not animation_tree.active:
		animation_tree.active = true
		
	if not _playback:
		var playback_obj: Variant = animation_tree.get(state_machine_path)
		# Allow duck typing for mocks
		if playback_obj and (playback_obj is AnimationNodeStateMachinePlayback or playback_obj.has_method("travel")):
			_playback = playback_obj
		
	if not _playback:
		return

	# Determine the target animation state name
	var target_anim_name: String = state.name
	if state_to_animation_map.has(state.name):
		target_anim_name = state_to_animation_map[state.name]
	
	# Filter Containers if requested
	# logic: If ignore_containers is true AND state has children AND it's not explicitly mapped... SKIP.
	# We allow explicitly mapped containers because the user might WANT "Grounded" to play a specific blend tree.
	if ignore_containers and state.get_child_count() > 0 and not state_to_animation_map.has(state.name):
		return

	# Attempt to travel
	_playback.travel(target_anim_name)
