class_name HFSMAnimationController extends Node

## Connects the HFSM logic to a Godot AnimationTree.
## Listens to state changes and drives the AnimationNodeStateMachine via .travel().
## Also syncs Blackboard variables to AnimationTree properties (e.g. BlendSpaces).

@export_group("References")
## The AnimationTree to control.
@export var animation_tree: AnimationTree
## The root of the HFSM.
@export var root_state: RecursiveState
## Optional: The node containing the blackboard (usually PlayerController).
## If not set, tries to find a 'blackboard' property on the owner or parent.
@export var blackboard_source: Node:
	set(value):
		blackboard_source = value
		_refresh_blackboard_cache()

@export_group("Configuration")
## Path to the playback object in the AnimationTree.
@export var state_machine_path: String = "parameters/playback"
## Optional mapping from HFSM State Name to Animation State Name.
## If a state is not in this map, it defaults to using the HFSM State Name directly.
@export var state_to_animation_map: Dictionary = {}
## Mapping of Blackboard Keys to AnimationTree parameters.
## Key = Blackboard Key (e.g. "input_dir"), Value = AnimationTree Path (e.g. "parameters/Run/blend_position")
@export var property_mapping: Dictionary = {}

## Cache the playback object
var _playback: Variant
## Cached reference to the blackboard dictionary to avoid get() calls every frame
var _blackboard: Dictionary = {}

func _ready() -> void:
	if not animation_tree:
		push_warning("HFSMAnimationController: No AnimationTree assigned.")
	
	if not root_state:
		# Try to auto-find RootState on parent
		var parent: Node = get_parent()
		if parent:
			root_state = parent.get_node_or_null("RootState")
	
	if not blackboard_source:
		# Try to auto-find a source with a blackboard
		var parent: Node = get_parent()
		if parent and "blackboard" in parent:
			blackboard_source = parent
		elif owner and "blackboard" in owner:
			blackboard_source = owner
			
	# Cache the blackboard reference if possible
	_refresh_blackboard_cache()

	if root_state:
		# Connect to all states in the hierarchy
		_connect_signals_recursive(root_state)
	else:
		push_warning("HFSMAnimationController: No RootState found.")

func _process(_delta: float) -> void:
	# 1. Cache playback object if needed
	if animation_tree and animation_tree.active and not _playback:
		var playback_obj: Variant = animation_tree.get(state_machine_path)
		# Allow duck typing for mocks
		if playback_obj and (playback_obj is AnimationNodeStateMachinePlayback or playback_obj.has_method("travel")):
			_playback = playback_obj
		
	# 2. Sync Properties (Blackboard -> AnimationTree)
	if animation_tree and not _blackboard.is_empty() and not property_mapping.is_empty():
		for bb_key: Variant in property_mapping:
			var anim_path: String = property_mapping[bb_key]
			var value: Variant = _blackboard.get(bb_key)
			
			if value != null:
				animation_tree.set(anim_path, value)

## Recursively connects to state_entered signals
func _connect_signals_recursive(state: RecursiveState) -> void:
	if not state.state_entered.is_connected(_on_state_entered):
		state.state_entered.connect(_on_state_entered)
	
	for child in state.get_children():
		if child is RecursiveState:
			_connect_signals_recursive(child)

## Triggered when ANY state in the HFSM is entered
func _on_state_entered(state: RecursiveState) -> void:
	if not animation_tree or not animation_tree.active:
		return
		
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
	
	# Attempt to travel
	_playback.travel(target_anim_name)

func _refresh_blackboard_cache() -> void:
	if blackboard_source:
		var bb: Variant = blackboard_source.get("blackboard")
		if bb is Dictionary:
			_blackboard = bb
		else:
			push_warning("HFSMAnimationController: Blackboard source found, but 'blackboard' property is not a Dictionary.")
			_blackboard = {}
	else:
		_blackboard = {}
