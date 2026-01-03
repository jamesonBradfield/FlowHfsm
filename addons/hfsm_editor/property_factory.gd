@tool
extends Node

static func create_control_for_property(object: Object, property: Dictionary, changed_callback: Callable) -> Control:
	var type = property.type
	var name = property.name
	var value = object.get(name)
	
	match type:
		TYPE_BOOL:
			var cb = CheckBox.new()
			cb.button_pressed = value
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
			sb.value_changed.connect(func(v): changed_callback.call(name, v))
			return sb
			
		TYPE_STRING:
			var le = LineEdit.new()
			le.text = value
			le.expand_to_text_length = true
			le.custom_minimum_size.x = 100
			le.text_changed.connect(func(v): changed_callback.call(name, v))
			return le
			
		TYPE_VECTOR2:
			var hbox = HBoxContainer.new()
			var x = SpinBox.new()
			x.min_value = -99999.0
			x.max_value = 99999.0
			x.step = 0.001
			x.value = value.x
			x.prefix = "x"
			x.allow_greater = true
			x.allow_lesser = true
			x.custom_minimum_size.x = 70
			
			var y = SpinBox.new()
			y.min_value = -99999.0
			y.max_value = 99999.0
			y.step = 0.001
			y.value = value.y
			y.prefix = "y"
			y.allow_greater = true
			y.allow_lesser = true
			y.custom_minimum_size.x = 70
			
			var update_vec = func(_v):
				changed_callback.call(name, Vector2(x.value, y.value))
			
			x.value_changed.connect(update_vec)
			y.value_changed.connect(update_vec)
			hbox.add_child(x)
			hbox.add_child(y)
			return hbox

	# Fallback for unhandled types (just show label)
	var lbl = Label.new()
	lbl.text = str(value)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	return lbl
