@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/hfsm_editor/hfsm_inspector.gd")
var inspector_plugin

func _enter_tree():
	inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
