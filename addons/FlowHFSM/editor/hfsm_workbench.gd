@tool
extends VBoxContainer

## HFSM Workbench
##
## A persistent bottom panel tool for FlowHFSM.
## Replaces the old Asset Creation Wizard.
##
## Modes:
## 1. Dashboard (No Selection): Create new Scripts (Behavior/Condition).
## 2. Context (State Selected): Create Child States, Manage Variables (Future).

enum WorkbenchMode { DASHBOARD, CONTEXT_STATE }
enum CreationMode { TEMPLATE, DUPLICATE, EXTEND, NODE }

var current_mode: WorkbenchMode = WorkbenchMode.DASHBOARD
var current_creation_mode: CreationMode = CreationMode.TEMPLATE
var base_type: String = "StateBehavior"
var selected_source_path: String = ""
var active_node: Node = null

# UI Components
var main_container: VBoxContainer
var header_label: Label
var content_container: VBoxContainer

# Dashboard UI
var dashboard_container: HBoxContainer

# Context UI
var context_container: VBoxContainer

# Shared Config UI
var config_container: VBoxContainer
var class_name_edit: LineEdit
var folder_edit: LineEdit
var preview_edit: CodeEdit
var create_btn: Button
var error_label: Label

# STATIC PERSISTENCE
static var _last_used_behavior_folder: String = ""
static var _last_used_condition_folder: String = ""

# --- FILESYSTEM SYNC ---
func _wait_for_file_system(path: String) -> bool:
	var retries = 0
	while not FileAccess.file_exists(path) and retries < 20:
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(self): return false
		retries += 1
		
	EditorInterface.get_resource_filesystem().scan()
	
	retries = 0
	while EditorInterface.get_resource_filesystem().get_file_type(path).is_empty() and retries < 20:
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(self): return false
		retries += 1
		
	return true

func _ready() -> void:
	# VISUAL DOCTRINE: Look like Godot
	# We rely on Editor Theme
	
	# Layout
	add_theme_constant_override("separation", 0)
	
	# 1. Header / Toolbar
	var toolbar = HBoxContainer.new()
	toolbar.custom_minimum_size.y = 30
	add_child(toolbar)
	
	header_label = Label.new()
	header_label.text = "HFSM Workbench"
	header_label.add_theme_font_size_override("font_size", 16)
	toolbar.add_child(header_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	toolbar.add_child(spacer)
	
	# 2. Main Content Area
	content_container = VBoxContainer.new()
	content_container.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(content_container)
	
	_build_dashboard_ui()
	_build_context_ui() # Pre-build but hide
	_build_config_ui()  # The form for input
	
	# Initial State
	_on_selection_changed()
	
	# Monitor Selection
	# EditorSelection isn't a node, so we can't connect easily in tool script 
	# without passing the plugin reference or polling.
	# Polling is safer for simple tool scripts.
	set_process(true)

func _process(delta: float) -> void:
	_check_selection()

var _last_selected_node: Node = null

func _check_selection() -> void:
	var selection = EditorInterface.get_selection().get_selected_nodes()
	var node = selection[0] if not selection.is_empty() else null
	
	if node != _last_selected_node:
		_last_selected_node = node
		_on_selection_changed()

func _on_selection_changed() -> void:
	active_node = _last_selected_node
	
	# Determine Mode
	if active_node and active_node.is_class("Node") and (active_node.get_script() and active_node.get_script().resource_path.ends_with("RecursiveState.gd")):
		_switch_to_context_mode(active_node)
	else:
		_switch_to_dashboard_mode()

func _switch_to_dashboard_mode() -> void:
	current_mode = WorkbenchMode.DASHBOARD
	header_label.text = "Workbench: Dashboard"
	dashboard_container.visible = true
	context_container.visible = false
	config_container.visible = false # Hide config until an action is clicked

func _switch_to_context_mode(node: Node) -> void:
	current_mode = WorkbenchMode.CONTEXT_STATE
	header_label.text = "Workbench: Editing " + node.name
	dashboard_container.visible = false
	context_container.visible = true
	config_container.visible = false
	
	# Auto-setup for Node creation if we are in context mode?
	# Maybe show a summary first?
	# For now, let's show the "Add Child State" button in context container

func _build_dashboard_ui() -> void:
	dashboard_container = HBoxContainer.new()
	dashboard_container.alignment = BoxContainer.ALIGNMENT_CENTER
	dashboard_container.add_theme_constant_override("separation", 20)
	dashboard_container.size_flags_vertical = SIZE_EXPAND_FILL
	content_container.add_child(dashboard_container)
	
	_create_card(dashboard_container, "New Behavior", "Create stateless logic.", func(): _setup_config(CreationMode.TEMPLATE, "StateBehavior"))
	_create_card(dashboard_container, "New Condition", "Create logic gate.", func(): _setup_config(CreationMode.TEMPLATE, "StateCondition"))
	# _create_card(dashboard_container, "Duplicate", "Clone existing.", func(): _setup_config(CreationMode.DUPLICATE, "StateBehavior")) # Defaulting type?
	
func _build_context_ui() -> void:
	context_container = VBoxContainer.new()
	context_container.visible = false
	context_container.size_flags_vertical = SIZE_EXPAND_FILL
	content_container.add_child(context_container)
	
	var btn_add_child = Button.new()
	btn_add_child.text = "+ Add Child State"
	btn_add_child.custom_minimum_size = Vector2(200, 40)
	btn_add_child.pressed.connect(func(): _setup_config(CreationMode.NODE, "RecursiveState"))
	
	var center = CenterContainer.new()
	center.size_flags_vertical = SIZE_EXPAND_FILL
	center.add_child(btn_add_child)
	context_container.add_child(center)

func _create_card(parent: Control, title: String, desc: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 100)
	btn.pressed.connect(callback)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = title
	vbox.add_child(lbl)
	
	var lbl_d = Label.new()
	lbl_d.text = desc
	lbl_d.modulate = Color(0.7, 0.7, 0.7)
	lbl_d.add_theme_font_size_override("font_size", 10)
	vbox.add_child(lbl_d)
	
	parent.add_child(btn)

func _build_config_ui() -> void:
	config_container = VBoxContainer.new()
	config_container.visible = false
	config_container.size_flags_vertical = SIZE_EXPAND_FILL
	content_container.add_child(config_container)
	
	# Back Button
	var btn_back = Button.new()
	btn_back.text = "< Back"
	btn_back.pressed.connect(func(): 
		config_container.visible = false
		if current_mode == WorkbenchMode.DASHBOARD:
			dashboard_container.visible = true
		else:
			context_container.visible = true
	)
	config_container.add_child(btn_back)
	
	# Form
	var grid = GridContainer.new()
	grid.columns = 2
	config_container.add_child(grid)
	
	# Name
	var lbl_name = Label.new()
	lbl_name.text = "Name:"
	lbl_name.name = "LblName"
	grid.add_child(lbl_name)
	
	class_name_edit = LineEdit.new()
	class_name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	class_name_edit.text_changed.connect(func(_t): _update_preview())
	grid.add_child(class_name_edit)
	
	# Folder
	var lbl_folder = Label.new()
	lbl_folder.text = "Folder:"
	lbl_folder.name = "LblFolder"
	grid.add_child(lbl_folder)
	
	var folder_box = HBoxContainer.new()
	folder_box.size_flags_horizontal = SIZE_EXPAND_FILL
	folder_edit = LineEdit.new()
	folder_edit.text = "res://"
	folder_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	folder_box.add_child(folder_edit)
	grid.add_child(folder_box)
	
	# Options (Behavior creation)
	var lbl_opt = Label.new()
	lbl_opt.text = "Option:"
	lbl_opt.name = "LblOption" # Used to toggle visibility
	grid.add_child(lbl_opt)
	
	var opt_tmpl = OptionButton.new()
	opt_tmpl.name = "OptTemplate"
	opt_tmpl.size_flags_horizontal = SIZE_EXPAND_FILL
	opt_tmpl.add_item("Empty State")
	opt_tmpl.add_item("With New Behavior")
	opt_tmpl.item_selected.connect(func(_i): _update_preview())
	grid.add_child(opt_tmpl)
	
	# Preview
	preview_edit = CodeEdit.new()
	preview_edit.size_flags_vertical = SIZE_EXPAND_FILL
	preview_edit.editable = false
	preview_edit.add_theme_color_override("background_color", Color(0.1, 0.1, 0.1))
	config_container.add_child(preview_edit)
	
	# Error
	error_label = Label.new()
	error_label.modulate = Color(1, 0.4, 0.4)
	config_container.add_child(error_label)
	
	# Create Button
	create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.pressed.connect(_on_create_pressed)
	config_container.add_child(create_btn)

func _setup_config(mode: CreationMode, type: String) -> void:
	current_creation_mode = mode
	base_type = type
	
	dashboard_container.visible = false
	context_container.visible = false
	config_container.visible = true
	
	class_name_edit.text = ""
	class_name_edit.grab_focus()
	
	# Labels
	var lbl_name = config_container.find_child("LblName", true, false)
	if mode == CreationMode.NODE:
		lbl_name.text = "State Node Name:"
		config_container.find_child("LblFolder").visible = false
		config_container.find_child("LblOption").visible = true
		config_container.find_child("OptTemplate").visible = true
		folder_edit.get_parent().visible = false
	else:
		lbl_name.text = "Script Name:"
		config_container.find_child("LblFolder").visible = true
		folder_edit.get_parent().visible = true
		config_container.find_child("LblOption").visible = false
		config_container.find_child("OptTemplate").visible = false
		
		# Set default folder
		if type == "StateBehavior" and not _last_used_behavior_folder.is_empty():
			folder_edit.text = _last_used_behavior_folder
		elif type == "StateCondition" and not _last_used_condition_folder.is_empty():
			folder_edit.text = _last_used_condition_folder
	
	_update_preview()

func _update_preview() -> void:
	var c_name = class_name_edit.text.strip_edges()
	create_btn.disabled = c_name.is_empty()
	
	if current_creation_mode == CreationMode.NODE:
		var opt = config_container.find_child("OptTemplate", true, false)
		var with_behavior = (opt and opt.get_item_text(opt.selected) == "With New Behavior")
		
		# Dynamic UI: Show folder if behavior is selected
		var show_folder = with_behavior
		config_container.find_child("LblFolder").visible = show_folder
		folder_edit.get_parent().visible = show_folder
		
		var msg = "Plan:\n"
		msg += "1. Create RecursiveState node named '%s'.\n" % c_name
		if with_behavior:
			msg += "2. Create behavior script '%sBehavior.gd' in %s.\n" % [c_name, folder_edit.text]
		preview_edit.text = msg
		return

	# Script Generation Preview
	if base_type == "RecursiveState":
		preview_edit.text = "# STOP! RecursiveState is SEALED."
		create_btn.disabled = true
		return
		
	var code = "class_name %s extends %s\n\n" % [c_name if not c_name.is_empty() else "MyClass", base_type]
	code += "func enter(node, actor, blackboard): pass\n"
	code += "func update(node, delta, actor, blackboard): pass\n"
	code += "func exit(node, actor, blackboard): pass\n"
	preview_edit.text = code

func _on_create_pressed() -> void:
	if current_creation_mode == CreationMode.NODE:
		_create_node()
	else:
		_create_script()

func _create_script() -> void:
	var c_name = class_name_edit.text.strip_edges()
	var folder = folder_edit.text
	if not folder.ends_with("/"): folder += "/"
	var path = folder + c_name + ".gd"
	
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(preview_edit.text)
		f.close()
		
		if await _wait_for_file_system(path):
			var scr = load(path)
			var res = scr.new()
			var res_path = folder + c_name + ".tres"
			ResourceSaver.save(res, res_path)
			EditorInterface.get_resource_filesystem().scan()
			EditorInterface.edit_resource(scr)
			
			# Save folder pref
			if base_type == "StateBehavior": _last_used_behavior_folder = folder
			elif base_type == "StateCondition": _last_used_condition_folder = folder
			
			# Reset
			config_container.visible = false
			dashboard_container.visible = true

func _create_node() -> void:
	var state_name = class_name_edit.text.strip_edges()
	if not active_node: return
	
	var new_node = load("res://addons/FlowHFSM/runtime/RecursiveState.gd").new()
	new_node.name = state_name
	
	var root = EditorInterface.get_edited_scene_root()
	var undo = EditorInterface.get_editor_undo_redo()
	
	undo.create_action("Add Child State")
	undo.add_do_method(active_node, "add_child", new_node)
	undo.add_do_method(new_node, "set_owner", root)
	undo.add_undo_method(active_node, "remove_child", new_node)
	undo.commit_action()
	
	# Behavior logic
	var opt = config_container.find_child("OptTemplate", true, false)
	var with_behavior = (opt and opt.get_item_text(opt.selected) == "With New Behavior")
	
	if with_behavior:
		var b_name = state_name + "Behavior"
		var folder = folder_edit.text
		if not folder.ends_with("/"): folder += "/"
		var code = "class_name " + b_name + " extends StateBehavior\n\nfunc enter(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc update(node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc exit(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n"
		var path = folder + b_name + ".gd"
		
		var f = FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(code)
			f.close()
			if await _wait_for_file_system(path):
				var scr = load(path)
				var res = scr.new()
				var res_path = folder + b_name + ".tres"
				ResourceSaver.save(res, res_path)
				EditorInterface.get_resource_filesystem().scan()
				
				# Assign
				undo.create_action("Assign Behavior")
				undo.add_do_property(new_node, "behaviors", [res])
				undo.add_undo_property(new_node, "behaviors", [])
				undo.commit_action()
	
	# Reset
	config_container.visible = false
	context_container.visible = true
