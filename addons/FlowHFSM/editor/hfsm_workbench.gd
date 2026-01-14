@tool
extends VBoxContainer

## HFSM Workbench
##
## Persistent bottom panel for FlowHFSM.
## Handles Asset Creation (Dashboard) and State Editing (Context).

enum WorkbenchMode { DASHBOARD, CONTEXT_STATE }
enum CreationMode { TEMPLATE, DUPLICATE, EXTEND, NODE }

var current_mode: WorkbenchMode = WorkbenchMode.DASHBOARD
var current_creation_mode: CreationMode = CreationMode.TEMPLATE
var base_type: String = "StateBehavior"
var selected_source_path: String = ""
var active_node: Node = null
var folded_states: Dictionary = {} # Resource ID -> bool for context editor

# UI Components
var header_label: Label
var content_container: VBoxContainer

# Dashboard UI
var dashboard_container: ScrollContainer
var dashboard_cards: HBoxContainer

# Context UI
var context_container: ScrollContainer
var context_vbox: VBoxContainer
var context_variables_container: VBoxContainer
var context_behaviors_container: VBoxContainer

# Config UI
var config_container: VBoxContainer
var class_name_edit: LineEdit
var folder_edit: LineEdit
var preview_edit: CodeEdit
var create_btn: Button
var error_label: Label
var file_dialog: EditorFileDialog
var script_dialog: EditorFileDialog

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
	# Layout
	add_theme_constant_override("separation", 0)
	
	# 1. Header / Toolbar
	var toolbar = HBoxContainer.new()
	toolbar.custom_minimum_size.y = 30
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_header_background())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toolbar.add_child(panel)
	# But Panel inside HBox doesn't work like that for background. 
	# Let's just wrap toolbar in a PanelContainer or Margin.
	# Actually, simpler: just add children to toolbar.
	
	var header_panel = PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_header_background())
	add_child(header_panel)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.custom_minimum_size.y = 30
	header_panel.add_child(header_hbox)
	
	var spacer_l = Control.new()
	spacer_l.custom_minimum_size.x = 10
	header_hbox.add_child(spacer_l)
	
	header_label = Label.new()
	header_label.text = "HFSM Workbench"
	header_label.add_theme_font_size_override("font_size", 16)
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_hbox.add_child(header_label)
	
	# 2. Main Content Area
	content_container = VBoxContainer.new()
	content_container.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(content_container)
	
	_build_dashboard_ui()
	_build_context_ui()
	_build_config_ui()
	
	# Dialogs
	file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.dir_selected.connect(func(d): folder_edit.text = d)
	add_child(file_dialog)
	
	script_dialog = EditorFileDialog.new()
	script_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	script_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	script_dialog.filters = ["*.gd ; GDScript"]
	script_dialog.file_selected.connect(func(p): 
		selected_source_path = p
		var src_edit = config_container.find_child("EditSource", true, false)
		if src_edit: src_edit.text = p
		_update_preview()
	)
	add_child(script_dialog)
	
	# Initial State
	_on_selection_changed()
	
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
	elif active_node and not is_instance_valid(active_node):
		# Node deleted
		_last_selected_node = null
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
	config_container.visible = false 

func _switch_to_context_mode(node: Node) -> void:
	current_mode = WorkbenchMode.CONTEXT_STATE
	header_label.text = "Workbench: Editing " + node.name
	dashboard_container.visible = false
	context_container.visible = true
	config_container.visible = false
	
	_refresh_context_ui()

# --- DASHBOARD UI ---

func _build_dashboard_ui() -> void:
	dashboard_container = ScrollContainer.new()
	dashboard_container.size_flags_vertical = SIZE_EXPAND_FILL
	content_container.add_child(dashboard_container)
	
	var center = CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	dashboard_container.add_child(center)
	
	dashboard_cards = HBoxContainer.new()
	dashboard_cards.add_theme_constant_override("separation", 20)
	center.add_child(dashboard_cards)
	
	_create_card(dashboard_cards, "New Behavior", "Create stateless logic.", "New", func(): _setup_config(CreationMode.TEMPLATE, "StateBehavior"))
	_create_card(dashboard_cards, "New Condition", "Create logic gate.", "New", func(): _setup_config(CreationMode.TEMPLATE, "StateCondition"))
	_create_card(dashboard_cards, "Duplicate", "Clone existing script.", "Duplicate", func(): _setup_config(CreationMode.DUPLICATE, "StateBehavior"))
	_create_card(dashboard_cards, "Extend", "Inherit from existing.", "ScriptExtend", func(): _setup_config(CreationMode.EXTEND, "StateBehavior"))

func _create_card(parent: Control, title: String, desc: String, icon_name: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 140)
	btn.pressed.connect(callback)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 10)
	btn.add_child(vbox)
	
	var icon = TextureRect.new()
	icon.texture = get_theme_icon(icon_name, "EditorIcons")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	vbox.add_child(icon)
	
	var lbl = Label.new()
	lbl.text = title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	var lbl_d = Label.new()
	lbl_d.text = desc
	lbl_d.modulate = Color(0.7, 0.7, 0.7)
	lbl_d.add_theme_font_size_override("font_size", 10)
	lbl_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_d)
	
	parent.add_child(btn)

# --- CONTEXT UI ---

func _build_context_ui() -> void:
	context_container = ScrollContainer.new()
	context_container.visible = false
	context_container.size_flags_vertical = SIZE_EXPAND_FILL
	content_container.add_child(context_container)
	
	context_vbox = VBoxContainer.new()
	context_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	context_vbox.add_theme_constant_override("separation", 20)
	context_container.add_child(context_vbox)
	
	# Margins
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	context_vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(inner_vbox)
	
	# 1. Child State Creation
	var btn_add_child = Button.new()
	btn_add_child.text = "+ Add Child State"
	btn_add_child.custom_minimum_size = Vector2(0, 40)
	btn_add_child.pressed.connect(func(): _setup_config(CreationMode.NODE, "RecursiveState"))
	inner_vbox.add_child(btn_add_child)
	
	# 2. Variables Section
	inner_vbox.add_child(_create_section_header("State Variables", "Memory definitions for this state."))
	context_variables_container = VBoxContainer.new()
	inner_vbox.add_child(context_variables_container)
	
	var btn_add_var = Button.new()
	btn_add_var.text = "Add Variable"
	btn_add_var.icon = get_theme_icon("Add", "EditorIcons")
	btn_add_var.pressed.connect(_on_add_variable_pressed)
	inner_vbox.add_child(btn_add_var)
	
	# 3. Behaviors Section
	inner_vbox.add_child(HSeparator.new())
	inner_vbox.add_child(_create_section_header("Behaviors", "Logic resources attached to this state."))
	context_behaviors_container = VBoxContainer.new()
	inner_vbox.add_child(context_behaviors_container)
	
	var btn_add_beh = Button.new()
	btn_add_beh.text = "Add Behavior"
	btn_add_beh.icon = get_theme_icon("Add", "EditorIcons")
	btn_add_beh.pressed.connect(_on_add_behavior_pressed)
	inner_vbox.add_child(btn_add_beh)

func _create_section_header(text: String, tooltip: String) -> Control:
	var vbox = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.tooltip_text = tooltip
	vbox.add_child(lbl)
	return vbox

func _refresh_context_ui() -> void:
	if not active_node: return
	
	# Clear lists
	for c in context_variables_container.get_children(): c.queue_free()
	for c in context_behaviors_container.get_children(): c.queue_free()
	
	# Draw Variables
	var vars = active_node.get("declared_variables")
	if vars == null: vars = []
	for i in range(vars.size()):
		_draw_variable_row(vars[i], i)
		
	# Draw Behaviors
	var behs = active_node.get("behaviors")
	if behs == null: behs = []
	for i in range(behs.size()):
		_draw_behavior_row(behs[i], i)

func _draw_variable_row(variable: Resource, index: int) -> void:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_card_style())
	context_variables_container.add_child(card)
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var is_folded = false
	if variable: is_folded = folded_states.get(variable.get_instance_id(), false)
	
	var fold_btn = HFSMPropertyFactory.create_fold_button(is_folded, func():
		if variable:
			folded_states[variable.get_instance_id()] = not is_folded
			_refresh_context_ui()
	)
	fold_btn.disabled = (variable == null)
	header.add_child(fold_btn)
	
	var picker = EditorResourcePicker.new()
	picker.base_type = "StateVariable"
	picker.edited_resource = variable
	picker.size_flags_horizontal = SIZE_EXPAND_FILL
	picker.resource_changed.connect(func(res): _on_variable_changed(res, index))
	header.add_child(picker)
	
	var del_btn = Button.new()
	del_btn.icon = get_theme_icon("Remove", "EditorIcons")
	del_btn.flat = true
	del_btn.pressed.connect(func(): _on_remove_variable(index))
	header.add_child(del_btn)
	
	# Body
	if variable and not is_folded:
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		var props = HFSMPropertyFactory.create_property_list(variable, func(p, v): _on_variable_prop_changed(variable, p, v))
		margin.add_child(props)
		vbox.add_child(margin)

func _draw_behavior_row(behavior: Resource, index: int) -> void:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_card_style(Color(0.18, 0.20, 0.25, 1.0)))
	context_behaviors_container.add_child(card)
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var is_folded = false
	if behavior: is_folded = folded_states.get(behavior.get_instance_id(), false)
	
	var fold_btn = HFSMPropertyFactory.create_fold_button(is_folded, func():
		if behavior:
			folded_states[behavior.get_instance_id()] = not is_folded
			_refresh_context_ui()
	)
	fold_btn.disabled = (behavior == null)
	header.add_child(fold_btn)
	
	var picker = EditorResourcePicker.new()
	picker.base_type = "StateBehavior"
	picker.edited_resource = behavior
	picker.size_flags_horizontal = SIZE_EXPAND_FILL
	picker.resource_changed.connect(func(res): _on_behavior_changed(res, index))
	header.add_child(picker)
	
	var del_btn = Button.new()
	del_btn.icon = get_theme_icon("Remove", "EditorIcons")
	del_btn.flat = true
	del_btn.pressed.connect(func(): _on_remove_behavior(index))
	header.add_child(del_btn)
	
	# Body
	if behavior and not is_folded:
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		var props = HFSMPropertyFactory.create_property_list(behavior, func(p, v): _on_behavior_prop_changed(behavior, p, v))
		margin.add_child(props)
		vbox.add_child(margin)

# --- CONTEXT ACTIONS ---

func _on_add_variable_pressed() -> void:
	if not active_node: return
	var ur = EditorInterface.get_editor_undo_redo()
	var list = active_node.get("declared_variables")
	if list == null: list = []
	else: list = list.duplicate()
	
	var new_var = load("res://addons/FlowHFSM/runtime/StateVariable.gd").new()
	new_var.variable_name = "new_var"
	list.append(new_var)
	
	ur.create_action("Add Variable")
	ur.add_do_property(active_node, "declared_variables", list)
	ur.add_undo_property(active_node, "declared_variables", active_node.get("declared_variables"))
	ur.add_do_method(self, "_refresh_context_ui")
	ur.add_undo_method(self, "_refresh_context_ui")
	ur.commit_action()

func _on_remove_variable(index: int) -> void:
	var ur = EditorInterface.get_editor_undo_redo()
	var list = active_node.get("declared_variables").duplicate()
	list.remove_at(index)
	ur.create_action("Remove Variable")
	ur.add_do_property(active_node, "declared_variables", list)
	ur.add_undo_property(active_node, "declared_variables", active_node.get("declared_variables"))
	ur.add_do_method(self, "_refresh_context_ui")
	ur.add_undo_method(self, "_refresh_context_ui")
	ur.commit_action()

func _on_variable_changed(res: Resource, index: int) -> void:
	var list = active_node.get("declared_variables").duplicate()
	list[index] = res
	active_node.declared_variables = list
	_refresh_context_ui()

func _on_variable_prop_changed(res: Resource, p: String, v: Variant) -> void:
	res.set(p, v)

func _on_add_behavior_pressed() -> void:
	if not active_node: return
	var ur = EditorInterface.get_editor_undo_redo()
	var list = active_node.get("behaviors")
	if list == null: list = []
	else: list = list.duplicate()
	
	list.append(null)
	
	ur.create_action("Add Behavior Slot")
	ur.add_do_property(active_node, "behaviors", list)
	ur.add_undo_property(active_node, "behaviors", active_node.get("behaviors"))
	ur.add_do_method(self, "_refresh_context_ui")
	ur.add_undo_method(self, "_refresh_context_ui")
	ur.commit_action()

func _on_remove_behavior(index: int) -> void:
	var ur = EditorInterface.get_editor_undo_redo()
	var list = active_node.get("behaviors").duplicate()
	list.remove_at(index)
	ur.create_action("Remove Behavior")
	ur.add_do_property(active_node, "behaviors", list)
	ur.add_undo_property(active_node, "behaviors", active_node.get("behaviors"))
	ur.add_do_method(self, "_refresh_context_ui")
	ur.add_undo_method(self, "_refresh_context_ui")
	ur.commit_action()

func _on_behavior_changed(res: Resource, index: int) -> void:
	var list = active_node.get("behaviors").duplicate()
	list[index] = res
	active_node.behaviors = list
	_refresh_context_ui()

func _on_behavior_prop_changed(res: Resource, p: String, v: Variant) -> void:
	res.set(p, v)

# --- CONFIG UI ---

func _build_config_ui() -> void:
	config_container = VBoxContainer.new()
	config_container.visible = false
	config_container.size_flags_vertical = SIZE_EXPAND_FILL
	content_container.add_child(config_container)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.size_flags_vertical = SIZE_EXPAND_FILL
	config_container.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Back Button
	var btn_back = Button.new()
	btn_back.text = " < Back"
	btn_back.flat = true
	btn_back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_back.pressed.connect(func(): 
		config_container.visible = false
		if current_mode == WorkbenchMode.DASHBOARD:
			dashboard_container.visible = true
		else:
			context_container.visible = true
	)
	vbox.add_child(btn_back)
	
	# Form
	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)
	
	# Template Select (for Node/Template)
	var lbl_opt = Label.new()
	lbl_opt.text = "Template:"
	lbl_opt.name = "LblOption"
	grid.add_child(lbl_opt)
	
	var opt_tmpl = OptionButton.new()
	opt_tmpl.name = "OptTemplate"
	opt_tmpl.size_flags_horizontal = SIZE_EXPAND_FILL
	opt_tmpl.item_selected.connect(func(_i): _update_preview())
	grid.add_child(opt_tmpl)
	
	# Source Select (for Duplicate/Extend)
	var lbl_src = Label.new()
	lbl_src.text = "Source Script:"
	lbl_src.name = "LblSource"
	grid.add_child(lbl_src)
	
	var src_box = HBoxContainer.new()
	src_box.name = "HBoxSource"
	src_box.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var src_edit = LineEdit.new()
	src_edit.name = "EditSource"
	src_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	src_edit.text_changed.connect(func(t): selected_source_path = t; _update_preview())
	src_box.add_child(src_edit)
	
	var src_btn = Button.new()
	src_btn.text = "..."
	src_btn.pressed.connect(func(): script_dialog.popup_centered_ratio(0.6))
	src_box.add_child(src_btn)
	
	grid.add_child(src_box)

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
	folder_box.name = "HBoxFolder"
	folder_box.size_flags_horizontal = SIZE_EXPAND_FILL
	folder_edit = LineEdit.new()
	folder_edit.text = "res://"
	folder_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	folder_box.add_child(folder_edit)
	
	var folder_btn = Button.new()
	folder_btn.text = "..."
	folder_btn.pressed.connect(func(): file_dialog.popup_centered_ratio(0.6))
	folder_box.add_child(folder_btn)
	grid.add_child(folder_box)
	
	# Preview
	var lbl_prev = Label.new()
	lbl_prev.text = "Preview:"
	vbox.add_child(lbl_prev)
	
	preview_edit = CodeEdit.new()
	preview_edit.size_flags_vertical = SIZE_EXPAND_FILL
	preview_edit.editable = false
	preview_edit.add_theme_color_override("background_color", Color(0.1, 0.1, 0.1))
	vbox.add_child(preview_edit)
	
	create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.custom_minimum_size.y = 40
	create_btn.pressed.connect(_on_create_pressed)
	vbox.add_child(create_btn)

func _setup_config(mode: CreationMode, type: String) -> void:
	current_creation_mode = mode
	base_type = type
	
	dashboard_container.visible = false
	context_container.visible = false
	config_container.visible = true
	
	class_name_edit.text = ""
	class_name_edit.grab_focus()
	
	# UI Visibility
	var lbl_opt = config_container.find_child("LblOption", true, false)
	var opt_tmpl = config_container.find_child("OptTemplate", true, false)
	var lbl_src = config_container.find_child("LblSource", true, false)
	var hbox_src = config_container.find_child("HBoxSource", true, false)
	var lbl_folder = config_container.find_child("LblFolder", true, false)
	var hbox_folder = config_container.find_child("HBoxFolder", true, false)
	
	# Defaults
	lbl_opt.visible = false; opt_tmpl.visible = false
	lbl_src.visible = false; hbox_src.visible = false
	lbl_folder.visible = true; hbox_folder.visible = true
	
	if mode == CreationMode.TEMPLATE:
		lbl_opt.visible = true; opt_tmpl.visible = true
		opt_tmpl.clear()
		opt_tmpl.add_item("Empty")
		if type == "StateCondition": opt_tmpl.add_item("Blackboard Check")
		
	elif mode == CreationMode.DUPLICATE or mode == CreationMode.EXTEND:
		lbl_src.visible = true; hbox_src.visible = true
		
	elif mode == CreationMode.NODE:
		lbl_opt.visible = true; opt_tmpl.visible = true
		opt_tmpl.clear()
		opt_tmpl.add_item("Empty State")
		opt_tmpl.add_item("With New Behavior")
		lbl_folder.visible = false; hbox_folder.visible = false
	
	# Set folder
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
		
		# Show folder if behavior
		var lbl_folder = config_container.find_child("LblFolder", true, false)
		var hbox_folder = config_container.find_child("HBoxFolder", true, false)
		lbl_folder.visible = with_behavior
		hbox_folder.visible = with_behavior
		
		var msg = "Plan:\n"
		msg += "1. Create RecursiveState node named '%s'.\n" % c_name
		if with_behavior:
			msg += "2. Create behavior script '%sBehavior.gd' in %s.\n" % [c_name, folder_edit.text]
		preview_edit.text = msg
		return

	# Script Gen
	var code = ""
	if current_creation_mode == CreationMode.TEMPLATE:
		code = _generate_template(c_name)
	elif current_creation_mode == CreationMode.DUPLICATE:
		code = _generate_duplicate(c_name, selected_source_path)
	elif current_creation_mode == CreationMode.EXTEND:
		code = _generate_extend(c_name, selected_source_path)
		
	preview_edit.text = code

func _generate_template(c_name: String) -> String:
	var safe_name = c_name if not c_name.is_empty() else "MyClass"
	var opt = config_container.find_child("OptTemplate", true, false)
	var t_name = opt.get_item_text(opt.selected) if opt else "Empty"
	
	if base_type == "StateCondition":
		if t_name == "Blackboard Check":
			return "class_name " + safe_name + " extends StateCondition\n\n@export var key: String = \"some_key\"\n@export var target_value: bool = true\n\nfunc _evaluate(actor: Node, blackboard: Blackboard) -> bool:\n\treturn blackboard.get_value(key) == target_value\n"
		return "class_name " + safe_name + " extends StateCondition\n\nfunc _evaluate(actor: Node, blackboard: Blackboard) -> bool:\n\treturn false\n"
	else:
		return "class_name " + safe_name + " extends StateBehavior\n\nfunc enter(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc update(node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc exit(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n"

func _generate_duplicate(c_name: String, path: String) -> String:
	if path.is_empty(): return "# Select a source script."
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return "# Error reading " + path
	var txt = f.get_as_text()
	f.close()
	
	var regex = RegEx.new()
	regex.compile("class_name\\s+(\\w+)")
	var res = regex.search(txt)
	if res:
		var old_decl = res.get_string(0)
		var new_decl = "class_name " + c_name
		txt = txt.replace(old_decl, new_decl)
	else:
		txt = "class_name " + c_name + "\n" + txt
	return txt

func _generate_extend(c_name: String, path: String) -> String:
	if path.is_empty(): return "class_name " + c_name + " extends " + base_type + "\n"
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return "# Error reading " + path
	var txt = f.get_as_text()
	f.close()
	
	var regex = RegEx.new()
	regex.compile("class_name\\s+(\\w+)")
	var res = regex.search(txt)
	var parent = base_type
	if res: parent = res.get_string(1)
	
	return "class_name " + c_name + " extends " + parent + "\n\n"

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
			
			if base_type == "StateBehavior": _last_used_behavior_folder = folder
			elif base_type == "StateCondition": _last_used_condition_folder = folder
			
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
	
	var opt = config_container.find_child("OptTemplate", true, false)
	var with_behavior = (opt and opt.get_item_text(opt.selected) == "With New Behavior")
	
	if with_behavior:
		var b_name = state_name + "Behavior"
		var folder = folder_edit.text
		if not folder.ends_with("/"): folder += "/"
		var code = _generate_template(b_name)
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
				
				undo.create_action("Assign Behavior")
				undo.add_do_property(new_node, "behaviors", [res])
				undo.add_undo_property(new_node, "behaviors", [])
				undo.commit_action()
	
	config_container.visible = false
	context_container.visible = true
