extends EditorProperty

const PropertyFactory = preload("res://addons/hfsm_editor/property_factory.gd")

var container = VBoxContainer.new()
var is_expanded = true

func _init():
	label = ""
	add_child(container)

func _update_property():
	# Clear existing children
	for child in container.get_children():
		child.queue_free()
	
	var behavior = get_edited_object()[get_edited_property()]
	
	var header_box = HBoxContainer.new()
	container.add_child(header_box)
	
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
		var border_color = Color(0.4, 0.5, 0.9) # Blue/Purple for Behavior
		panel.add_theme_stylebox_override("panel", PropertyFactory.create_panel_style(border_color))
		
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
		
		# Add Smart Resource Toolbar
		var toolbar = PropertyFactory.create_resource_toolbar(behavior, self, func(new_res):
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
					p_label.tooltip_text = p_name
					p_label.modulate = Color(0.8, 0.8, 0.8)
					p_label.custom_minimum_size.x = 110
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
