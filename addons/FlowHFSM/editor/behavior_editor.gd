@tool
extends EditorProperty

const ThemeResource = preload("res://addons/FlowHFSM/editor/flow_hfsm_theme.tres")

var container: VBoxContainer = VBoxContainer.new()
var current_behavior: Resource
var updating_from_ui: bool = false
var is_folded: bool = false

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
	var behavior: Resource = edited_object.get(property_path)
	
	# Connection management
	if current_behavior != behavior:
		if current_behavior and current_behavior.changed.is_connected(_on_behavior_changed):
			current_behavior.changed.disconnect(_on_behavior_changed)
		current_behavior = behavior
		if current_behavior:
			if not current_behavior.changed.is_connected(_on_behavior_changed):
				current_behavior.changed.connect(_on_behavior_changed)
	
	if not behavior:
		_draw_empty_state()
	else:
		_draw_filled_state(behavior)

func _draw_empty_state() -> void:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_empty_slot_style())
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var lbl = Label.new()
	lbl.text = "No Behavior Assigned"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(1, 1, 1, 0.5)
	vbox.add_child(lbl)
	
	var picker = EditorResourcePicker.new()
	picker.base_type = "StateBehavior"
	picker.edited_resource = null
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(_on_resource_picked)
	
	# Center the picker somewhat
	var picker_holder = MarginContainer.new()
	picker_holder.add_theme_constant_override("margin_left", 40)
	picker_holder.add_theme_constant_override("margin_right", 40)
	picker_holder.add_theme_constant_override("margin_top", 10)
	picker_holder.add_child(picker)
	
	vbox.add_child(picker_holder)
	panel.add_child(vbox)
	container.add_child(panel)

func _draw_filled_state(behavior: Resource) -> void:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", HFSMPropertyFactory.create_card_style(Color(0.18, 0.20, 0.25, 1.0)))
	
	var vbox = VBoxContainer.new()
	
	# --- Header ---
	var header = HBoxContainer.new()
	
	# Fold Button
	var fold_btn = HFSMPropertyFactory.create_fold_button(is_folded, func():
		is_folded = not is_folded
		_update_property() # Re-draw to toggle visibility
	)
	header.add_child(fold_btn)
	
	# Resource Picker (Acts as Title + Actions)
	var picker = EditorResourcePicker.new()
	picker.base_type = "StateBehavior"
	picker.edited_resource = behavior
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(_on_resource_picked)
	header.add_child(picker)
	
	vbox.add_child(header)
	
	# --- Body ---
	if not is_folded:
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 4)
		
		var props_list = HFSMPropertyFactory.create_property_list(behavior, _on_property_changed.bind(behavior))
		margin.add_child(props_list)
		vbox.add_child(margin)
	
	card.add_child(vbox)
	container.add_child(card)

func _on_resource_picked(res: Resource) -> void:
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var object: Object = get_edited_object()
	var property: StringName = get_edited_property()
	var old_res: Variant = object.get(property)
	
	ur.create_action("Change Behavior Resource")
	ur.add_do_property(object, property, res)
	ur.add_undo_property(object, property, old_res)
	if object.has_method("notify_property_list_changed"):
		ur.add_do_method(object, "notify_property_list_changed")
		ur.add_undo_method(object, "notify_property_list_changed")
	ur.commit_action()

func _on_property_changed(p_name: String, new_val: Variant, behavior: Resource) -> void:
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

func _on_behavior_changed() -> void:
	_update_property()
