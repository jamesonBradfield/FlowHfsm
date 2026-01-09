@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/FlowHFSM/editor/hfsm_inspector.gd")
var inspector_plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin)
