extends EditorProperty

const PropertyFactory = preload("res://addons/hfsm_editor/property_factory.gd")

var container = VBoxContainer.new()
var is_expanded = true

func _init():
	add_child(container)

func _update_property():
	# Clear existing children
	for child in container.get_children():
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
		style.bg_color = Color(0.15, 0.15, 0.2, 0.5)
		style.content_margin_left = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		panel.add_theme_stylebox_override("panel", style)
		
		var props_box = VBoxContainer.new()
		panel.add_child(props_box)
		
		# --- Header with Toggle and Open Button ---
		var panel_header = HBoxContainer.new()
		
		var toggle_btn = Button.new()
		toggle_btn.flat = true
		toggle_btn.text = "▼" if is_expanded else "▶"
		toggle_btn.pressed.connect(func(): 
			is_expanded = not is_expanded
			_update_property()
		)
		panel_header.add_child(toggle_btn)
		
		var script_lbl = Label.new()
		var script_name = "Embedded"
		var is_shared = false
		
		if behavior.get_script():
			script_name = behavior.get_script().resource_path.get_file().get_basename()
		
		if not behavior.resource_path.is_empty() and not behavior.resource_path.contains("::"):
			script_name += " (Shared)"
			is_shared = true
		else:
			var owner_node = _find_owner_node(behavior)
			if owner_node and owner_node != get_edited_object():
				script_name += " (From: %s)" % owner_node.name
				is_shared = true # Technically shared via reference
			else:
				script_name += " (Local)"
			
		script_lbl.text = script_name
		script_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if not is_shared else Color(1, 0.8, 0.5))
		panel_header.add_child(script_lbl)
		
		var h_spacer = Control.new()
		h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_header.add_child(h_spacer)
		
		var open_btn = Button.new()
		open_btn.text = "Edit"
		open_btn.tooltip_text = "Open Resource in full Inspector"
		open_btn.pressed.connect(func(): EditorInterface.edit_resource(behavior), CONNECT_DEFERRED)
		panel_header.add_child(open_btn)
		
		props_box.add_child(panel_header)
		
		# --- Properties List ---
		if is_expanded:
			var list_container = VBoxContainer.new()
			# Indent slightly
			var margin_container = MarginContainer.new()
			margin_container.add_theme_constant_override("margin_left", 20)
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
