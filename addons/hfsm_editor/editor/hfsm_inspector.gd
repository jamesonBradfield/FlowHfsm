extends EditorInspectorPlugin

# We only want to handle the RecursiveState node
func _can_handle(object):
	return object is RecursiveState

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	# We want to intercept the "transitions" array and display it better
	if name == "transitions":
		add_property_editor(name, preload("res://addons/hfsm_editor/editor/transition_editor.gd").new())
		return true # We handled it
		
	# Intercept behavior to inline it
	if name == "behavior":
		add_property_editor(name, preload("res://addons/hfsm_editor/editor/behavior_editor.gd").new())
		return true
		
	return false
