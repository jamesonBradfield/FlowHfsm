@tool
extends EditorProperty

const Factory = preload("res://addons/hfsm_editor/editor/property_factory.gd")
const ThemeResource = preload("res://addons/hfsm_editor/editor/hfsm_editor_theme.tres")

var container: VBoxContainer = VBoxContainer.new()
var updating_from_ui: bool = false

func _init() -> void:
	label = ""
	container.theme = ThemeResource
	add_child(container)

func _update_property() -> void:
	if updating_from_ui: return
	
	# Clear existing children
	for child in container.get_children():
		child.queue_free()
	
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var conditions: Array = object.get(property)
	
	if conditions == null:
		conditions = []
	
	# List of conditions
	for i in range(conditions.size()):
		var condition: StateCondition = conditions[i]
		
		# 1. Header (Picker + Delete)
		var header: HBoxContainer = HBoxContainer.new()
		
		var picker: EditorResourcePicker = EditorResourcePicker.new()
		picker.base_type = "StateCondition"
		picker.edited_resource = condition
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Bind index to ensure correct removal/change
		picker.resource_changed.connect(_on_condition_changed.bind(i))
		header.add_child(picker)
		
		var del_btn: Button = Button.new()
		del_btn.icon = get_theme_icon("Remove", "EditorIcons")
		del_btn.tooltip_text = "Remove Condition"
		del_btn.flat = true
		del_btn.pressed.connect(_on_remove_condition.bind(i))
		header.add_child(del_btn)
		
		container.add_child(header)
		
		# 2. Inline Properties (if resource exists)
		if condition:
			var margin: MarginContainer = MarginContainer.new()
			# Indent to visually associate properties with the condition
			margin.add_theme_constant_override("margin_left", 20)
			
			var props_list: Control = Factory.create_property_list(condition, func(p_name, val):
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
			)
			margin.add_child(props_list)
			container.add_child(margin)
			
		# Small spacer
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.y = 4
		container.add_child(spacer)
		
	# Add Button
	var add_btn: Button = Button.new()
	add_btn.text = "Add Condition"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.pressed.connect(_on_add_pressed)
	container.add_child(add_btn)

func _on_condition_changed(new_res: Resource, index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var conditions: Array = object.get(property).duplicate()
	conditions[index] = new_res
	_apply_changes(conditions, "Change Condition Resource")

func _on_remove_condition(index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var conditions: Array = object.get(property).duplicate()
	conditions.remove_at(index)
	_apply_changes(conditions, "Remove Condition")

func _on_add_pressed() -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var conditions: Array = object.get(property)
	if conditions:
		conditions = conditions.duplicate()
	else:
		conditions = []
	conditions.append(null)
	_apply_changes(conditions, "Add Condition")

func _apply_changes(new_conditions: Array, action_name: String) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var old_conditions: Array = object.get(property)
	
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	ur.add_do_property(object, property, new_conditions)
	ur.add_undo_property(object, property, old_conditions)
	
	if object.has_method("notify_property_list_changed"):
		ur.add_do_method(object, "notify_property_list_changed")
		ur.add_undo_method(object, "notify_property_list_changed")
		
	ur.commit_action()
