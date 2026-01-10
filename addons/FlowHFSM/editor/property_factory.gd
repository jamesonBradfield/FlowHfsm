@tool
class_name HFSMPropertyFactory
extends RefCounted

static func create_panel_style(border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 0.6)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left = 4
	style.border_color = border_color
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func create_resource_toolbar(resource: Resource, parent_control: Control, callback: Callable) -> Control:
	var container: HBoxContainer = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	var is_shared: bool = not resource.resource_path.is_empty() and not resource.resource_path.contains("::")
	
	var label: Label = Label.new()
	label.text = "SHARED" if is_shared else "LOCAL"
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2) if is_shared else Color(0.6, 0.8, 1.0))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	if is_shared:
		var btn_unique: Button = Button.new()
		btn_unique.tooltip_text = "Make Unique (Duplicate)"
		btn_unique.icon = parent_control.get_theme_icon("Duplicate", "EditorIcons")
		btn_unique.flat = true
		btn_unique.pressed.connect(func():
			var new_res: Resource = resource.duplicate()
			callback.call(new_res)
		)
		container.add_child(btn_unique)
	else:
		var btn_save: Button = Button.new()
		btn_save.tooltip_text = "Save to File"
		btn_save.icon = parent_control.get_theme_icon("Save", "EditorIcons")
		btn_save.flat = true
		btn_save.pressed.connect(func():
			var file_dialog: EditorFileDialog = EditorFileDialog.new()
			parent_control.add_child(file_dialog)
			file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
			file_dialog.clear_filters()
			file_dialog.add_filter("*.tres", "Resource")
			
			file_dialog.file_selected.connect(func(path):
				ResourceSaver.save(resource, path)
				resource.take_over_path(path)
				callback.call(resource)
				file_dialog.queue_free()
			, CONNECT_ONE_SHOT)
			
			file_dialog.canceled.connect(func(): file_dialog.queue_free(), CONNECT_ONE_SHOT)
			
			file_dialog.popup_centered_ratio(0.5)
		)
		container.add_child(btn_save)
		
	return container

static func _apply_tooltip(control: Control, property: Dictionary) -> void:
	if property.get("hint_string", "") != "":
		control.tooltip_text = property.hint_string
	else:
		control.tooltip_text = property.name.capitalize()

static func create_control_for_property(object: Object, property: Dictionary, changed_callback: Callable) -> Control:
	var type: int = property.type
	var name: String = property.name
	var value: Variant = object.get(name)
	
	match type:
		TYPE_BOOL:
			var cb: CheckBox = CheckBox.new()
			cb.button_pressed = value
			cb.tooltip_text = property.name.capitalize()
			_apply_tooltip(cb, property)
			cb.toggled.connect(func(v): changed_callback.call(name, v))
			return cb
			
		TYPE_INT:
			if property.hint == PROPERTY_HINT_ENUM:
				var opt: OptionButton = OptionButton.new()
				var items: PackedStringArray = property.hint_string.split(",")
				for i in range(items.size()):
					var item_split: PackedStringArray = items[i].split(":")
					var item_name: String = item_split[0]
					var item_val: int = i
					if item_split.size() > 1:
						item_val = int(item_split[1])
					
					opt.add_item(item_name, item_val)
					if item_val == value:
						opt.select(opt.item_count - 1)
				
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
				sb.value = float(value)
				sb.step = 1
				sb.allow_greater = true
				sb.allow_lesser = true
				_apply_tooltip(sb, property)
				sb.value_changed.connect(func(v): changed_callback.call(name, int(v)))
				return sb
				
		TYPE_FLOAT:
			var sb: SpinBox = SpinBox.new()
			sb.min_value = -99999.0
			sb.max_value = 99999.0
			sb.step = 0.001
			sb.value = value
			sb.allow_greater = true
			sb.allow_lesser = true
			sb.custom_minimum_size.x = 80
			sb.tooltip_text = property.name.capitalize()
			_apply_tooltip(sb, property)
			sb.value_changed.connect(func(v): changed_callback.call(name, v))
			return sb
			
		TYPE_STRING:
			var le: LineEdit = LineEdit.new()
			if value == null:
				le.text = ""
			else:
				le.text = str(value)
			le.expand_to_text_length = true
			le.custom_minimum_size.x = 110
			le.tooltip_text = property.name.capitalize()
			_apply_tooltip(le, property)
			le.text_changed.connect(func(v): changed_callback.call(name, v))
			return le
			
		TYPE_VECTOR2:
			var hbox: HBoxContainer = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)
			_apply_tooltip(hbox, property)
			
			var create_field: Callable = func(val, label_text, color):
				var container: HBoxContainer = HBoxContainer.new()
				container.add_theme_constant_override("separation", 0)
				
				var l: Label = Label.new()
				l.text = label_text
				l.modulate = color
				l.add_theme_font_size_override("font_size", 10)
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				# Add a small margin or style if possible, but basic Label works for simple "x"
				l.custom_minimum_size.x = 12
				container.add_child(l)
				
				var s: SpinBox = SpinBox.new()
				s.min_value = -99999.0
				s.max_value = 99999.0
				s.step = 0.001
				s.value = val
				s.allow_greater = true
				s.allow_lesser = true
				s.custom_minimum_size.x = 60
				container.add_child(s)
				return [container, s]
			
			# Red for X (similar to Godot's convention), Green for Y
			var x_pack: Array = create_field.call(value.x, "X", Color(0.8, 0.2, 0.2))
			var y_pack: Array = create_field.call(value.y, "Y", Color(0.2, 0.8, 0.2))
			
			var x_spin: SpinBox = x_pack[1]
			var y_spin: SpinBox = y_pack[1]
			
			var update_vec: Callable = func(_v):
				changed_callback.call(name, Vector2(x_spin.value, y_spin.value))
			
			x_spin.value_changed.connect(update_vec)
			y_spin.value_changed.connect(update_vec)
			
			hbox.add_child(x_pack[0])
			hbox.add_child(y_pack[0])
			return hbox

	# Fallback for unhandled types (just show label)
	var lbl: Label = Label.new()
	lbl.text = str(value)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	return lbl

static func create_property_list(resource: Resource, changed_callback: Callable) -> Control:
	var container: VBoxContainer = VBoxContainer.new()
	
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
			p_label.modulate = Color(0.8, 0.8, 0.8)
			p_label.custom_minimum_size.x = 110
			p_label.add_theme_font_size_override("font_size", 12)
			row.add_child(p_label)
			
			var editor: Control = create_control_for_property(resource, prop, func(name, val):
				changed_callback.call(name, val)
			)
			if editor:
				editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(editor)
			else:
				# Fallback if creation failed (shouldn't happen with default catch-all)
				var err_lbl = Label.new()
				err_lbl.text = "Error"
				row.add_child(err_lbl)
			
			container.add_child(row)
			
	return container
