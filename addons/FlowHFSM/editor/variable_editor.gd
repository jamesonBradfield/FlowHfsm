@tool
extends EditorProperty

const ThemeResource = preload("res://addons/FlowHFSM/editor/flow_hfsm_theme.tres")
const HFSMPropertyFactory = preload("res://addons/FlowHFSM/editor/property_factory.gd")
const StateVariableScript = preload("res://addons/FlowHFSM/runtime/StateVariable.gd")

var container: VBoxContainer = VBoxContainer.new()
var updating_from_ui: bool = false
var folded_states: Dictionary = {} # Resource ID -> bool

func _init() -> void:
	label = ""
	container.theme = ThemeResource
	add_child(container)

func _update_property() -> void:
	if updating_from_ui: return
	
	for child in container.get_children():
		child.queue_free()
	
	var object: Object = get_edited_object()
	if not object: return
	
	var property: StringName = get_edited_property()
	var variables: Variant = object.get(property)
	
	if variables == null or not (variables is Array):
		variables = []
	
	if variables.is_empty():
		_draw_empty_state()
	else:
		_draw_list(variables)

func _draw_empty_state() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_empty_slot_style())
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl: Label = Label.new()
	lbl.text = "No Variables Defined"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(1, 1, 1, 0.5)
	vbox.add_child(lbl)
	
	var add_btn: Button = Button.new()
	add_btn.text = "Add Variable"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.custom_minimum_size.x = 120
	add_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_btn.pressed.connect(_on_add_pressed)
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_child(add_btn)
	vbox.add_child(margin)
	
	panel.add_child(vbox)
	container.add_child(panel)

func _draw_list(variables: Array) -> void:
	# List Container
	var list_vbox: VBoxContainer = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	
	for i in range(variables.size()):
		var variable: StateVariable = variables[i]
		
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_card_style())
		
		var card_vbox: VBoxContainer = VBoxContainer.new()
		
		# --- Header ---
		var header: HBoxContainer = HBoxContainer.new()
		
		# Fold
		var is_folded: bool = false
		if variable:
			is_folded = folded_states.get(variable.get_instance_id(), false)
		
		var fold_btn: Button = HFSMPropertyFactory.create_fold_button(is_folded, func():
			if variable:
				folded_states[variable.get_instance_id()] = not is_folded
				_update_property()
		)
		# Disable fold if null
		fold_btn.disabled = (variable == null)
		header.add_child(fold_btn)
		
		# Picker
		var picker: EditorResourcePicker = EditorResourcePicker.new()
		picker.base_type = "StateVariable"
		picker.edited_resource = variable
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.resource_changed.connect(_on_variable_changed.bind(i))
		header.add_child(picker)
		
		# Delete
		var del_btn: Button = Button.new()
		del_btn.icon = get_theme_icon("Remove", "EditorIcons")
		del_btn.tooltip_text = "Remove Variable"
		del_btn.flat = true
		del_btn.pressed.connect(_on_remove_variable.bind(i))
		header.add_child(del_btn)
		
		card_vbox.add_child(header)
		
		# --- Body ---
		if variable and not is_folded:
			var margin: MarginContainer = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 14)
			margin.add_theme_constant_override("margin_top", 4)
			
			var props_list: Control = HFSMPropertyFactory.create_property_list(variable, _on_variable_property_changed.bind(variable))
			margin.add_child(props_list)
			card_vbox.add_child(margin)
		
		card.add_child(card_vbox)
		list_vbox.add_child(card)
		
	container.add_child(list_vbox)
	
	# Bottom Add Button
	var add_btn_row: HBoxContainer = HBoxContainer.new()
	add_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var add_btn: Button = Button.new()
	add_btn.text = "Add Variable"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.pressed.connect(_on_add_pressed)
	add_btn_row.add_child(add_btn)
	container.add_child(add_btn_row)

func _on_variable_changed(new_res: Resource, index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var variables: Array = object.get(property).duplicate()
	variables[index] = new_res
	_apply_changes(variables, "Change Variable Resource")

func _on_variable_property_changed(p_name: String, val: Variant, variable: Resource) -> void:
	updating_from_ui = true
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var old_val: Variant = variable.get(p_name)
	
	ur.create_action("Change Variable Property: " + p_name)
	ur.add_do_method(variable, "set", p_name, val)
	ur.add_undo_method(variable, "set", p_name, old_val)
	
	if variable.has_method("emit_changed"):
		ur.add_do_method(variable, "emit_changed")
		ur.add_undo_method(variable, "emit_changed")
		
	ur.commit_action()
	updating_from_ui = false

func _on_remove_variable(index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var variables: Array = object.get(property).duplicate()
	variables.remove_at(index)
	_apply_changes(variables, "Remove Variable")

func _on_add_pressed() -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var raw_val: Variant = object.get(property)
	
	# Fix: Use duplicate() to preserve Typed Array info
	var new_variables: Array = []
	if raw_val != null and raw_val is Array:
		new_variables = raw_val.duplicate()
	
	# Safe instantiation
	var new_var: StateVariable = StateVariableScript.new()
	new_var.variable_name = "new_var"
	new_variables.append(new_var)
	
	_apply_changes(new_variables, "Add Variable")

func _apply_changes(new_variables: Array, action_name: String) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var old_variables: Variant = object.get(property)
	
	if old_variables == null:
		old_variables = []
	elif old_variables is Array:
		old_variables = old_variables.duplicate()
	
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	
	# Use method calls for explicit setting
	ur.add_do_method(object, "set", property, new_variables)
	ur.add_undo_method(object, "set", property, old_variables)
	
	if object.has_method("notify_property_list_changed"):
		ur.add_do_method(object, "notify_property_list_changed")
		ur.add_undo_method(object, "notify_property_list_changed")
		
	ur.commit_action()
	
	# Force UI update immediately
	_update_property()
