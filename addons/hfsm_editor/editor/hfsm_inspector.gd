extends EditorInspectorPlugin

# We only want to handle the RecursiveState node
func _can_handle(object: Object) -> bool:
	return object is RecursiveState

func _parse_property(object: Object, _type: int, name: String, _hint_type: int, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	# Intercept behavior to inline it
	if name == "behavior":
		add_property_editor(name, preload("res://addons/hfsm_editor/editor/behavior_editor.gd").new())
		return true

	# Intercept activation_conditions to inline them
	if name == "activation_conditions":
		add_property_editor(name, preload("res://addons/hfsm_editor/editor/condition_editor.gd").new())
		return true

		
	return false
