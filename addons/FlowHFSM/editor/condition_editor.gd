@tool
extends EditorProperty

const ThemeResource = preload("res://addons/FlowHFSM/editor/flow_hfsm_theme.tres")
const HFSMPropertyFactory = preload("res://addons/FlowHFSM/editor/property_factory.gd")

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
	var conditions: Variant = object.get(property)
	
	if conditions == null or not (conditions is Array):
		conditions = []
	
	if conditions.is_empty():
		_draw_empty_state()
	else:
		_draw_list(conditions)

func _draw_empty_state() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_empty_slot_style())
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl: Label = Label.new()
	lbl.text = "No Activation Conditions"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(1, 1, 1, 0.5)
	vbox.add_child(lbl)
	
	var add_btn: Button = Button.new()
	add_btn.text = "Add Condition"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.custom_minimum_size.x = 120
	add_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_btn.pressed.connect(_on_add_pressed)
	
	var btn_hbox: HBoxContainer = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 10)
	btn_hbox.add_child(add_btn)
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_child(btn_hbox)
	vbox.add_child(margin)
	
	panel.add_child(vbox)
	container.add_child(panel)

func _draw_list(conditions: Array) -> void:
	var list_vbox: VBoxContainer = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	
	for i in range(conditions.size()):
		var condition: Resource = conditions[i]
		
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_card_style())
		
		var card_vbox: VBoxContainer = VBoxContainer.new()
		
		# --- Header ---
		var header: HBoxContainer = HBoxContainer.new()
		
		# Fold
		var is_folded: bool = false
		if condition:
			is_folded = folded_states.get(condition.get_instance_id(), false)
			
		var fold_btn: Button = HFSMPropertyFactory.create_fold_button(is_folded, func():
			if condition:
				folded_states[condition.get_instance_id()] = not is_folded
				_update_property()
		)
		fold_btn.disabled = (condition == null)
		header.add_child(fold_btn)
		
		# Picker
		var picker: EditorResourcePicker = EditorResourcePicker.new()
		picker.base_type = "StateCondition"
		picker.edited_resource = condition
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.resource_changed.connect(_on_condition_changed.bind(i))
		header.add_child(picker)
		
		# Delete
		var del_btn: Button = Button.new()
		del_btn.icon = get_theme_icon("Remove", "EditorIcons")
		del_btn.tooltip_text = "Remove Condition"
		del_btn.flat = true
		del_btn.pressed.connect(_on_remove_condition.bind(i))
		header.add_child(del_btn)
		
		card_vbox.add_child(header)
		
		# --- Body ---
		if condition and not is_folded:
			var margin: MarginContainer = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 14)
			margin.add_theme_constant_override("margin_top", 4)
			
			var props_list: Control = HFSMPropertyFactory.create_property_list(condition, _on_condition_property_changed.bind(condition))
			margin.add_child(props_list)
			card_vbox.add_child(margin)
		
		card.add_child(card_vbox)
		list_vbox.add_child(card)
		
	container.add_child(list_vbox)
	
	# Bottom Add Button
	var add_btn_row: HBoxContainer = HBoxContainer.new()
	add_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_btn_row.add_theme_constant_override("separation", 10)
	
	var add_btn: Button = Button.new()
	add_btn.text = "Add Condition"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.pressed.connect(_on_add_pressed)
	add_btn_row.add_child(add_btn)
	
	container.add_child(add_btn_row)

func _on_condition_changed(new_res: Resource, index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var conditions: Array = object.get(property).duplicate()
	conditions[index] = new_res
	_apply_changes(conditions, "Change Condition Resource")

func _on_condition_property_changed(p_name: String, val: Variant, condition: Resource) -> void:
	updating_from_ui = true
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var old_val: Variant = condition.get(p_name)
	
	ur.create_action("Change Condition Property: " + p_name)
	ur.add_do_method(condition, "set", p_name, val)
	ur.add_undo_method(condition, "set", p_name, old_val)
	
	if condition.has_method("emit_changed"):
		ur.add_do_method(condition, "emit_changed")
		ur.add_undo_method(condition, "emit_changed")
		
	ur.commit_action()
	updating_from_ui = false

func _on_remove_condition(index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var conditions: Array = object.get(property).duplicate()
	conditions.remove_at(index)
	_apply_changes(conditions, "Remove Condition")

func _on_add_pressed() -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var raw_val: Variant = object.get(property)
	
	# Fix: Use duplicate() to preserve Typed Array info (Array[StateCondition])
	var new_conditions: Array = []
	if raw_val != null and raw_val is Array:
		new_conditions = raw_val.duplicate()
	
	# Append null
	new_conditions.append(null)
	
	_apply_changes(new_conditions, "Add Condition")

func _apply_changes(new_conditions: Array, action_name: String) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var old_conditions: Variant = object.get(property)
	
	if old_conditions == null:
		old_conditions = []
	elif old_conditions is Array:
		old_conditions = old_conditions.duplicate()
	
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	
	# Use method calls for explicit setting
	ur.add_do_method(object, "set", property, new_conditions)
	ur.add_undo_method(object, "set", property, old_conditions)
	
	if object.has_method("notify_property_list_changed"):
		ur.add_do_method(object, "notify_property_list_changed")
		ur.add_undo_method(object, "notify_property_list_changed")
		
	ur.commit_action()
	
	# Force UI update immediately
	_update_property()
