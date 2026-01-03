extends EditorProperty

const PropertyFactory = preload("res://addons/hfsm_editor/property_factory.gd")

var container = VBoxContainer.new()
var is_expanded = true
var file_dialog: EditorFileDialog

func _init():
	add_child(container)
	
	file_dialog = EditorFileDialog.new()
	add_child(file_dialog)

func _update_property():
	# Clear existing children
	for child in container.get_children():
		if child != file_dialog:
			child.queue_free()
	
	var behavior = get_edited_object()[get_edited_property()]
	
	var header_box = HBoxContainer.new()
	container.add_child(header_box)
	
	var label = Label.new()
	label.text = "Behavior"
	header_box.add_child(label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(spacer)
	
	# Resource Picker for the main behavior slot
	var picker = EditorResourcePicker.new()
	picker.base_type = "StateBehavior"
	picker.edited_resource = behavior
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(func(res):
		emit_changed(get_edited_property(), res)
	)
	header_box.add_child(picker)

	# If we have a behavior, show its properties inline
	if behavior:
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.14, 0.6)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.border_width_left = 4
		style.border_color = Color(0.4, 0.5, 0.9) # Blue/Purple for Behavior
		style.content_margin_left = 10
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)
		
		var props_box = VBoxContainer.new()
		panel.add_child(props_box)
		
		# --- Header with Toggle and Open Button ---
		var panel_header = HBoxContainer.new()
		
		var toggle_btn = Button.new()
		toggle_btn.flat = true
		toggle_btn.icon = get_theme_icon("GuiTreeArrowDown" if is_expanded else "GuiTreeArrowRight", "EditorIcons")
		toggle_btn.pressed.connect(func(): 
			is_expanded = not is_expanded
			_update_property()
		)
		panel_header.add_child(toggle_btn)
		
		var script_lbl = Label.new()
		var script_name = "Embedded"
		
		if behavior.get_script():
			script_name = behavior.get_script().resource_path.get_file().get_basename()
		
		script_lbl.text = script_name
		script_lbl.add_theme_font_size_override("font_size", 13)
		script_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		panel_header.add_child(script_lbl)
		
		# Add Smart Resource Toolbar
		var toolbar = _create_resource_toolbar(behavior, func(new_res):
			if new_res != behavior:
				emit_changed(get_edited_property(), new_res)
			_update_property()
		)
		panel_header.add_child(toolbar)
		
		var h_spacer = Control.new()
		h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_header.add_child(h_spacer)
		
		var open_btn = Button.new()
		open_btn.tooltip_text = "Open Resource in full Inspector"
		open_btn.icon = get_theme_icon("Edit", "EditorIcons")
		open_btn.flat = true
		open_btn.pressed.connect(func(): EditorInterface.edit_resource(behavior), CONNECT_DEFERRED)
		panel_header.add_child(open_btn)
		
		props_box.add_child(panel_header)
		
		# --- Properties List ---
		if is_expanded:
			var list_container = VBoxContainer.new()
			# Indent slightly
			var margin_container = MarginContainer.new()
			margin_container.add_theme_constant_override("margin_left", 24)
			margin_container.add_theme_constant_override("margin_top", 4)
			margin_container.add_child(list_container)
			
			props_box.add_child(margin_container)
			
			for prop in behavior.get_property_list():
				if prop.usage & PROPERTY_USAGE_EDITOR:
					var p_name = prop.name
					if p_name in ["script", "resource_name", "resource_path", "resource_local_to_scene"]:
						continue
						
					var row = HBoxContainer.new()
					row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					
					var p_label = Label.new()
					p_label.text = p_name.capitalize()
					p_label.modulate = Color(0.8, 0.8, 0.8)
					p_label.custom_minimum_size.x = 100
					row.add_child(p_label)
					
					var editor = PropertyFactory.create_control_for_property(behavior, prop, func(name, val):
						behavior.set(name, val)
						emit_changed(get_edited_property(), behavior)
					)
					editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					row.add_child(editor)
					
					list_container.add_child(row)
				
		container.add_child(panel)

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

func _find_owner_node(resource: Resource) -> Node:
	# This is a bit of a hack to guess where an embedded resource comes from.
	# We search the current scene to see if any other node references this EXACT resource instance.
	var root = get_tree().edited_scene_root
	if not root: return null
	
	var owners = []
	_search_resource_usage(root, resource, owners)
	
	if owners.size() > 0:
		return owners[0] # Return the first one found
	return null

func _search_resource_usage(node: Node, target_res: Resource, result: Array):
	# Check script properties
	var props = node.get_property_list()
	for p in props:
		if p.type == TYPE_OBJECT and (p.usage & PROPERTY_USAGE_STORAGE):
			var val = node.get(p.name)
			if val == target_res:
				result.append(node)
				return
				
	# Recurse
	for child in node.get_children():
		_search_resource_usage(child, target_res, result)
