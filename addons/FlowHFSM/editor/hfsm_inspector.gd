extends EditorInspectorPlugin

const AssetCreationDialog = preload("res://addons/FlowHFSM/editor/asset_creation_dialog.gd")
var wizard_dialog: ConfirmationDialog

func _can_handle(object: Object) -> bool:
	return object is RecursiveState

func _parse_begin(object: Object) -> void:
	if not object is RecursiveState: return
	
	# Create Wizard if needed
	if not wizard_dialog:
		wizard_dialog = AssetCreationDialog.new()
		# We need to add it to the editor scene, but EditorInspectorPlugin doesn't have add_child
		# So we add it to the first control created or find a way to host it.
		# Actually, we can add it as a child of a control we inject.
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn = Button.new()
	btn.text = "Add Child State"
	btn.icon = btn.get_theme_icon("New", "EditorIcons")
	btn.pressed.connect(func(): 
		if not wizard_dialog.is_inside_tree():
			EditorInterface.get_base_control().add_child(wizard_dialog)
		wizard_dialog.configure_node_creation(object)
		wizard_dialog.popup_centered()
	)
	hbox.add_child(btn)
	
	add_custom_control(hbox)

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
