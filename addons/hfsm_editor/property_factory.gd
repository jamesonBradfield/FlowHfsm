@tool
extends Node

static func _apply_tooltip(control: Control, property: Dictionary):
	if property.get("hint_string", "") != "":
		control.tooltip_text = property.hint_string
	else:
		control.tooltip_text = property.name.capitalize()

static func create_control_for_property(object: Object, property: Dictionary, changed_callback: Callable) -> Control:
	var type = property.type
	var name = property.name
	var value = object.get(name)
	
	match type:
		TYPE_BOOL:
			var cb = CheckBox.new()
			cb.button_pressed = value
			_apply_tooltip(cb, property)
			cb.toggled.connect(func(v): changed_callback.call(name, v))
			return cb
			
		TYPE_INT:
			if property.hint == PROPERTY_HINT_ENUM:
				var opt = OptionButton.new()
				var items = property.hint_string.split(",")
				for i in range(items.size()):
					var item_split = items[i].split(":")
					var item_name = item_split[0]
					var item_val = i
					if item_split.size() > 1:
						item_val = int(item_split[1])
					
					opt.add_item(item_name, item_val)
					if item_val == value:
						opt.select(opt.item_count - 1)
				
				_apply_tooltip(opt, property)
				opt.item_selected.connect(func(idx): 
					var id = opt.get_item_id(idx)
					changed_callback.call(name, id)
				)
				return opt
			else:
				var sb = SpinBox.new()
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
			var sb = SpinBox.new()
			sb.min_value = -99999.0
			sb.max_value = 99999.0
			sb.step = 0.001
			sb.value = value
			sb.allow_greater = true
			sb.allow_lesser = true
			sb.custom_minimum_size.x = 80
			_apply_tooltip(sb, property)
			sb.value_changed.connect(func(v): changed_callback.call(name, v))
			return sb
			
		TYPE_STRING:
			var le = LineEdit.new()
			le.text = value
			le.expand_to_text_length = true
			le.custom_minimum_size.x = 100
			_apply_tooltip(le, property)
			le.text_changed.connect(func(v): changed_callback.call(name, v))
			return le
			
		TYPE_VECTOR2:
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)
			_apply_tooltip(hbox, property)
			
			var create_field = func(val, label_text, color):
				var container = HBoxContainer.new()
				container.add_theme_constant_override("separation", 0)
				
				var l = Label.new()
				l.text = label_text
				l.modulate = color
				l.add_theme_font_size_override("font_size", 10)
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				# Add a small margin or style if possible, but basic Label works for simple "x"
				l.custom_minimum_size.x = 12
				container.add_child(l)
				
				var s = SpinBox.new()
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
			var x_pack = create_field.call(value.x, "X", Color(0.8, 0.2, 0.2))
			var y_pack = create_field.call(value.y, "Y", Color(0.2, 0.8, 0.2))
			
			var x_spin = x_pack[1]
			var y_spin = y_pack[1]
			
			var update_vec = func(_v):
				changed_callback.call(name, Vector2(x_spin.value, y_spin.value))
			
			x_spin.value_changed.connect(update_vec)
			y_spin.value_changed.connect(update_vec)
			
			hbox.add_child(x_pack[0])
			hbox.add_child(y_pack[0])
			return hbox

	# Fallback for unhandled types (just show label)
	var lbl = Label.new()
	lbl.text = str(value)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	return lbl
