extends EditorProperty

const PropertyFactory = preload("res://addons/hfsm_editor/property_factory.gd")

var container = VBoxContainer.new()

func _init():
	add_child(container)
	container.add_theme_constant_override("separation", 10)

func _update_property():
	# Clear existing children
	for child in container.get_children():
		child.queue_free()
	
	var transitions = get_edited_object()[get_edited_property()]
	
	if transitions == null:
		# Initialize if null
		transitions = []
		get_edited_object()[get_edited_property()] = transitions

	# --- Header ---
	var header_box = HBoxContainer.new()
	var header = Label.new()
	header.text = "Transitions (%d)" % transitions.size()
	header_box.add_child(header)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(spacer)
	
	var add_trans_btn = Button.new()
	add_trans_btn.text = "+ Add Transition"
	add_trans_btn.pressed.connect(_add_transition)
	header_box.add_child(add_trans_btn)
	
	container.add_child(header_box)
	
	# --- List ---
	for i in range(transitions.size()):
		var t = transitions[i]
		if not t: continue
		
		var panel = PanelContainer.new()
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
		panel_style.border_width_left = 2
		panel_style.border_color = Color.GREEN if t.operation == 0 else Color.ORANGE
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
		op_selector.item_selected.connect(func(idx): 
			t.operation = idx
			emit_changed(get_edited_property(), transitions)
			_update_property() # Refresh to update border color
		)
		op_row.add_child(op_selector)

		var expand_btn = Button.new()
		expand_btn.text = "Open Resource"
		expand_btn.pressed.connect(func(): EditorInterface.edit_resource(t), CONNECT_DEFERRED)
		op_row.add_child(expand_btn)
		
		var op_spacer = Control.new()
		op_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		op_row.add_child(op_spacer)
		
		var remove_trans_btn = Button.new()
		remove_trans_btn.text = "Remove"
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
		v_box.add_child(cond_container)
		
		for j in range(t.conditions.size()):
			var c = t.conditions[j]
			var cond_box = VBoxContainer.new()
			
			# 1. Row: Picker + Info + Remove Button
			var cond_row = HBoxContainer.new()
			
			# Resource Picker
			var picker = EditorResourcePicker.new()
			picker.base_type = "StateCondition"
			picker.edited_resource = c
			picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			picker.resource_changed.connect(func(res): 
				t.conditions[j] = res
				emit_changed(get_edited_property(), transitions)
				_update_property() # Refresh to show properties
			)
			cond_row.add_child(picker)

			# Shared/Local Info Label
			if c:
				var info_lbl = Label.new()
				var info_text = ""
				var is_shared_cond = false
				
				if not c.resource_path.is_empty() and not c.resource_path.contains("::"):
					info_text = "(Shared)"
					is_shared_cond = true
				else:
					# Use a similar heuristic or just mark as local
					info_text = "(Local)"
				
				info_lbl.text = info_text
				info_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if not is_shared_cond else Color(1, 0.8, 0.5))
				info_lbl.add_theme_font_size_override("font_size", 10)
				cond_row.add_child(info_lbl)
			
			# Remove Condition Button
			var del_cond_btn = Button.new()
			del_cond_btn.text = "X"
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
				props_style.bg_color = Color(0.05, 0.05, 0.05, 0.2)
				props_style.content_margin_left = 15
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
						p_lbl.modulate = Color(0.7, 0.7, 0.7)
						p_lbl.custom_minimum_size.x = 90
						p_lbl.add_theme_font_size_override("font_size", 12)
						p_row.add_child(p_lbl)
						
						var editor = PropertyFactory.create_control_for_property(c, prop, func(name, val):
							c.set(name, val)
							# Note: Modifying a sub-resource might not trigger the main property changed signal automatically
							# We force an update to be safe, though c.emit_changed() should handle it if Resource is set up right
							emit_changed(get_edited_property(), transitions)
						)
						editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						p_row.add_child(editor)
						
						props_list.add_child(p_row)
				
				if props_list.get_child_count() > 0:
					cond_box.add_child(props_panel)
			
			cond_container.add_child(cond_box)
			
			# Add small separator if not last
			if j < t.conditions.size() - 1:
				var sep = HSeparator.new()
				sep.modulate = Color(1, 1, 1, 0.1)
				cond_container.add_child(sep)
			
		# Add Condition Button
		var add_cond_btn = Button.new()
		add_cond_btn.text = "+ Add Condition"
		add_cond_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		add_cond_btn.pressed.connect(func(): 
			t.conditions.append(null)
			emit_changed(get_edited_property(), transitions)
			_update_property()
		)
		v_box.add_child(add_cond_btn)

		container.add_child(panel)

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
