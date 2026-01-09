@tool
extends EditorProperty

const Factory = preload("res://addons/FlowHFSM/editor/property_factory.gd")
const ThemeResource = preload("res://addons/FlowHFSM/editor/hfsm_editor_theme.tres")
	
var container: VBoxContainer = VBoxContainer.new()
var current_behavior: Resource
var updating_from_ui: bool = false
	
func _init() -> void:
	label = ""
	container.theme = ThemeResource
	add_child(container)

func _update_property() -> void:
	if updating_from_ui: return
	
	# Clear existing children
	for child in container.get_children():
		child.queue_free()
	
	var behavior: Resource = get_edited_object()[get_edited_property()]
	
	if current_behavior != behavior:
		if current_behavior and current_behavior.changed.is_connected(_on_behavior_changed):
			current_behavior.changed.disconnect(_on_behavior_changed)
		current_behavior = behavior
		if current_behavior:
			if not current_behavior.changed.is_connected(_on_behavior_changed):
				current_behavior.changed.connect(_on_behavior_changed)
	
	# Resource Picker for the main behavior slot
	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = "StateBehavior"
	picker.edited_resource = behavior
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(func(res):
		var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
		var object: Object = get_edited_object()
		var property: StringName = get_edited_property()
		var old_res: Variant = object.get(property)
		
		ur.create_action("Change Behavior Resource")
		ur.add_do_property(object, property, res)
		ur.add_undo_property(object, property, old_res)
		
		if object.has_method("notify_property_list_changed"):
			ur.add_do_method(object, "notify_property_list_changed")
			ur.add_undo_method(object, "notify_property_list_changed")
			
		ur.commit_action()
	)
	container.add_child(picker)
	
	# If we have a behavior, show its properties inline directly
	if behavior:
		var props_box: VBoxContainer = VBoxContainer.new()
		
		# Indent slightly
		var margin_container: MarginContainer = MarginContainer.new()
		
		var props_list: Control = Factory.create_property_list(behavior, func(prop_name, new_val):
			updating_from_ui = true
			var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
			var old_val: Variant = behavior.get(prop_name)
			
			ur.create_action("Change Behavior Property: " + prop_name)
			ur.add_do_method(behavior, "set", prop_name, new_val)
			ur.add_undo_method(behavior, "set", prop_name, old_val)
			
			if behavior.has_method("emit_changed"):
				ur.add_do_method(behavior, "emit_changed")
				ur.add_undo_method(behavior, "emit_changed")
				
			ur.commit_action()
			updating_from_ui = false
		)
		margin_container.add_child(props_list)
		
		props_box.add_child(margin_container)
		container.add_child(props_box)

func _on_behavior_changed() -> void:
	_update_property()

func _find_owner_node(resource: Resource) -> Node:
	# This is a bit of a hack to guess where an embedded resource comes from.
	# We search the current scene to see if any other node references this EXACT resource instance.
	var root: Node = get_tree().edited_scene_root
	if not root: return null
	
	var owners: Array = []
	_search_resource_usage(root, resource, owners)
	
	if owners.size() > 0:
		return owners[0] # Return the first one found
	return null

func _search_resource_usage(node: Node, target_res: Resource, result: Array) -> void:
	# Check script properties
	var props: Array[Dictionary] = node.get_property_list()
	for p: Dictionary in props:
		if p.type == TYPE_OBJECT and (p.usage & PROPERTY_USAGE_STORAGE):
			var val: Variant = node.get(p.name)
			if val == target_res:
				result.append(node)
				return
				
	# Recurse
	for child: Node in node.get_children():
		_search_resource_usage(child, target_res, result)
