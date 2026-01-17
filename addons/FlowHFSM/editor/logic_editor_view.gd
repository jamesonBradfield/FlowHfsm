@tool
extends ScrollContainer

## LogicEditorView (The "Tuner" & "Builder")
## Displays horizontal cards AND allows adding new logic components directly.

const HFSMPropertyFactory = preload("res://addons/FlowHFSM/editor/property_factory.gd")

var current_state: Node
var content_box: HBoxContainer

# Context Menus
var add_condition_popup: PopupMenu
var add_behavior_popup: PopupMenu

func _ready() -> void:
	name = "Logic Tuner"
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	
	content_box = HBoxContainer.new()
	content_box.size_flags_horizontal = SIZE_EXPAND_FILL
	content_box.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(content_box)
	
	# Create Popups
	_setup_popups()

	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1e1e1e")
	add_theme_stylebox_override("panel", style)

func _setup_popups() -> void:
	# 1. Condition Menu
	add_condition_popup = PopupMenu.new()
	add_condition_popup.id_pressed.connect(_on_add_condition)
	add_child(add_condition_popup)
	
	# 2. Behavior Menu
	add_behavior_popup = PopupMenu.new()
	add_behavior_popup.id_pressed.connect(_on_add_behavior)
	add_child(add_behavior_popup)

func edit_state(node: Node) -> void:
	current_state = node
	_rebuild_ui()

func _rebuild_ui() -> void:
	for c in content_box.get_children():
		if c is VBoxContainer or c is VSeparator: # Keep popups, kill UI
			c.queue_free()
	
	if not current_state: return

	# --- COLUMN 1: IF (Conditions) ---
	var cond_col := _create_column("Activation Logic (IF)", Color("ff5d5d"))
	content_box.add_child(cond_col)
	content_box.add_child(VSeparator.new())
	
	# Cards
	var conditions: Array = current_state.get("activation_conditions")
	if conditions:
		for i in range(conditions.size()):
			var card := _create_resource_card(conditions[i], "Condition %d" % i, i, true)
			cond_col.add_child(card)
	
	# Add Button
	var btn_add_cond := Button.new()
	btn_add_cond.text = "+ Add Condition"
	btn_add_cond.pressed.connect(func(): _show_add_menu(add_condition_popup, _get_condition_options()))
	cond_col.add_child(btn_add_cond)

	# --- COLUMN 2: THEN (Behaviors) ---
	var beh_col := _create_column("Behaviors (THEN)", Color("4fabff"))
	content_box.add_child(beh_col)
	
	# Cards
	var behaviors: Array = current_state.get("behaviors")
	if behaviors:
		for i in range(behaviors.size()):
			var res: Resource = behaviors[i]
			var title: String = res.resource_path.get_file().get_basename() if res else "Null"
			if res and res.resource_name: title = res.resource_name
			
			var card := _create_resource_card(res, title, i, false)
			beh_col.add_child(card)

	# Add Button
	var btn_add_beh := Button.new()
	btn_add_beh.text = "+ Add Behavior"
	btn_add_beh.pressed.connect(func(): _show_add_menu(add_behavior_popup, _get_behavior_options()))
	beh_col.add_child(btn_add_beh)

# --- UI Helpers ---

func _create_column(title_text: String, color: Color) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.custom_minimum_size.x = 220
	
	var lbl := Label.new()
	lbl.text = title_text
	lbl.modulate = color
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	col.add_child(lbl)
	col.add_child(HSeparator.new())
	return col

func _create_resource_card(res: Resource, title: String, index: int, is_condition: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	
	# Header
	var header := Label.new()
	header.text = title
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)
	
	# Actions
	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)
	
	if res:
		var btn_edit := Button.new()
		btn_edit.text = "Edit"
		btn_edit.size_flags_horizontal = SIZE_EXPAND_FILL
		btn_edit.icon = get_theme_icon("Edit", "EditorIcons")
		btn_edit.pressed.connect(func(): EditorInterface.edit_resource(res))
		hbox.add_child(btn_edit)
	
	var btn_del := Button.new()
	btn_del.icon = get_theme_icon("Remove", "EditorIcons")
	btn_del.pressed.connect(func(): _remove_item(index, is_condition))
	hbox.add_child(btn_del)
	
	return panel

# --- Logic Actions ---

func _get_condition_options() -> Dictionary:
	return {
		"Input Check": "res://addons/FlowHFSM/presets/conditions/ConditionInput.gd",
		"Float Comparison (> <)": "res://addons/FlowHFSM/presets/conditions/ConditionFloatCmp.gd",
		"Bool Comparison (==)": "res://addons/FlowHFSM/presets/conditions/ConditionBoolCmp.gd",
		"Timer Elapsed": "res://addons/FlowHFSM/presets/conditions/ConditionTimerElapsed.gd"
	}

func _get_behavior_options() -> Dictionary:
	return {
		"Physics (Move/Slide)": "res://addons/FlowHFSM/presets/behaviors/BehaviorPhysics.gd",
		"Animation Tree": "res://addons/FlowHFSM/presets/behaviors/BehaviorAnimationTree.gd",
		"Timer Lock (Cooldowns)": "res://addons/FlowHFSM/runtime/behaviors/BehaviorTimerLock.gd",
		"Set Property (Generic)": "res://addons/FlowHFSM/presets/behaviors/BehaviorSetProperty.gd"
	}

func _show_add_menu(popup: PopupMenu, options: Dictionary) -> void:
	popup.clear()
	var idx := 0
	for label in options:
		popup.add_item(label, idx)
		popup.set_item_metadata(idx, options[label])
		idx += 1
	popup.position = Vector2(get_screen_position() + get_local_mouse_position())
	popup.popup()

func _on_add_condition(id: int) -> void:
	var path: String = add_condition_popup.get_item_metadata(id)
	var script := load(path) as Script
	if script:
		var new_res := script.new() as Resource
		# Add to array
		var arr: Array = current_state.activation_conditions.duplicate() # Copy for safety
		arr.append(new_res)
		current_state.activation_conditions = arr # Re-assign to trigger setters
		_rebuild_ui()

func _on_add_behavior(id: int) -> void:
	var path: String = add_behavior_popup.get_item_metadata(id)
	var script := load(path) as Script
	if script:
		var new_res := script.new() as Resource
		# Add to array
		var arr: Array = current_state.behaviors.duplicate()
		arr.append(new_res)
		current_state.behaviors = arr
		_rebuild_ui()

func _remove_item(index: int, is_condition: bool) -> void:
	if is_condition:
		var arr: Array = current_state.activation_conditions.duplicate()
		arr.remove_at(index)
		current_state.activation_conditions = arr
	else:
		var arr: Array = current_state.behaviors.duplicate()
		arr.remove_at(index)
		current_state.behaviors = arr
	_rebuild_ui()
