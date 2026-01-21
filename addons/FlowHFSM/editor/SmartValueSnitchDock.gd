@tool
extends Control

# Explicitly preload ValueNode to avoid class_name resolution issues
const ValueNode = preload("res://addons/FlowHFSM/runtime/values/ValueNode.gd")

var tree: Tree
var timer: float = 0.0
const REFRESH_RATE = 0.2

func _ready() -> void:
	# Build UI
	var layout = VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	
	var label = Label.new()
	label.text = "Value Snitch Monitor"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(label)
	
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.columns = 2
	tree.set_column_title(0, "Property")
	tree.set_column_title(1, "Value")
	tree.set_column_titles_visible(true)
	tree.hide_root = true
	layout.add_child(tree)

func _process(delta: float) -> void:
	timer += delta
	if timer < REFRESH_RATE: return
	timer = 0.0
	
	_update_snitch()

func _update_snitch() -> void:
	tree.clear()
	var root = tree.create_item()
	
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		return
		
	var node = selection[0]
	if not node: return
	
	# Recursively scan for ValueFloat/ValueNode
	_scan_object(node, root, node.name)

func _scan_object(obj: Object, parent_item: TreeItem, label: String) -> void:
	if not obj: return
	
	# Determine if we should expand this object
	var is_relevant = false
	if obj is RecursiveState: is_relevant = true
	if obj is StateBehavior: is_relevant = true
	if obj is StateCondition: is_relevant = true
	if obj is ValueFloat: is_relevant = true
	if obj is ValueNode: is_relevant = true
	
	# 1. Check Properties
	var properties = obj.get_property_list()
	for prop in properties:
		var name = prop.name
		var type = prop.type
		var usage = prop.usage
		
		# Skip hidden/editor properties
		if not (usage & PROPERTY_USAGE_STORAGE): continue
		
		var val = obj.get(name)
		
		if val is Object:
			if val is ValueFloat:
				_evaluate_value_float(val, parent_item, label + "." + name)
			elif val is ValueNode:
				_evaluate_value_node(val, parent_item, label + "." + name)
			elif val is Resource:
				# Dive into arrays of resources (Behaviors/Conditions)
				pass 
			elif val is Array:
				pass # TODO: Handle Array[Resource]
				
		# Arrays handling
		if type == TYPE_ARRAY and val is Array:
			for i in range(val.size()):
				var item = val[i]
				if item is Object:
					_scan_object(item, parent_item, label + "." + name + "[%d]" % i)


func _evaluate_value_float(vf: ValueFloat, parent_item: TreeItem, name: String) -> void:
	var item = tree.create_item(parent_item)
	item.set_text(0, name)
	
	# Simulation Context
	var actor = _get_simulation_actor()
	var blackboard = null # TODO: Mock blackboard?
	
	var result = vf.get_value(actor, blackboard)
	item.set_text(1, str(result))
	
	# Color code based on mode
	if vf.mode == ValueFloat.Mode.CONSTANT:
		item.set_custom_color(1, Color.LIGHT_GRAY)
	else:
		item.set_custom_color(1, Color.GREEN_YELLOW)

func _evaluate_value_node(vn: ValueNode, parent_item: TreeItem, name: String) -> void:
	var item = tree.create_item(parent_item)
	item.set_text(0, name)
	
	var actor = _get_simulation_actor()
	var blackboard = null
	
	var result = vn.get_node(actor, blackboard)
	if result:
		item.set_text(1, str(result.name) + " (" + str(result) + ")")
		item.set_custom_color(1, Color.GREEN)
	else:
		item.set_text(1, "null")
		item.set_custom_color(1, Color.RED)

func _get_simulation_actor() -> Node:
	# Use Editor Camera as actor
	if EditorInterface.get_editor_viewport_3d():
		return EditorInterface.get_editor_viewport_3d().get_camera_3d()
	return null
