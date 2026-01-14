extends EditorInspectorPlugin

# const AssetCreationDialog = preload("res://addons/FlowHFSM/editor/asset_creation_dialog.gd")
# var wizard_dialog: ConfirmationDialog

func _can_handle(object: Object) -> bool:
	return object is RecursiveState

func _parse_begin(object: Object) -> void:
	if not object is RecursiveState: return
	
	# WORKBENCH MIGRATION: 
	# The "Add Child State" button is removed.
	# Users should use the HFSM Workbench (Bottom Panel) or the Scene Tree.
	
	# Optional: Add a label hinting at the workbench?
	var lbl = Label.new()
	lbl.text = "Tip: Use HFSM Workbench to add states."
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_custom_control(lbl)

func _parse_property(object: Object, _type: int, name: String, _hint_type: int, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	# Intercept behaviors to inline it
	if name == "behaviors":
		add_property_editor(name, preload("res://addons/FlowHFSM/editor/behavior_editor.gd").new())
		return true

	# Intercept activation_conditions to inline them
	if name == "activation_conditions":
		add_property_editor(name, preload("res://addons/FlowHFSM/editor/condition_editor.gd").new())
		return true

	# Intercept declared_variables to inline them
	if name == "declared_variables":
		add_property_editor(name, preload("res://addons/FlowHFSM/editor/variable_editor.gd").new())
		return true

	return false
