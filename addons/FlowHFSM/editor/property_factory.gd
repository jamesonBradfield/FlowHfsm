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

static func create_control_for_property(object: Object, property: Dictionary, changed_callback: Callable) -> Control:
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
			return _create_variant_editor(object, name, value, changed_callback)

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

	# Fallback
	var lbl: Label = Label.new()
	lbl.text = str(value)
	lbl.modulate = Color(0.6, 0.6, 0.6)
	return lbl

static func _create_variant_editor(object: Object, name: String, value: Variant, changed_callback: Callable) -> Control:
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
		var editor = create_control_for_property(object, sub_prop, changed_callback)
		if editor:
			editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.add_child(editor)
			
	return container

static func create_property_list(resource: Resource, changed_callback: Callable) -> Control:
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
			)
			if editor:
				editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				editor.size_flags_stretch_ratio = 0.6
				row.add_child(editor)
			
			container.add_child(row)
			
	return container
