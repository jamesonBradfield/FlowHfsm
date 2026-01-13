class_name HFSMAnimationController extends Node

## Connects the HFSM logic to a Godot AnimationTree.
## Listens to state changes and drives the AnimationNodeStateMachine via .travel().
## Also syncs Source variables to AnimationTree properties (e.g. BlendSpaces).

@export_group("References")
## The AnimationTree to control.
@export var animation_tree: AnimationTree
## The root of the HFSM.
@export var root_state: RecursiveState
## Optional: The node containing the properties to sync (usually PlayerController).
## If not set, tries to find the owner.
@export var property_source: Node

@export_group("Configuration")
## Path to the playback object in the AnimationTree.
@export var state_machine_path: String = "parameters/playback"
## Optional mapping from HFSM State Name to Animation State Name.
## If a state is not in this map, it defaults to using the HFSM State Name directly.
@export var state_to_animation_map: Dictionary = {}
## Mapping of Source Property Names to AnimationTree parameters.
## Key = Property Name (e.g. "input_direction"), Value = AnimationTree Path (e.g. "parameters/Run/blend_position")
@export var property_mapping: Dictionary = {}

## If true, attempts to read properties from the Root State's Blackboard if not found in property_source.
@export var sync_from_blackboard: bool = false

## Cache the playback object
var _playback: Variant

func _ready() -> void:
	if not animation_tree:
		push_warning("HFSMAnimationController: No AnimationTree assigned.")
	
	if not root_state:
		# Try to auto-find RootState on parent
		var parent: Node = get_parent()
		if parent:
			root_state = parent.get_node_or_null("RootState")
	
	if not property_source:
		# Try to auto-find a source
		var parent: Node = get_parent()
		if parent and parent.has_method("_process"): # Heuristic for a controller script
			property_source = parent
		elif owner:
			property_source = owner
			
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
		
	# 2. Sync Properties (Source -> AnimationTree)
	if animation_tree and not property_mapping.is_empty():
		var bb = null
		if sync_from_blackboard and root_state:
			bb = root_state.get_blackboard()

		for source_prop: String in property_mapping:
			var anim_path: String = property_mapping[source_prop]
			var value: Variant = null
			
			# Priority 1: Property Source
			if property_source:
				value = property_source.get(source_prop)
			
			# Priority 2: Blackboard (Fallback or Primary if source missing)
			if value == null and bb and bb.has_value(source_prop):
				value = bb.get_value(source_prop)
			
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
	
	# Attempt to travel
	_playback.travel(target_anim_name)

