@tool
## Asset Creation Wizard
##
## A step-by-step wizard for creating new StateBehavior and StateCondition assets.
## Supports templates, duplication, and inheritance (extension).
## Automatically handles file creation, resource registration, and editor opening.
extends ConfirmationDialog

signal resource_created(resource: Resource)

enum CreationMode { TEMPLATE, DUPLICATE, EXTEND, NODE }

var current_mode: CreationMode = CreationMode.TEMPLATE
var base_type: String = "StateBehavior"
var selected_source_path: String = ""
var parent_node_for_creation: Node = null # For CreationMode.NODE

# UI Containers
var step1_container: VBoxContainer
var step2_container: VBoxContainer

# Step 1 UI
var type_buttons: Array[Button] = []

# Step 2 UI
var config_grid: GridContainer
var class_name_edit: LineEdit
var folder_edit: LineEdit
var preview_edit: CodeEdit
var back_btn: Button

# Dialogs
var file_dialog: EditorFileDialog
var script_dialog: EditorFileDialog

func _init() -> void:
	title = "Asset Creation Wizard"
	min_size = Vector2(700, 600)
	get_ok_button().text = "Create Asset"
	get_ok_button().disabled = true # Disabled until Step 2
	
	# Main Layout
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	
	# --- Step 1: Selection ---
	step1_container = VBoxContainer.new()
	step1_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	step1_container.add_theme_constant_override("separation", 20)
	main_vbox.add_child(step1_container)
	
	var lbl_step1 = Label.new()
	lbl_step1.text = "Step 1: Choose Creation Method"
	lbl_step1.add_theme_font_size_override("font_size", 18)
	lbl_step1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step1_container.add_child(lbl_step1)
	
	var cards_hbox = HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 20)
	cards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	step1_container.add_child(cards_hbox)
	
	_create_selection_card(cards_hbox, "New Empty", "Create a fresh script from a template.", CreationMode.TEMPLATE, "New")
	_create_selection_card(cards_hbox, "Duplicate", "Clone an existing behavior/condition.", CreationMode.DUPLICATE, "Duplicate")
	_create_selection_card(cards_hbox, "Extend", "Inherit from an existing class.", CreationMode.EXTEND, "ScriptExtend")
	
	# --- Step 2: Configuration ---
	step2_container = VBoxContainer.new()
	step2_container.visible = false
	step2_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(step2_container)
	
	var header_hbox = HBoxContainer.new()
	step2_container.add_child(header_hbox)
	
	back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.icon = get_theme_icon("Back", "EditorIcons")
	back_btn.pressed.connect(_on_back_pressed)
	header_hbox.add_child(back_btn)
	
	var lbl_step2 = Label.new()
	lbl_step2.text = "Step 2: Configure Asset"
	lbl_step2.add_theme_font_size_override("font_size", 18)
	lbl_step2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_step2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_hbox.add_child(lbl_step2)
	
	# Error Label
	var lbl_error = Label.new()
	lbl_error.name = "LblError"
	lbl_error.modulate = Color(1, 0.4, 0.4) # Red
	lbl_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_error.visible = false
	step2_container.add_child(lbl_error)
	
	# Config Grid
	config_grid = GridContainer.new()
	config_grid.columns = 2
	step2_container.add_child(config_grid)
	
	# -- Config Elements (created dynamically or hidden/shown) --
	
	# Template Select
	var lbl_tmpl = Label.new()
	lbl_tmpl.text = "Template:"
	lbl_tmpl.name = "LblTemplate"
	config_grid.add_child(lbl_tmpl)
	
	var opt_tmpl = OptionButton.new()
	opt_tmpl.name = "OptTemplate"
	opt_tmpl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_tmpl.item_selected.connect(func(_i): _update_preview())
	config_grid.add_child(opt_tmpl)
	
	# Source File
	var lbl_src = Label.new()
	lbl_src.text = "Source Script:"
	lbl_src.name = "LblSource"
	config_grid.add_child(lbl_src)
	
	var src_hbox = HBoxContainer.new()
	src_hbox.name = "HBoxSource"
	src_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var src_edit = LineEdit.new()
	src_edit.name = "EditSource"
	src_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	src_edit.text_changed.connect(func(t): selected_source_path = t; _update_preview())
	src_hbox.add_child(src_edit)
	
	var src_btn = Button.new()
	src_btn.text = "..."
	src_btn.pressed.connect(func(): script_dialog.popup_centered_ratio(0.6))
	src_hbox.add_child(src_btn)
	
	config_grid.add_child(src_hbox)
	
	# Class Name
	config_grid.add_child(Label.new().duplicate()) # Spacer or Label
	config_grid.get_child(config_grid.get_child_count()-1).text = "Class Name:"
	
	class_name_edit = LineEdit.new()
	class_name_edit.placeholder_text = "MyNewAsset"
	class_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_name_edit.text_changed.connect(func(_t): _update_preview())
	config_grid.add_child(class_name_edit)
	
	# Folder
	config_grid.add_child(Label.new().duplicate())
	config_grid.get_child(config_grid.get_child_count()-1).text = "Save Folder:"
	
	var folder_hbox = HBoxContainer.new()
	folder_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	folder_edit = LineEdit.new()
	folder_edit.text = "res://"
	folder_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folder_hbox.add_child(folder_edit)
	
	var folder_btn = Button.new()
	folder_btn.text = "..."
	folder_btn.pressed.connect(func(): file_dialog.popup_centered_ratio(0.6))
	folder_hbox.add_child(folder_btn)
	
	config_grid.add_child(folder_hbox)
	
	# Preview
	var lbl_prev = Label.new()
	lbl_prev.text = "Preview:"
	step2_container.add_child(lbl_prev)
	
	preview_edit = CodeEdit.new()
	preview_edit.editable = false
	preview_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_edit.add_theme_color_override("background_color", Color(0.1, 0.1, 0.1))
	# Syntax highlighting is manual but better than nothing
	preview_edit.syntax_highlighter = CodeHighlighter.new()
	preview_edit.syntax_highlighter.add_keyword_color("class_name", Color(1, 0.4, 0.7))
	preview_edit.syntax_highlighter.add_keyword_color("extends", Color(1, 0.4, 0.7))
	preview_edit.syntax_highlighter.add_keyword_color("func", Color(0.4, 0.7, 1))
	preview_edit.syntax_highlighter.add_keyword_color("return", Color(1, 0.4, 0.7))
	preview_edit.syntax_highlighter.add_keyword_color("var", Color(1, 0.4, 0.7))
	preview_edit.syntax_highlighter.add_keyword_color("void", Color(0.4, 1, 0.6))
	preview_edit.syntax_highlighter.add_keyword_color("bool", Color(0.4, 1, 0.6))
	step2_container.add_child(preview_edit)
	
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
		src_edit.text = p
		_update_preview()
	)
	add_child(script_dialog)
	
	confirmed.connect(_on_confirmed)

func _create_selection_card(parent: Control, title: String, desc: String, mode: CreationMode, icon_name: String) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(180, 220)
	btn.pressed.connect(func(): _go_to_step2(mode))
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 10)
	btn.add_child(vbox)
	
	var icon_tex = get_theme_icon(icon_name, "EditorIcons")
	var icon_rect = TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(64, 64)
	vbox.add_child(icon_rect)
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(lbl_desc)
	
	parent.add_child(btn)

func configure_node_creation(parent: Node) -> void:
	base_type = "RecursiveState"
	parent_node_for_creation = parent
	current_mode = CreationMode.NODE
	title = "Create Child State"
	
	_go_to_step2(CreationMode.NODE)
	
	# Override Step 2 UI for Node Creation
	var lbl_tmpl = find_child("LblTemplate", true, false)
	var opt_tmpl = find_child("OptTemplate", true, false)
	var lbl_src = find_child("LblSource", true, false)
	var hbox_src = find_child("HBoxSource", true, false)
	
	if lbl_tmpl: lbl_tmpl.visible = true
	if opt_tmpl: 
		opt_tmpl.visible = true
		opt_tmpl.clear()
		opt_tmpl.add_item("Empty State")
		opt_tmpl.add_item("With New Behavior")
		opt_tmpl.item_selected.connect(func(idx): 
			_update_node_ui_visibility()
			_update_preview()
		)
	
	_update_node_ui_visibility() # Initial state
	
	# Hide preview as it's not a script
	preview_edit.visible = true # Keep visible for status text
	
	if class_name_edit:
		class_name_edit.placeholder_text = "MyNewState"

func _update_node_ui_visibility() -> void:
	if current_mode != CreationMode.NODE: return
	
	var opt = find_child("OptTemplate", true, false)
	var is_with_behavior = (opt and opt.get_item_text(opt.selected) == "With New Behavior")
	
	# We need ClassName/Folder for the Behavior if selected
	# Actually, we use ClassName for the Node Name regardless.
	# If behavior, we derive behavior name from Node name.
	
	# Show folder only if creating behavior
	var lbl_folder = config_grid.get_child(config_grid.get_child_count()-2) # Hacky access, should use node refs
	if lbl_folder and lbl_folder is Label: lbl_folder.visible = is_with_behavior
	folder_edit.get_parent().visible = is_with_behavior

func configure(type: String) -> void:
	base_type = type
	_go_to_step1()
	
	# Update Templates
	var opt = find_child("OptTemplate", true, false)
	if opt:
		opt.clear()
		opt.add_item("Empty")
		if type == "StateCondition":
			opt.add_item("Blackboard Check")
	
	# Update Placeholder
	if class_name_edit:
		class_name_edit.placeholder_text = "MyNew" + type.trim_prefix("State")
	
	# Try to find default folders
	var fs = DirAccess.open("res://")
	var default_folder = "res://"
	if type == "StateBehavior":
		if fs.dir_exists("addons/FlowHFSM/presets/behaviors"):
			default_folder = "res://addons/FlowHFSM/presets/behaviors/"
	elif type == "StateCondition":
		if fs.dir_exists("addons/FlowHFSM/presets/conditions"):
			default_folder = "res://addons/FlowHFSM/presets/conditions/"
			
	folder_edit.text = default_folder

func _go_to_step1() -> void:
	step1_container.visible = true
	step2_container.visible = false
	get_ok_button().disabled = true
	title = "Create New " + base_type + " - Step 1"

func _go_to_step2(mode: CreationMode) -> void:
	current_mode = mode
	step1_container.visible = false
	step2_container.visible = true
	get_ok_button().disabled = false
	title = "Create New " + base_type + " - Configure"
	
	# Show/Hide Configs
	var lbl_tmpl = find_child("LblTemplate", true, false)
	var opt_tmpl = find_child("OptTemplate", true, false)
	var lbl_src = find_child("LblSource", true, false)
	var hbox_src = find_child("HBoxSource", true, false)
	
	var show_tmpl = (mode == CreationMode.TEMPLATE)
	var show_src = (mode != CreationMode.TEMPLATE)
	
	if lbl_tmpl: lbl_tmpl.visible = show_tmpl
	if opt_tmpl: opt_tmpl.visible = show_tmpl
	if lbl_src: lbl_src.visible = show_src
	if hbox_src: hbox_src.visible = show_src
	
	_update_preview()

func _on_back_pressed() -> void:
	_go_to_step1()

func _update_preview() -> void:
	if current_mode == CreationMode.NODE:
		var state_name = class_name_edit.text.strip_edges()
		if state_name.is_empty():
			preview_edit.text = "Please enter a name for the new state."
			get_ok_button().disabled = true
			return
			
		var opt = find_child("OptTemplate", true, false)
		var with_behavior = (opt and opt.get_item_text(opt.selected) == "With New Behavior")
		
		var msg = "Plan:\n"
		msg += "1. Create RecursiveState node named '%s' under '%s'.\n" % [state_name, parent_node_for_creation.name]
		
		if with_behavior:
			var b_name = "Behavior" + state_name
			msg += "2. Create new script '%s.gd' in selected folder.\n" % b_name
			msg += "3. Create new resource '%s.tres'.\n" % b_name
			msg += "4. Assign behavior to node."
			
		preview_edit.text = msg
		get_ok_button().disabled = false
		return

	var c_name = class_name_edit.text.strip_edges()
	var error_msg = ""
	
	# Validation
	if c_name.is_empty():
		error_msg = "Class Name is required."
	elif not c_name.is_valid_identifier():
		error_msg = "Class Name must be a valid identifier."
	else:
		var folder = folder_edit.text
		if not folder.ends_with("/"): folder += "/"
		if FileAccess.file_exists(folder + c_name + ".gd"):
			error_msg = "Script already exists at this path."
		elif FileAccess.file_exists(folder + c_name + ".tres"):
			error_msg = "Resource already exists at this path."
	
	if current_mode != CreationMode.TEMPLATE and selected_source_path.is_empty():
		error_msg = "Please select a source script."
	
	var lbl_error = find_child("LblError", true, false)
	if lbl_error:
		if error_msg.is_empty():
			lbl_error.visible = false
			get_ok_button().disabled = false
		else:
			lbl_error.text = error_msg
			lbl_error.visible = true
			get_ok_button().disabled = true
			
	if c_name.is_empty(): c_name = "{ClassName}"
	
	var code = ""
	match current_mode:
		CreationMode.TEMPLATE:
			code = _generate_template(c_name)
		CreationMode.DUPLICATE:
			if selected_source_path.is_empty():
				code = "# Select a source script to duplicate."
			else:
				code = _generate_duplicate(c_name, selected_source_path)
		CreationMode.EXTEND:
			if selected_source_path.is_empty():
				code = "class_name " + c_name + " extends " + base_type + "\n\n# Select a source script to extend."
			else:
				code = _generate_extend(c_name, selected_source_path)
	preview_edit.text = code

func _generate_template(c_name: String) -> String:
	var opt = find_child("OptTemplate", true, false)
	var t_name = "Empty"
	if opt and opt.selected >= 0: t_name = opt.get_item_text(opt.selected)
	
	if base_type == "StateCondition":
		if t_name == "Blackboard Check":
			return "class_name " + c_name + " extends StateCondition\n\n@export var key: String = \"some_key\"\n@export var target_value: bool = true\n\nfunc _evaluate(actor: Node, blackboard: Blackboard) -> bool:\n\treturn blackboard.get_value(key) == target_value\n"
		return "class_name " + c_name + " extends StateCondition\n\nfunc _evaluate(actor: Node, blackboard: Blackboard) -> bool:\n\treturn false\n"
	else:
		return "class_name " + c_name + " extends StateBehavior\n\nfunc enter(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc update(node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc exit(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n"

func _generate_duplicate(c_name: String, path: String) -> String:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return "# Error reading " + path
	var txt = f.get_as_text()
	f.close()
	
	var regex = RegEx.new()
	regex.compile("class_name\\s+(\\w+)")
	var res = regex.search(txt)
	if res:
		# Only replace the first occurrence (declaration)
		# To be safe, we reconstruct the string or just replace exact match
		var old_decl = res.get_string(0) # e.g. "class_name Old"
		var new_decl = "class_name " + c_name
		txt = txt.replace(old_decl, new_decl)
	else:
		# Fallback: Prepend class_name if missing
		txt = "class_name " + c_name + "\n" + txt
	return txt

func _generate_extend(c_name: String, path: String) -> String:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return "# Error reading " + path
	var txt = f.get_as_text()
	f.close()
	
	var regex = RegEx.new()
	regex.compile("class_name\\s+(\\w+)")
	var res = regex.search(txt)
	var parent = base_type
	if res: parent = res.get_string(1)
	
	# If no class_name found, maybe it's a script extending something else?
	# In that case, we can't easily extend it by class name unless it has one.
	# Fallback to base_type is safer than invalid code.
	
	return "class_name " + c_name + " extends " + parent + "\n\n"


func _on_confirmed() -> void:
	if current_mode == CreationMode.NODE:
		_create_node()
		return

	var c_name = class_name_edit.text
	if c_name.is_empty():
		printerr("Class Name cannot be empty")
		return
	
	var folder = folder_edit.text
	if not folder.ends_with("/"): folder += "/"
	var script_path = folder + c_name + ".gd"
	var res_path = folder + c_name + ".tres"
	
	var f = FileAccess.open(script_path, FileAccess.WRITE)
	if not f:
		printerr("Cannot write " + script_path)
		return
	f.store_string(preview_edit.text)
	f.close()
	
	var fs = EditorInterface.get_resource_filesystem()
	fs.scan()
	
	# Wait for file
	var found = false
	for i in range(20):
		if not is_instance_valid(self): return # Safety check if dialog was freed
		if not fs.get_file_type(script_path).is_empty():
			found = true
			break
		await get_tree().create_timer(0.1).timeout
	
	if not is_instance_valid(self): return # Safety check after loop
	if not found: printerr("Warning: Script file not detected after scan.")
	
	var script = load(script_path)
	if not script:
		printerr("Failed to load script")
		return
		
	var res = script.new()
	if not (res is Resource):
		printerr("Script is not a Resource")
		return
		
	var err = ResourceSaver.save(res, res_path)
	if err != OK:
		printerr("Failed to save resource")
		return
		
	fs.scan()
	EditorInterface.edit_resource(script)
	
	if is_instance_valid(self):
		resource_created.emit(load(res_path))

func _create_node() -> void:
	var state_name = class_name_edit.text.strip_edges()
	if state_name.is_empty(): return
	
	var new_node = load("res://addons/FlowHFSM/runtime/RecursiveState.gd").new()
	new_node.name = state_name
	
	var root = EditorInterface.get_edited_scene_root()
	var undo = EditorInterface.get_editor_undo_redo()
	
	undo.create_action("Add Child State")
	undo.add_do_method(parent_node_for_creation, "add_child", new_node)
	undo.add_do_method(new_node, "set_owner", root)
	undo.add_undo_method(parent_node_for_creation, "remove_child", new_node)
	
	# Optional: Also create behavior?
	var opt = find_child("OptTemplate", true, false)
	if opt and opt.get_item_text(opt.selected) == "With New Behavior":
		# 1. Generate Behavior
		var b_name = "Behavior" + state_name
		var folder = folder_edit.text
		if not folder.ends_with("/"): folder += "/"
		
		# Generate Template Code
		var code = "class_name " + b_name + " extends StateBehavior\n\nfunc enter(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc update(node: Node, delta: float, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n\nfunc exit(node: Node, actor: Node, blackboard: Blackboard) -> void:\n\tpass\n"
		
		var script_path = folder + b_name + ".gd"
		var res_path = folder + b_name + ".tres"
		
		var f = FileAccess.open(script_path, FileAccess.WRITE)
		if f:
			f.store_string(code)
			f.close()
			
			# We must scan before creating resource from script
			var fs = EditorInterface.get_resource_filesystem()
			fs.scan()
			
			# Wait loop (blocking slightly but necessary for "One Click" feel)
			# NOTE: In an undo action, we can't easily async wait.
			# Strategy: We do the file ops, then add a "do_method" that loads and assigns.
			# BUT `load()` will fail if scan isn't done.
			
			# ALTERNATIVE: Separate the behavior creation from the UndoRedo block?
			# We can commit the node creation, THEN do the behavior logic.
		else:
			printerr("Failed to write behavior script.")
			
	undo.commit_action()
	
	if opt and opt.get_item_text(opt.selected) == "With New Behavior":
		_finalize_behavior_creation_async("Behavior" + state_name, folder_edit.text, new_node)

func _finalize_behavior_creation_async(b_name: String, folder: String, target_node: Node) -> void:
	if not folder.ends_with("/"): folder += "/"
	var script_path = folder + b_name + ".gd"
	var res_path = folder + b_name + ".tres"
	
	# Wait for scan
	var fs = EditorInterface.get_resource_filesystem()
	for i in range(20):
		if not is_instance_valid(self): return
		if not fs.get_file_type(script_path).is_empty():
			break
		await get_tree().create_timer(0.1).timeout
		
	var script = load(script_path)
	if not script: return
	
	var res = script.new()
	ResourceSaver.save(res, res_path)
	fs.scan()
	EditorInterface.edit_resource(script)
	
	# Assign to node
	# We need to use UndoRedo for property assignment to ensure it saves/undoes correctly
	var undo = EditorInterface.get_editor_undo_redo()
	undo.create_action("Assign New Behavior")
	undo.add_do_property(target_node, "behaviors", [res])
	undo.add_undo_property(target_node, "behaviors", [])
	undo.commit_action()

