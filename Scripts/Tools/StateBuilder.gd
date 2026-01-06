@tool
extends Node

## A helper tool to build State Machines in the Editor.
## Attach this to a node in your scene (e.g. "StateBuilder") to use it.

# signal status_changed(msg: String) # Not used yet

# --- CONFIGURATION ---
@export_group("1. Target State")
## The state node you want to modify.
@export var target_state: RecursiveState:
	set(value):
		target_state = value
		_update_status()

@export_group("2. Add Conditions")
## Select conditions to form the activation gate.
## (This list is populated by scanning 'res://Resources/conditions')
@export var available_conditions: Array[StateCondition] = []
## Click to scan project for conditions.
@export var scan_conditions_button: bool = false : set = _scan_conditions
## Conditions selected for the state activation.
@export var selected_conditions: Array[StateCondition] = []
## How to combine them (AND/OR).
@export var activation_mode: RecursiveState.ActivationMode = RecursiveState.ActivationMode.AND
## Click to apply conditions to the Target State.
@export var apply_conditions_button: bool = false : set = _apply_conditions

@export_group("3. Create New State")
## Name for the new state node.
@export var new_state_name: String = "NewState"
## Create a new RecursiveState as a child of the Target State (or Root if Target is null).
@export var create_state_button: bool = false : set = _create_state

@export_group("Utils")
@export var debug_output: String = ""

func _ready():
	if Engine.is_editor_hint():
		_scan_conditions(true)

func _update_status():
	if target_state:
		debug_output = "Target: %s" % target_state.name
	else:
		debug_output = "No Target Selected"

# --- SCANNING ---

func _scan_conditions(_val):
	if not _val: return
	
	print("[StateBuilder] Scanning for conditions...")
	available_conditions.clear()
	
	var path = "res://Resources/conditions"
	_recursive_scan(path)
	
	debug_output = "Found %d conditions." % available_conditions.size()
	scan_conditions_button = false # Reset toggle

func _recursive_scan(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					_recursive_scan(path + "/" + file_name)
			else:
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var res = load(path + "/" + file_name)
					if res is StateCondition:
						available_conditions.append(res)
			file_name = dir.get_next()
	else:
		print("[StateBuilder] Could not open directory: " + path)

# --- CONDITION ASSIGNMENT ---

func _apply_conditions(_val):
	if not _val: return
	apply_conditions_button = false # Reset
	
	if not target_state:
		printerr("[StateBuilder] No Target State selected!")
		return
		
	# Update State
	target_state.activation_conditions = selected_conditions.duplicate()
	target_state.activation_mode = activation_mode
	
	print("[StateBuilder] Applied %d conditions to '%s' (Mode: %s)." % [selected_conditions.size(), target_state.name, RecursiveState.ActivationMode.keys()[activation_mode]])
	
	# Mark as dirty so editor saves it
	_mark_scene_dirty()

# --- STATE CREATION ---

func _create_state(_val):
	if not _val: return
	create_state_button = false
	
	var parent = target_state
	if not parent:
		# Try to find a root or use self's parent
		parent = get_node("../") # Assuming builder is in the scene
		
	if not parent:
		printerr("[StateBuilder] No parent found to add state to.")
		return
		
	var new_node = RecursiveState.new()
	new_node.name = new_state_name
	
	parent.add_child(new_node)
	new_node.owner = get_tree().edited_scene_root
	
	print("[StateBuilder] Created state '%s' under '%s'." % [new_state_name, parent.name])
	
	# Auto-select the new state
	target_state = new_node
	_mark_scene_dirty()

func _mark_scene_dirty():
	# Note: Accessing EditorInterface from a generic tool script in the scene 
	# might be restricted or require the script to be an EditorPlugin. 
	# For a simple @tool script in the scene tree, modifying the node is usually enough 
	# for the editor to detect changes if properties are exported.
	pass
