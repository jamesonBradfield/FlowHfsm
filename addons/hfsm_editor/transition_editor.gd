extends EditorProperty

const PropertyFactory = preload("res://addons/hfsm_editor/property_factory.gd")

var container = VBoxContainer.new()
var file_dialog: EditorFileDialog

func _init():
	label = ""
	add_child(container)
	container.add_theme_constant_override("separation", 10)
	
	file_dialog = EditorFileDialog.new()
	add_child(file_dialog)

func _update_property():
	# Clear existing children
	for child in container.get_children():
		if child != file_dialog:
			child.queue_free()
	
	var transitions = get_edited_object()[get_edited_property()]
	
	if transitions == null:
		# Initialize if null
		transitions = []
		get_edited_object()[get_edited_property()] = transitions

	# --- List ---
	if transitions.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No transitions defined."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(empty_label)

	for i in range(transitions.size()):
		var t = transitions[i]
		if not t: continue
		
		var panel = PanelContainer.new()
		
		# Zebra Striping
		if i % 2 != 0:
			var bg_rect = ColorRect.new()
			bg_rect.color = Color(1, 1, 1, 0.03)
			bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(bg_rect)
			
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.12, 0.12, 0.12, 0.6)
		panel_style.corner_radius_top_left = 4
		panel_style.corner_radius_top_right = 4
		panel_style.corner_radius_bottom_left = 4
		panel_style.corner_radius_bottom_right = 4
		panel_style.border_width_left = 4
		panel_style.border_color = Color(0.2, 0.8, 0.2) if t.operation == 0 else Color(1.0, 0.6, 0.0)
		panel_style.content_margin_left = 8
		panel_style.content_margin_right = 8
		panel_style.content_margin_top = 8
		panel_style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", panel_style)
		
		var v_box = VBoxContainer.new()
		panel.add_child(v_box)
		
		# 1. Operation Row
		var op_row = HBoxContainer.new()
		
		var op_label = Label.new()
		op_label.text = "Logic:"
		op_row.add_child(op_label)
		
		var op_selector = OptionButton.new()
		op_selector.add_item("AND (All True)", 0)
		op_selector.add_item("OR (Any True)", 1)
		op_selector.selected = t.operation
		op_selector.tooltip_text = "Logic Operation"
		op_selector.item_selected.connect(func(idx): 
			t.operation = idx
			emit_changed(get_edited_property(), transitions)
			_update_property() # Refresh to update border color
		)
		op_row.add_child(op_selector)

		var op_spacer = Control.new()
		op_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		op_row.add_child(op_spacer)
		
		# Move Up
		var btn_up = Button.new()
		btn_up.flat = true
		btn_up.icon = get_theme_icon("MoveUp", "EditorIcons")
		btn_up.tooltip_text = "Move Up"
		if i == 0: btn_up.disabled = true
		btn_up.pressed.connect(func(): _move_transition(i, -1))
		op_row.add_child(btn_up)

		# Move Down
		var btn_down = Button.new()
		btn_down.flat = true
		btn_down.icon = get_theme_icon("MoveDown", "EditorIcons")
		btn_down.tooltip_text = "Move Down"
		if i == transitions.size() - 1: btn_down.disabled = true
		btn_down.pressed.connect(func(): _move_transition(i, 1))
		op_row.add_child(btn_down)
		
		var remove_trans_btn = Button.new()
		remove_trans_btn.tooltip_text = "Remove Transition"
		remove_trans_btn.icon = get_theme_icon("Remove", "EditorIcons")
		remove_trans_btn.flat = true
		remove_trans_btn.modulate = Color(1, 0.4, 0.4)
		remove_trans_btn.pressed.connect(func(): _remove_transition(i))
		op_row.add_child(remove_trans_btn)
		
		v_box.add_child(op_row)
		
		# 2. Conditions List
		var cond_label = Label.new()
		cond_label.text = "Conditions:"
		cond_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		v_box.add_child(cond_label)
		
		var cond_container = VBoxContainer.new()
		cond_container.add_theme_constant_override("separation", 6)
		v_box.add_child(cond_container)
		
		for j in range(t.conditions.size()):
			var c = t.conditions[j]
			var cond_box = VBoxContainer.new()
			
			# 1. Row: Picker + Toolbar + Remove
			var cond_row = HBoxContainer.new()
			
			# Resource Picker
			var picker = EditorResourcePicker.new()
			picker.base_type = "StateCondition"
			picker.edited_resource = c
			picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			picker.resource_changed.connect(func(res): 
				t.conditions[j] = res
				emit_changed(get_edited_property(), transitions)
				_update_property()
			)
			cond_row.add_child(picker)
			
			# Smart Resource Controls
			if c:
				var toolbar = _create_resource_toolbar(c, func(new_res):
					if new_res != c:
						t.conditions[j] = new_res
						emit_changed(get_edited_property(), transitions)
					_update_property()
				)
				cond_row.add_child(toolbar)
			
			# Remove Condition Button
			var del_cond_btn = Button.new()
			del_cond_btn.icon = get_theme_icon("Remove", "EditorIcons")
			del_cond_btn.tooltip_text = "Remove Condition"
			del_cond_btn.flat = true
			del_cond_btn.pressed.connect(func(): 
				t.conditions.remove_at(j)
				emit_changed(get_edited_property(), transitions)
				_update_property()
			)
			cond_row.add_child(del_cond_btn)
			
			cond_box.add_child(cond_row)

			# 2. Inline Properties (if condition exists)
			if c:
				var props_panel = PanelContainer.new()
				var props_style = StyleBoxFlat.new()
				props_style.bg_color = Color(0.08, 0.08, 0.08, 0.4)
				props_style.corner_radius_bottom_left = 4
				props_style.corner_radius_bottom_right = 4
				props_style.content_margin_left = 12
				props_style.content_margin_top = 4
				props_style.content_margin_bottom = 4
				props_panel.add_theme_stylebox_override("panel", props_style)
				
				var props_list = VBoxContainer.new()
				props_panel.add_child(props_list)
				
				# Show exports
				for prop in c.get_property_list():
					if prop.usage & PROPERTY_USAGE_EDITOR:
						var p_name = prop.name
						if p_name in ["script", "resource_name", "resource_path", "resource_local_to_scene"]:
							continue
							
						var p_row = HBoxContainer.new()
						p_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						
						var p_lbl = Label.new()
						p_lbl.text = p_name.capitalize()
						p_lbl.tooltip_text = p_name
						p_lbl.modulate = Color(0.7, 0.7, 0.7)
						p_lbl.custom_minimum_size.x = 110
						p_lbl.add_theme_font_size_override("font_size", 12)
						p_row.add_child(p_lbl)
						
						var editor = PropertyFactory.create_control_for_property(c, prop, func(name, val):
							c.set(name, val)
							emit_changed(get_edited_property(), transitions)
						)
						editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						p_row.add_child(editor)
						
						props_list.add_child(p_row)
				
				if props_list.get_child_count() > 0:
					cond_box.add_child(props_panel)
			
			cond_container.add_child(cond_box)
			
		# Add Condition Button
		var add_cond_btn = Button.new()
		add_cond_btn.text = "Add Condition"
		add_cond_btn.icon = get_theme_icon("Add", "EditorIcons")
		add_cond_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		add_cond_btn.pressed.connect(func(): 
			t.conditions.append(null)
			emit_changed(get_edited_property(), transitions)
			_update_property()
		)
		v_box.add_child(add_cond_btn)

		container.add_child(panel)

	# --- Add Transition Button (Bottom, Full Width) ---
	var add_trans_btn = Button.new()
	add_trans_btn.text = "Add Transition"
	add_trans_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_trans_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_trans_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_trans_btn.pressed.connect(_add_transition)
	container.add_child(add_trans_btn)

func _create_resource_toolbar(resource: Resource, callback: Callable) -> Control:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	var is_shared = not resource.resource_path.is_empty() and not resource.resource_path.contains("::")
	
	var label = Label.new()
	label.text = "SHARED" if is_shared else "LOCAL"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2) if is_shared else Color(0.6, 0.8, 1.0))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	if is_shared:
		var btn_unique = Button.new()
		btn_unique.tooltip_text = "Make Unique (Duplicate)"
		btn_unique.icon = get_theme_icon("Duplicate", "EditorIcons")
		btn_unique.flat = true
		btn_unique.pressed.connect(func():
			var new_res = resource.duplicate()
			callback.call(new_res)
		)
		container.add_child(btn_unique)
	else:
		var btn_save = Button.new()
		btn_save.tooltip_text = "Save to File"
		btn_save.icon = get_theme_icon("Save", "EditorIcons")
		btn_save.flat = true
		btn_save.pressed.connect(func():
			file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
			file_dialog.clear_filters()
			file_dialog.add_filter("*.tres", "Resource")
			
			# Disconnect previous connections safely
			var conns = file_dialog.file_selected.get_connections()
			for c in conns:
				file_dialog.file_selected.disconnect(c.callable)
				
			file_dialog.file_selected.connect(func(path):
				ResourceSaver.save(resource, path)
				resource.take_over_path(path)
				callback.call(resource)
			, CONNECT_ONE_SHOT)
			
			file_dialog.popup_centered_ratio(0.5)
		)
		container.add_child(btn_save)
		
	return container

func _add_transition():
	var transitions = get_edited_object()[get_edited_property()]
	var new_t = StateTransition.new()
	# Default to empty conditions
	new_t.conditions = []
	transitions.append(new_t)
	emit_changed(get_edited_property(), transitions)
	_update_property()

func _remove_transition(index: int):
	var transitions = get_edited_object()[get_edited_property()]
	transitions.remove_at(index)
	emit_changed(get_edited_property(), transitions)
	_update_property()

func _move_transition(index: int, direction: int):
	var transitions = get_edited_object()[get_edited_property()]
	var target_index = index + direction
	if target_index >= 0 and target_index < transitions.size():
		var t = transitions[index]
		transitions.remove_at(index)
		transitions.insert(target_index, t)
		emit_changed(get_edited_property(), transitions)
		_update_property()
