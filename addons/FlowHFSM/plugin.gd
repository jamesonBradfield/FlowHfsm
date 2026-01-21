@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/FlowHFSM/src/editor/inspector/hfsm_inspector.gd")
# NO SCENE PRELOAD. We load the script raw.

var inspector_plugin: EditorInspectorPlugin
var workbench_instance: Control

func _enter_tree() -> void:
	# 1. Inspector
	inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)
	
	# 2. Workbench (DIRECT SCRIPT LOAD)
	# This bypasses the .tscn cache entirely.
	var workbench_script = ResourceLoader.load("res://addons/FlowHFSM/src/editor/workbench/hfsm_workbench.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	if workbench_script:
		workbench_instance = workbench_script.new()
		# Add to bottom panel
		add_control_to_bottom_panel(workbench_instance, "FlowHFSM")

func _exit_tree() -> void:
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
	
	if workbench_instance:
		remove_control_from_bottom_panel(workbench_instance)
		workbench_instance.free()
