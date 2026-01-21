class_name StateDebugger extends Node

## A UI-based debug tool for FlowHFSM.
## Displays the active state hierarchy, memory, and blackboard variables.
## Automatically creates a CanvasLayer overlay.

@export_group("References")
## The root state to monitor.
@export var root_state: RecursiveState
## Optional: Link to the PlayerController to view the global Blackboard.
@export var player_controller: Node

@export_group("Display Settings")
## If true, shows the full path of behaviors attached to states.
@export var show_behaviors: bool = false
## If true, shows the memory of the active leaf state.
@export var show_memory: bool = true
## If true, shows blackboard variables.
@export var show_blackboard: bool = true

# UI Components
var _canvas: CanvasLayer
var _label: RichTextLabel
var _panel: PanelContainer

func _ready() -> void:
	_setup_ui()
	
	# Auto-discovery
	if not root_state:
		# 1. Try parent
		if get_parent() is RecursiveState:
			root_state = get_parent()
		# 2. Try sibling "RootState"
		elif get_parent().has_node("RootState"):
			root_state = get_parent().get_node("RootState")
			
	if not player_controller:
		# Try to find a sibling PlayerController
		var p: Node = get_parent()
		if p:
			for child in p.get_children():
				if child.name == "PlayerController" or child.get_script().resource_path.ends_with("PlayerController.gd"):
					player_controller = child
					break

func _setup_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "StateDebuggerOverlay"
	add_child(_canvas)
	
	_panel = PanelContainer.new()
	_panel.name = "DebugPanel"
	_canvas.add_child(_panel)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8) # Dark semi-transparent
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	
	# Position: Top-Left with some margin
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(20, 20)
	
	_label = RichTextLabel.new()
	_label.name = "DebugText"
	_label.fit_content = true
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size = Vector2(300, 0)
	_label.bbcode_enabled = false # Explicitly disable BBCode
	_panel.add_child(_label)

func _process(_delta: float) -> void:
	if not root_state:
		_label.text = "StateDebugger: No Root Linked"
		return
		
	var sb: String = ""
	
	# 1. Hierarchy Path
	sb += "Active State:\n"
	sb += _get_active_path_text(root_state)
	sb += "\n"
	
	# 2. Leaf Memory
	if show_memory:
		sb += "\nLeaf Memory:\n"
		sb += "%s\n" % _get_leaf_data(root_state)
	
	# 3. Blackboard
	if show_blackboard and player_controller:
		var bb_data: String = "N/A"
		var bb: Blackboard = null
		
		# Duck typing for getting blackboard
		if player_controller.has_method("get_blackboard"):
			bb = player_controller.get_blackboard()
		elif "_blackboard" in player_controller:
			bb = player_controller._blackboard
			
		if bb:
			bb_data = str(bb.get_data())
			
		sb += "\nBlackboard:\n"
		sb += "%s" % bb_data
		
	_label.text = sb

func _get_active_path_text(node: RecursiveState) -> String:
	var state_name: String = node.name
	
	if show_behaviors and not node.behaviors.is_empty():
		var b_names: PackedStringArray = []
		for b: StateBehavior in node.behaviors:
			if not b: continue
			var b_name: String = b.resource_path.get_file().get_basename()
			if b_name.is_empty(): b_name = "Embedded"
			b_names.append(b_name)
		
		if not b_names.is_empty():
			state_name += " (%s)" % ", ".join(b_names)
		
	if node.active_child:
		return state_name + " > " + _get_active_path_text(node.active_child)
	
	return state_name

func _get_leaf_data(node: RecursiveState) -> String:
	if node.active_child:
		return _get_leaf_data(node.active_child)
	
	if node.memory.is_empty():
		return "{ }"
	return str(node.memory)
