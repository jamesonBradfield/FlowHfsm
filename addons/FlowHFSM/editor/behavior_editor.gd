@tool
extends EditorProperty

const ThemeResource = preload("res://addons/FlowHFSM/editor/flow_hfsm_theme.tres")

var container: VBoxContainer = VBoxContainer.new()
var updating_from_ui: bool = false
var folded_states: Dictionary = {} # Resource ID -> bool

func _init() -> void:
	label = "" # We draw our own label/header
	container.theme = ThemeResource
	add_child(container)

func _update_property() -> void:
	if updating_from_ui: return
	
	# Clear existing
	for child in container.get_children():
		child.queue_free()
	
	var edited_object: Object = get_edited_object()
	if not edited_object: return
	
	var property_path: StringName = get_edited_property()
	var behaviors = edited_object.get(property_path)
	
	if behaviors == null or not (behaviors is Array):
		behaviors = []
	
	if behaviors.is_empty():
		_draw_empty_state()
	else:
		_draw_list(behaviors)

func _draw_empty_state() -> void:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_empty_slot_style())
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl = Label.new()
	lbl.text = "No Behaviors Assigned"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(1, 1, 1, 0.5)
	vbox.add_child(lbl)
	
	var add_btn = Button.new()
	add_btn.text = "Add Behavior"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.custom_minimum_size.x = 120
	add_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_btn.pressed.connect(_on_add_pressed)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_child(add_btn)
	vbox.add_child(margin)
	
	panel.add_child(vbox)
	container.add_child(panel)

func _draw_list(behaviors: Array) -> void:
	var list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	
	for i in range(behaviors.size()):
		var behavior: Resource = behaviors[i]
		
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_card_style(Color(0.18, 0.20, 0.25, 1.0)))
		
		var card_vbox = VBoxContainer.new()
		
		# --- Header ---
		var header = HBoxContainer.new()
		
		# Fold Button
		var is_folded = false
		if behavior:
			is_folded = folded_states.get(behavior.get_instance_id(), false)
			
		var fold_btn = HFSMPropertyFactory.create_fold_button(is_folded, func():
			if behavior:
				folded_states[behavior.get_instance_id()] = not is_folded
				_update_property()
		)
		fold_btn.disabled = (behavior == null)
		header.add_child(fold_btn)
		
		# Resource Picker
		var picker = EditorResourcePicker.new()
		picker.base_type = "StateBehavior"
		picker.edited_resource = behavior
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.resource_changed.connect(_on_behavior_changed.bind(i))
		header.add_child(picker)
		
		# Delete Button
		var del_btn = Button.new()
		del_btn.icon = get_theme_icon("Remove", "EditorIcons")
		del_btn.tooltip_text = "Remove Behavior"
		del_btn.flat = true
		del_btn.pressed.connect(_on_remove_behavior.bind(i))
		header.add_child(del_btn)
		
		card_vbox.add_child(header)
		
		# --- Body ---
		if behavior and not is_folded:
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 14)
			margin.add_theme_constant_override("margin_top", 10)
			margin.add_theme_constant_override("margin_bottom", 4)
			
			var props_list = HFSMPropertyFactory.create_property_list(behavior, _on_behavior_property_changed.bind(behavior))
			margin.add_child(props_list)
			card_vbox.add_child(margin)
		
		card.add_child(card_vbox)
		list_vbox.add_child(card)
		
	container.add_child(list_vbox)
	
	# Bottom Add Button
	var add_btn_row = HBoxContainer.new()
	add_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var add_btn = Button.new()
	add_btn.text = "Add Behavior"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.pressed.connect(_on_add_pressed)
	add_btn_row.add_child(add_btn)
	container.add_child(add_btn_row)

func _on_behavior_changed(new_res: Resource, index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var behaviors: Array = object.get(property).duplicate()
	behaviors[index] = new_res
	_apply_changes(behaviors, "Change Behavior Resource")

func _on_behavior_property_changed(p_name: String, new_val: Variant, behavior: Resource) -> void:
	updating_from_ui = true
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var old_val: Variant = behavior.get(p_name)
	
	ur.create_action("Change Behavior Property: " + p_name)
	ur.add_do_method(behavior, "set", p_name, new_val)
	ur.add_undo_method(behavior, "set", p_name, old_val)
	if behavior.has_method("emit_changed"):
		ur.add_do_method(behavior, "emit_changed")
		ur.add_undo_method(behavior, "emit_changed")
	ur.commit_action()
	updating_from_ui = false

func _on_remove_behavior(index: int) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var behaviors: Array = object.get(property).duplicate()
	behaviors.remove_at(index)
	_apply_changes(behaviors, "Remove Behavior")

func _on_add_pressed() -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var behaviors: Array = object.get(property)
	if behaviors:
		behaviors = behaviors.duplicate()
	else:
		behaviors = []
	
	# Append null to let user pick
	behaviors.append(null)
	
	_apply_changes(behaviors, "Add Behavior")

func _apply_changes(new_behaviors: Array, action_name: String) -> void:
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var old_behaviors: Array = object.get(property)
	
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	ur.add_do_property(object, property, new_behaviors)
	ur.add_undo_property(object, property, old_behaviors)
	
	if object.has_method("notify_property_list_changed"):
		ur.add_do_method(object, "notify_property_list_changed")
		ur.add_undo_method(object, "notify_property_list_changed")
		
	ur.commit_action()
