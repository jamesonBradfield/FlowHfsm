@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/FlowHFSM/editor/hfsm_inspector.gd")

var inspector_plugin: EditorInspectorPlugin
var workbench_instance: Control

func _enter_tree() -> void:
	inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)
	
	# NUCLEAR CACHE BUST: Force Godot to ignore the cached .tscn
	var scene = ResourceLoader.load("res://addons/FlowHFSM/editor/HFSMWorkbench.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	
	if scene:
		workbench_instance = scene.instantiate()
		add_control_to_bottom_panel(workbench_instance, "FlowHFSM")

func _exit_tree() -> void:
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
	
	if workbench_instance:
		remove_control_from_bottom_panel(workbench_instance)
		workbench_instance.free()
