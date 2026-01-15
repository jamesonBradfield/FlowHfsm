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

# smash_dialog definition
var smash_dialog: EditorFileDialog

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
	
	smash_dialog = EditorFileDialog.new()
	smash_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	smash_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	smash_dialog.filters = ["*.gd ; GDScript"]
	smash_dialog.file_selected.connect(_on_smash_file_selected)
	add_child(smash_dialog)
	
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

func _is_state(node: Node) -> bool:
	if not node: return false
	# Try strict type check (works if class is registered)
	if node is RecursiveState: return true
	# Fallback: Script resource path check (works for base class)
	var scr = node.get_script()
	if scr and scr.resource_path.ends_with("RecursiveState.gd"): return true
	# Fallback: Check for inheritance in script source/meta? 
	# Too slow. Stick to these two.
	return false

func _on_selection_changed() -> void:
	active_node = _last_selected_node
	
	# Determine Mode
	if _is_state(active_node):
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
	dashboard_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(dashboard_container)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 30)
	dashboard_container.add_child(main_vbox)
	
	# Spacer Top
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size.y = 20
	main_vbox.add_child(spacer_top)
	
	# 1. Hero Section
	var hero_vbox = VBoxContainer.new()
	hero_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(hero_vbox)
	
	var lbl_welcome = Label.new()
	lbl_welcome.text = "Welcome to FlowHFSM"
	lbl_welcome.add_theme_font_size_override("font_size", 24)
	lbl_welcome.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	lbl_welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_vbox.add_child(lbl_welcome)
	
	var lbl_sub = Label.new()
	lbl_sub.text = "Select an action to get started with your state machine."
	lbl_sub.modulate = Color(0.7, 0.7, 0.7)
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_vbox.add_child(lbl_sub)
	
	# 2. Action Cards
	var cards_center = CenterContainer.new()
	cards_center.size_flags_horizontal = SIZE_EXPAND_FILL
	main_vbox.add_child(cards_center)
	
	dashboard_cards = HBoxContainer.new()
	dashboard_cards.add_theme_constant_override("separation", 24)
	cards_center.add_child(dashboard_cards)
	
	_create_card(dashboard_cards, "New Behavior", "Create stateless logic resource.", "New", func(): _setup_config(CreationMode.TEMPLATE, "StateBehavior"), Color(0.4, 0.6, 0.8))
	_create_card(dashboard_cards, "New Condition", "Create boolean logic gate.", "New", func(): _setup_config(CreationMode.TEMPLATE, "StateCondition"), Color(0.4, 0.8, 0.6))
	_create_card(dashboard_cards, "Duplicate", "Clone an existing script.", "Duplicate", func(): _setup_config(CreationMode.DUPLICATE, "StateBehavior"), Color(0.8, 0.6, 0.4))
	_create_card(dashboard_cards, "Extend", "Inherit from existing script.", "ScriptExtend", func(): _setup_config(CreationMode.EXTEND, "StateBehavior"), Color(0.7, 0.5, 0.8))

	# 3. Footer / Links
	var footer_vbox = VBoxContainer.new()
	footer_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	footer_vbox.alignment = BoxContainer.ALIGNMENT_END # Push to bottom
	main_vbox.add_child(footer_vbox)
	
	var links_hbox = HBoxContainer.new()
	links_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	links_hbox.add_theme_constant_override("separation", 20)
	footer_vbox.add_child(links_hbox)
	
	_create_link_button(links_hbox, "Documentation", "Help", "https://github.com/") # Placeholder URL
	_create_link_button(links_hbox, "Report Issue", "Error", "https://github.com/") # Placeholder URL
	
	# Spacer Bottom
	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size.y = 20
	footer_vbox.add_child(spacer_bot)

func _create_card(parent: Control, title: String, desc: String, icon_name: String, callback: Callable, accent_color: Color = Color(1,1,1)) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 160)
	btn.pressed.connect(callback)
	# Styling
	# We can't easily override StyleBoxFlat here without creating new ones, 
	# but we can try to use a theme variation or just let it be a button.
	# Let's add a colorful strip at the top inside the button?
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# Icon Area
	var icon_center = CenterContainer.new()
	vbox.add_child(icon_center)
	
	var icon = TextureRect.new()
	icon.texture = get_theme_icon(icon_name, "EditorIcons")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(56, 56)
	icon.modulate = accent_color
	icon_center.add_child(icon)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)
	
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_constant_override("outline_size", 0) # Bold-ish?
	# Make it look bold via font variation if possible, or just color
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	var lbl_d = Label.new()
	lbl_d.text = desc
	lbl_d.modulate = Color(0.7, 0.7, 0.7)
	lbl_d.add_theme_font_size_override("font_size", 11)
	lbl_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_d)
	
	parent.add_child(btn)

func _create_link_button(parent: Control, text: String, icon_name: String, url: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.icon = get_theme_icon(icon_name, "EditorIcons")
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func(): OS.shell_open(url))
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
	
	# 1. Top Bar (Tools)
	var tools_hbox = HBoxContainer.new()
	tools_hbox.add_theme_constant_override("separation", 10)
	inner_vbox.add_child(tools_hbox)
	
	var btn_add_child = Button.new()
	btn_add_child.text = "+ Add Child State"
	btn_add_child.custom_minimum_size = Vector2(0, 40)
	btn_add_child.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_add_child.pressed.connect(func(): _setup_config(CreationMode.NODE, "RecursiveState"))
	tools_hbox.add_child(btn_add_child)
	
	var btn_smash = Button.new()
	btn_smash.text = "Smash (Optimize)"
	btn_smash.icon = get_theme_icon("Script", "EditorIcons")
	btn_smash.tooltip_text = "Compile child logic into a single optimized GDScript."
	btn_smash.pressed.connect(_on_smash_pressed)
	tools_hbox.add_child(btn_smash)
	
	# 2. Logic Overview (Children)
	inner_vbox.add_child(_create_section_header("Logic Flow (Children)", "Execution order and conditions of child states."))
	
	# Header Row
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	inner_vbox.add_child(header_row)
	
	var lbl_prio = Label.new()
	lbl_prio.text = "Pri"
	lbl_prio.custom_minimum_size.x = 30
	lbl_prio.modulate = Color(0.5, 0.5, 0.5)
	lbl_prio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(lbl_prio)
	
	var lbl_name = Label.new()
	lbl_name.text = "State Name"
	lbl_name.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl_name.size_flags_stretch_ratio = 0.3
	lbl_name.modulate = Color(0.5, 0.5, 0.5)
	header_row.add_child(lbl_name)
	
	var lbl_beh = Label.new()
	lbl_beh.text = "Behavior"
	lbl_beh.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl_beh.size_flags_stretch_ratio = 0.3
	lbl_beh.modulate = Color(0.5, 0.5, 0.5)
	header_row.add_child(lbl_beh)
	
	var lbl_cond = Label.new()
	lbl_cond.text = "Conditions"
	lbl_cond.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl_cond.size_flags_stretch_ratio = 0.4
	lbl_cond.modulate = Color(0.5, 0.5, 0.5)
	header_row.add_child(lbl_cond)
	
	context_variables_container = VBoxContainer.new() # Reusing var name for list container to minimize diffs? No, let's rename properly.
	# Actually, I'll rename it in the class definition or just use a new variable.
	# Let's use a new variable in the full file replace or careful edit.
	# Since I am using `edit`, I should be careful.
	# I will replace the whole block of _build_context_ui to be safe.


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
	# context_behaviors_container is removed

	
	# Draw Children
	var children = []
	for c in active_node.get_children():
		if _is_state(c):
			children.append(c)
	
	if children.is_empty():

		var lbl = Label.new()
		lbl.text = "No child states. This is a Leaf State."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		context_variables_container.add_child(lbl)
		return

	# Inverse order for Priority display? 
	# No, Godot tree order: Top = Index 0.
	# HFSM Logic: "Iterate children. Last valid wins."
	# So Index 0 is LOW priority. Index N is HIGH priority.
	# Let's display in Scene Tree order (0 to N) but label them.
	
	for i in range(children.size()):
		var child = children[i]
		_draw_child_row(child, i, children.size())

func _draw_child_row(node: Node, index: int, total: int) -> void:
	var card = PanelContainer.new()
	# Alternating colors?
	var bg = Color(0.15, 0.17, 0.23, 0.5)
	if index % 2 == 1: bg = Color(0.18, 0.20, 0.25, 0.5)
	
	card.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_card_style(bg))
	context_variables_container.add_child(card)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)
	
	# 1. Priority / Index
	var lbl_idx = Label.new()
	lbl_idx.text = str(index)
	lbl_idx.custom_minimum_size.x = 30
	lbl_idx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_idx.modulate = Color(0.6, 0.6, 0.6)
	if index == total - 1: # Highest Priority
		lbl_idx.modulate = Color(0.4, 0.8, 0.5)
		lbl_idx.text += " (Hi)"
	hbox.add_child(lbl_idx)
	
	# 2. Name
	var btn_name = Button.new()
	btn_name.text = node.name
	btn_name.flat = true
	btn_name.icon = get_theme_icon("Node", "EditorIcons")
	btn_name.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_name.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_name.size_flags_stretch_ratio = 0.3
	btn_name.pressed.connect(func(): EditorInterface.edit_node(node))
	hbox.add_child(btn_name)
	
	# 3. Behavior
	var beh_vbox = VBoxContainer.new()
	beh_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	beh_vbox.size_flags_stretch_ratio = 0.3
	beh_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(beh_vbox)
	
	var behs = node.get("behaviors")
	if behs and behs.size() > 0:
		for b in behs:
			if b:
				var lbl_b = Label.new()
				lbl_b.text = b.resource_path.get_file().get_basename()
				lbl_b.clip_text = true
				lbl_b.add_theme_font_size_override("font_size", 12)
				lbl_b.tooltip_text = b.resource_path
				beh_vbox.add_child(lbl_b)
	else:
		var lbl_b = Label.new()
		lbl_b.text = "-"
		lbl_b.modulate = Color(0.3, 0.3, 0.3)
		beh_vbox.add_child(lbl_b)
		
	# 4. Conditions
	var cond_flow = HFlowContainer.new()
	cond_flow.size_flags_horizontal = SIZE_EXPAND_FILL
	cond_flow.size_flags_stretch_ratio = 0.4
	hbox.add_child(cond_flow)
	
	var conds = node.get("activation_conditions")
	if conds and conds.size() > 0:
		for c in conds:
			if c:
				var panel = PanelContainer.new()
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.2, 0.4, 0.6, 0.4)
				style.corner_radius_top_left = 4
				style.corner_radius_top_right = 4
				style.corner_radius_bottom_left = 4
				style.corner_radius_bottom_right = 4
				style.content_margin_left = 6
				style.content_margin_right = 6
				panel.add_theme_stylebox_override("panel", style)
				
				var lbl_c = Label.new()
				lbl_c.text = c.resource_path.get_file().get_basename()
				lbl_c.add_theme_font_size_override("font_size", 10)
				panel.add_child(lbl_c)
				cond_flow.add_child(panel)
	else:
		var lbl_c = Label.new()
		lbl_c.text = "Always"
		lbl_c.modulate = Color(0.4, 0.4, 0.4)
		lbl_c.add_theme_font_size_override("font_size", 11)
		cond_flow.add_child(lbl_c)


# Removed obsolete context actions


func _on_smash_pressed() -> void:
	if not active_node: return
	smash_dialog.current_file = "Smashed_%s.gd" % active_node.name
	smash_dialog.popup_centered_ratio(0.6)

func _on_smash_file_selected(path: String) -> void:
	if not active_node: return
	# Safe load of LogicSmasher in case class_name isn't ready
	var smasher_script = load("res://addons/FlowHFSM/editor/logic_smasher.gd")
	if not smasher_script:
		push_error("FlowHFSM: LogicSmasher script not found!")
		return
		
	var code = smasher_script.smash(active_node)
	
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(code)
		f.close()
		EditorInterface.get_resource_filesystem().scan()
		
		# Wait for scan?
		await get_tree().create_timer(0.2).timeout
		
		var res = load(path)
		if res:
			EditorInterface.edit_resource(res)
			print("FlowHFSM: Smashed state logic to ", path)
		else:
			push_error("FlowHFSM: Failed to load generated script.")

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
