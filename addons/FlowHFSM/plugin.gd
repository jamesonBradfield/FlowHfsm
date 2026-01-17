@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/FlowHFSM/editor/hfsm_inspector.gd")
# REMOVED: const WorkbenchScene = preload(...) 

var inspector_plugin: EditorInspectorPlugin
var workbench_instance: Control

func _enter_tree() -> void:
	inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)
	
	# DYNAMIC LOAD (Breaks the cache)
	var scene = load("res://addons/FlowHFSM/editor/HFSMWorkbench.tscn")
	if scene:
		workbench_instance = scene.instantiate()
		add_control_to_bottom_panel(workbench_instance, "FlowHFSM")

func _exit_tree() -> void:
	# ... (Keep existing cleanup code)
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)

	if workbench_instance:
		remove_control_from_bottom_panel(workbench_instance)
		workbench_instance.free()
