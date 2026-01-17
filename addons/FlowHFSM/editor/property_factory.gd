@tool
class_name HFSMPropertyFactory
extends RefCounted

const COLOR_BACKGROUND = Color(0.15, 0.17, 0.23, 0.5)
const COLOR_BORDER = Color(0.25, 0.27, 0.33, 0.8)
const COLOR_HEADER = Color(0.20, 0.22, 0.28, 0.8)

# --- Styling ---

static func create_card_style(bg_color: Color = COLOR_BACKGROUND) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = COLOR_BORDER
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	return style

static func create_empty_slot_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4, 0.3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style

# --- Components ---

static func create_fold_button(is_folded: bool, callback: Callable) -> Button:
	var btn = Button.new()
	btn.flat = true
	# Use standard editor icons
	var update_icon = func():
		var icon_name = "GuiTreeArrowRight" if is_folded else "GuiTreeArrowDown"
		# Fallback if theme isn't ready yet
		if Engine.is_editor_hint():
			btn.icon = EditorInterface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
	
	update_icon.call()
	btn.pressed.connect(func():
		callback.call()
	)
	return btn

static func create_header_background() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_HEADER
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	return style

# --- Property Editors ---

static func _apply_tooltip(control: Control, property: Dictionary) -> void:
	if property.get("hint_string", "") != "":
		control.tooltip_text = property.hint_string
	else:
		control.tooltip_text = property.name.capitalize()

static func create_control_for_property(object: Object, property: Dictionary, changed_callback: Callable, depth: int = 0) -> Control:
	if depth > 8:
		var lbl = Label.new()
		lbl.text = "..."
		lbl.tooltip_text = "Recursion limit reached"
		return lbl

	var type: int = property.type
	var name: String = property.name
	var value: Variant = object.get(name)
	var hint: int = property.hint
	var hint_string: String = property.hint_string
	
	# If type is NIL (Variant), infer from value
	if type == TYPE_NIL:
		if value != null:
			type = typeof(value)
		else:
			# If null, provide a Type Selector + Fallback Editor
			return _create_variant_editor(object, name, value, changed_callback, depth)

	match type:
		TYPE_BOOL:
			var cb: CheckBox = CheckBox.new()
			cb.button_pressed = bool(value)
			cb.tooltip_text = property.name.capitalize()
			_apply_tooltip(cb, property)
			cb.toggled.connect(func(v): changed_callback.call(name, v))
			return cb
			
		TYPE_INT:
			if hint == PROPERTY_HINT_ENUM:
				var opt: OptionButton = OptionButton.new()
				var items: PackedStringArray = hint_string.split(",")
				var current_idx = 0
				
				for item_str in items:
					var item_split: PackedStringArray = item_str.split(":")
					var item_name: String = item_split[0]
					var item_val: int = current_idx
					if item_split.size() > 1:
						item_val = int(item_split[1])
					
					opt.add_item(item_name, item_val)
					if item_val == value:
						opt.select(opt.item_count - 1)
					
					current_idx = item_val + 1
				
				_apply_tooltip(opt, property)
				opt.item_selected.connect(func(idx): 
					var id: int = opt.get_item_id(idx)
					changed_callback.call(name, id)
				)
				return opt
			else:
				var sb: SpinBox = SpinBox.new()
				sb.min_value = -2147483648
				sb.max_value = 2147483647
				sb.step = 1
				sb.allow_greater = true
				sb.allow_lesser = true
				
				# Parse Hint String for Range (min,max,step,or_greater,or_lesser)
				if hint == PROPERTY_HINT_RANGE:
					var parts = hint_string.split(",")
					if parts.size() >= 2:
						sb.min_value = float(parts[0])
						sb.max_value = float(parts[1])
						sb.allow_lesser = false
						sb.allow_greater = false
					if parts.size() >= 3:
						sb.step = float(parts[2])
					if "or_greater" in hint_string:
						sb.allow_greater = true
					if "or_lesser" in hint_string:
						sb.allow_lesser = true
				
				sb.value = float(value)
				_apply_tooltip(sb, property)
				sb.value_changed.connect(func(v): changed_callback.call(name, int(v)))
				return sb
				
		TYPE_FLOAT:
			var sb: SpinBox = SpinBox.new()
			sb.min_value = -99999.0
			sb.max_value = 99999.0
			sb.step = 0.001
			sb.allow_greater = true
			sb.allow_lesser = true
			
			if hint == PROPERTY_HINT_RANGE:
				var parts = hint_string.split(",")
				if parts.size() >= 2:
					sb.min_value = float(parts[0])
					sb.max_value = float(parts[1])
					sb.allow_lesser = false
					sb.allow_greater = false
				if parts.size() >= 3:
					sb.step = float(parts[2])
				if "or_greater" in hint_string:
					sb.allow_greater = true
				if "or_lesser" in hint_string:
					sb.allow_lesser = true
			
			sb.value = value
			sb.custom_minimum_size.x = 80
			_apply_tooltip(sb, property)
			sb.value_changed.connect(func(v): changed_callback.call(name, v))
			return sb
			
		TYPE_STRING, TYPE_STRING_NAME:
			if hint == PROPERTY_HINT_MULTILINE_TEXT:
				var te: TextEdit = TextEdit.new()
				te.text = str(value) if value != null else ""
				te.custom_minimum_size.y = 80
				te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
				_apply_tooltip(te, property)
				te.text_changed.connect(func(): changed_callback.call(name, te.text))
				return te
			else:
				var le: LineEdit = LineEdit.new()
				le.text = str(value) if value != null else ""
				le.expand_to_text_length = true
				le.custom_minimum_size.x = 120
				_apply_tooltip(le, property)
				le.text_changed.connect(func(v): changed_callback.call(name, v))
				return le
		
		TYPE_COLOR:
			var cp: ColorPickerButton = ColorPickerButton.new()
			cp.color = value
			cp.custom_minimum_size.x = 40
			_apply_tooltip(cp, property)
			cp.color_changed.connect(func(v): changed_callback.call(name, v))
			return cp
			
		TYPE_NODE_PATH:
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)
			
			var le = LineEdit.new()
			le.text = str(value)
			le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			le.editable = true # Allow manual entry too
			le.text_submitted.connect(func(v): changed_callback.call(name, NodePath(v)))
			le.focus_exited.connect(func(): changed_callback.call(name, NodePath(le.text)))
			hbox.add_child(le)
			
			var btn = Button.new()
			# btn.icon = EditorInterface.get_base_control().get_theme_icon("Node", "EditorIcons") # Context safe
			btn.text = "..."
			btn.tooltip_text = "Pick Node"
			btn.pressed.connect(func():
				# We need a reference to the scene root to pick nodes relative to it
				var root = EditorInterface.get_edited_scene_root()
				if not root:
					print("FlowHFSM: No edited scene root found.")
					return
					
				# Create and configure the dialog
				# Note: EditorInterface.popup_node_selector is deprecated/removed in 4.x
				# We must use EditorInterface.get_selection() or custom logic, 
				# OR instantiate a SceneTreeDialog which is not exposed to GDScript easily.
				#
				# WORKAROUND: We use a simple ConfirmationDialog with a Tree, 
				# OR we rely on the manual text entry for now, 
				# BUT the user specifically asked for the popup.
				#
				# Better approach for plugins: EditorPropertyNodePath
				# Since we are inside a custom control, we can't easily embed the native editor property.
				#
				# Let's use a standard hack: EditorInterface.get_base_control().add_child(...)
				pass # Logic to be implemented in helper
				_open_node_selector(root, func(path):
					le.text = str(path)
					changed_callback.call(name, path)
				)
			)
			hbox.add_child(btn)
			return hbox
			
		TYPE_VECTOR2:
			# Custom Vector2 editor (compact)
			var hbox: HBoxContainer = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)
			_apply_tooltip(hbox, property)
			
			var create_field = func(val, label_text, color):
				var container: HBoxContainer = HBoxContainer.new()
				container.add_theme_constant_override("separation", 2)
				
				var l: Label = Label.new()
				l.text = label_text
				l.modulate = color
				l.add_theme_font_size_override("font_size", 10)
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				container.add_child(l)
				
				var s: SpinBox = SpinBox.new()
				s.min_value = -99999.0
				s.max_value = 99999.0
				s.step = 0.001
				s.value = val
				s.allow_greater = true
				s.allow_lesser = true
				s.custom_minimum_size.x = 60
				s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				container.add_child(s)
				return [container, s]
			
			var x_pack = create_field.call(value.x, "x", Color(0.8, 0.4, 0.4))
			var y_pack = create_field.call(value.y, "y", Color(0.4, 0.8, 0.4))
			
			var x_spin = x_pack[1]
			var y_spin = y_pack[1]
			
			var update_vec = func(_v):
				changed_callback.call(name, Vector2(x_spin.value, y_spin.value))
			
			x_spin.value_changed.connect(update_vec)
			y_spin.value_changed.connect(update_vec)
			
			hbox.add_child(x_pack[0])
			hbox.add_child(y_pack[0])
			return hbox

		TYPE_OBJECT:
			if value is Resource:
				# Check for Smart Value signature (duck typing)
				if "mode" in value and "blackboard_key" in value and "node_path" in value:
					return _create_smart_value_editor(value, func(p_name, p_val):
						value.set(p_name, p_val)
						# Value* resources emit notify_property_list_changed() on mode set, 
						# which triggers inspector refresh.
					, depth)
				
				# Check for AnimationDriver signature (duck typing)
				if "parameter_path" in value and "type" in value and "value_float" in value:
					return _create_animation_driver_editor(value, func(p_name, p_val):
						value.set(p_name, p_val)
					, depth)
				
				# Recursive Resource Editor (Inline)
				var panel = PanelContainer.new()
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
				style.border_width_left = 2
				style.border_color = Color(1, 1, 1, 0.1)
				style.content_margin_left = 8
				style.content_margin_right = 4
				style.content_margin_top = 4
				style.content_margin_bottom = 4
				panel.add_theme_stylebox_override("panel", style)
				
				# Callback wrapper
				var sub_callback = func(prop_name, prop_val):
					value.set(prop_name, prop_val)
					
				# Build the list
				var sub_list = create_property_list(value, sub_callback, depth + 1)
				panel.add_child(sub_list)
				return panel
			else:
				# Fallback for null or non-resources
				var lbl_null = Label.new()
				lbl_null.text = "<null>" if value == null else str(value)
				lbl_null.modulate = Color(0.5, 0.5, 0.5)
				return lbl_null

	# Fallback for unhandled types
	var lbl: Label = Label.new()
	lbl.text = str(value)
	lbl.modulate = Color(0.6, 0.6, 0.6)
	return lbl

static func _create_smart_value_editor(res: Resource, callback: Callable, depth: int = 0) -> Control:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	# 1. Mode Selector (Compact)
	var mode_opt = OptionButton.new()
	mode_opt.add_item("Const", 0) # CONSTANT
	mode_opt.add_item("BB", 1)    # BLACKBOARD
	mode_opt.add_item("Prop", 2)  # PROPERTY
	mode_opt.selected = res.mode
	mode_opt.custom_minimum_size.x = 60
	mode_opt.item_selected.connect(func(idx):
		callback.call("mode", idx)
		# The inspector will rebuild because the resource emits changed signal
	)
	container.add_child(mode_opt)
	
	# 2. Contextual Value Editor
	var mode = res.mode
	var target_prop = ""
	
	if mode == 0: # CONSTANT
		target_prop = "value"
	elif mode == 1: # BLACKBOARD
		target_prop = "blackboard_key"
	elif mode == 2: # PROPERTY
		target_prop = "property_name" # Only showing Property Name inline for compactness, Path is complex
		
	# Find property info for the target
	var target_info = null
	for p in res.get_property_list():
		if p.name == target_prop:
			target_info = p
			break
			
	if target_info:
		# For Property Mode, we want [NodePath] [PropName]
		if mode == 2:
			# Node Path
			var np_info = null
			for p in res.get_property_list():
				if p.name == "node_path": np_info = p; break
			
			if np_info:
				var np_editor = create_control_for_property(res, np_info, callback, depth + 1)
				if np_editor:
					np_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					np_editor.size_flags_stretch_ratio = 0.4
					container.add_child(np_editor)

		var editor = create_control_for_property(res, target_info, callback, depth + 1)
		if editor:
			editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			editor.size_flags_stretch_ratio = 1.0
			container.add_child(editor)
	
	return container

static func _create_animation_driver_editor(res: Resource, callback: Callable, depth: int = 0) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	
	# Create a styled card background
	var panel = PanelContainer.new()
	var style = create_card_style(Color(0.12, 0.14, 0.18, 0.5))
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 6)
	panel.add_child(inner_vbox)
	
	# --- Row 1: Config (Path + Type) ---
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	
	# Parameter Path
	var path_info = null
	for p in res.get_property_list():
		if p.name == "parameter_path": path_info = p; break
	
	if path_info:
		var lbl = Label.new()
		lbl.text = "Anim Param"
		lbl.modulate = Color(0.7, 0.7, 0.7)
		lbl.add_theme_font_size_override("font_size", 10)
		row1.add_child(lbl)
		
		var path_editor = create_control_for_property(res, path_info, callback, depth + 1)
		path_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row1.add_child(path_editor)
	
	# Type Selector
	var type_info = null
	for p in res.get_property_list():
		if p.name == "type": type_info = p; break
		
	if type_info:
		var type_editor = create_control_for_property(res, type_info, callback, depth + 1)
		type_editor.custom_minimum_size.x = 80
		row1.add_child(type_editor)
		
	inner_vbox.add_child(row1)
	
	# --- Row 2: Value Editor ---
	# We determine which property to show based on the 'type' value
	var target_prop = ""
	var current_type = res.type # Accessing property directly via duck typing
	
	match current_type:
		0: target_prop = "value_float"   # ValueType.FLOAT
		1: target_prop = "value_vector2" # ValueType.VECTOR2
		2: target_prop = "value_bool"    # ValueType.BOOL
	
	var val_info = null
	for p in res.get_property_list():
		if p.name == target_prop: val_info = p; break
	
	if val_info:
		var val_editor = create_control_for_property(res, val_info, callback, depth + 1)
		inner_vbox.add_child(val_editor)
	
	container.add_child(panel)
	return container

static func _open_node_selector(root_node: Node, callback: Callable) -> void:
	var dialog = EditorNodeSelector.new()
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio(0.4)
	dialog.node_selected.connect(func(node_path):
		callback.call(node_path)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	dialog.show_window(root_node)

class EditorNodeSelector extends Window:
	# A custom mini-window to replicate SceneTreeDialog since the native one isn't exposed
	signal node_selected(path: NodePath)
	signal canceled
	
	var tree: Tree
	var root: Node
	var _ok_btn: Button
	
	func show_window(p_root: Node):
		root = p_root
		title = "Select a Node"
		transient = true
		exclusive = true
		wrap_controls = true
		
		var panel = PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(panel)
		
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		# Filter
		var filter = LineEdit.new()
		filter.placeholder_text = "Filter nodes..."
		filter.text_changed.connect(_on_filter_changed)
		vbox.add_child(filter)
		
		# Tree
		tree = Tree.new()
		tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tree.hide_root = false
		tree.item_activated.connect(_on_confirmed)
		vbox.add_child(tree)
		
		# Buttons
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_END
		
		var btn_cancel = Button.new()
		btn_cancel.text = "Cancel"
		btn_cancel.pressed.connect(func(): canceled.emit())
		hbox.add_child(btn_cancel)
		
		_ok_btn = Button.new()
		_ok_btn.text = "OK"
		_ok_btn.pressed.connect(_on_confirmed)
		hbox.add_child(_ok_btn)
		
		vbox.add_child(hbox)
		
		_build_tree()
		popup_centered(Vector2(400, 600))
		
	func _build_tree():
		tree.clear()
		if not root: return
		
		var tree_root = tree.create_item()
		_process_node(root, tree_root)
		
	func _process_node(node: Node, parent_item: TreeItem):
		parent_item.set_text(0, node.name)
		# We store the relative path from the root as metadata
		# But wait, NodePath should be relative to the object using it (Behavior or State)
		# For simplicity in this generic picker, we return path relative to Scene Root
		# The user might need to adjust ".." manually if the Context is deep in the tree.
		#
		# Ideally: The 'property_factory' knows the 'object' (Resource).
		# But Resources don't have a place in the tree. The NODE using the resource does.
		# We don't easily know which Node owns this Resource at this level.
		# So returning path from Scene Root is the standard "safe" guess, 
		# though often absolute paths (/root/Scene/...) or relative from root are used.
		
		# Let's use the path relative to the Edited Scene Root.
		var path = root.get_path_to(node)
		parent_item.set_metadata(0, path)
		
		# Icon
		var icon = EditorInterface.get_base_control().get_theme_icon("Node", "EditorIcons")
		if node.get_class() != "Node":
			if EditorInterface.get_base_control().has_theme_icon(node.get_class(), "EditorIcons"):
				icon = EditorInterface.get_base_control().get_theme_icon(node.get_class(), "EditorIcons")
		parent_item.set_icon(0, icon)
		
		for child in node.get_children():
			if child.owner != root and child != root: continue # Only show owned nodes (scene context)
			var child_item = tree.create_item(parent_item)
			_process_node(child, child_item)

	func _on_filter_changed(txt: String):
		# TODO: Implement filtering
		pass
		
	func _on_confirmed():
		var item = tree.get_selected()
		if item:
			node_selected.emit(item.get_metadata(0))
		else:
			canceled.emit()

static func _create_variant_editor(object: Object, name: String, value: Variant, changed_callback: Callable, depth: int = 0) -> Control:
	# A simplified Variant editor: [Type Selector] [Value Editor]
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	# Type Selector
	var type_opt = OptionButton.new()
	type_opt.add_item("Null", TYPE_NIL)
	type_opt.add_item("Bool", TYPE_BOOL)
	type_opt.add_item("Int", TYPE_INT)
	type_opt.add_item("Float", TYPE_FLOAT)
	type_opt.add_item("String", TYPE_STRING)
	type_opt.add_item("Vector2", TYPE_VECTOR2)
	type_opt.add_item("Vector3", TYPE_VECTOR3)
	type_opt.add_item("Color", TYPE_COLOR)
	
	# Select current type
	var current_type = typeof(value)
	for i in range(type_opt.item_count):
		if type_opt.get_item_id(i) == current_type:
			type_opt.select(i)
			break
			
	type_opt.item_selected.connect(func(idx):
		var new_type = type_opt.get_item_id(idx)
		if new_type == current_type: return
		
		# Create default value for new type
		var new_val
		match new_type:
			TYPE_NIL: new_val = null
			TYPE_BOOL: new_val = false
			TYPE_INT: new_val = 0
			TYPE_FLOAT: new_val = 0.0
			TYPE_STRING: new_val = ""
			TYPE_VECTOR2: new_val = Vector2.ZERO
			TYPE_VECTOR3: new_val = Vector3.ZERO
			TYPE_COLOR: new_val = Color.WHITE
			_: new_val = null # Unsupported fallback
			
		changed_callback.call(name, new_val)
	)
	
	container.add_child(type_opt)
	
	# Value Editor (Recursive call but with explicit type)
	# We mock a property dict to reuse logic
	var sub_prop = {
		"name": name,
		"type": current_type,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage": PROPERTY_USAGE_DEFAULT
	}
	
	# Only create editor if not null
	if current_type != TYPE_NIL:
		var editor = create_control_for_property(object, sub_prop, changed_callback, depth + 1)
		if editor:
			editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.add_child(editor)
			
	return container

static func create_property_list(resource: Resource, changed_callback: Callable, depth: int = 0) -> Control:
	var container: VBoxContainer = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	
	for prop: Dictionary in resource.get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR:
			var p_name: String = prop.name
			if p_name in ["script", "resource_name", "resource_path", "resource_local_to_scene"]:
				continue
				
			var row: HBoxContainer = HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var p_label: Label = Label.new()
			p_label.text = p_name.capitalize()
			p_label.tooltip_text = p_name
			p_label.modulate = Color(0.85, 0.85, 0.85)
			p_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p_label.size_flags_stretch_ratio = 0.4
			# Use proper theme font if available, else default
			# p_label.add_theme_font_size_override("font_size", 14) 
			row.add_child(p_label)
			
			var editor: Control = create_control_for_property(resource, prop, func(name, val):
				changed_callback.call(name, val)
			, depth)
			if editor:
				editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				editor.size_flags_stretch_ratio = 0.6
				row.add_child(editor)
			
			container.add_child(row)
			
	return container
