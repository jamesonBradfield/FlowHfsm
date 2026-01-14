@tool
extends EditorPlugin

const InspectorPlugin = preload("res://addons/FlowHFSM/editor/hfsm_inspector.gd")
# const CharacterDock = preload("res://addons/FlowHFSM/editor/character_creation_dock.gd")

var inspector_plugin: EditorInspectorPlugin
# var dock_instance: Control

func _enter_tree() -> void:
	inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)
	
	# dock_instance = CharacterDock.new()
	# add_control_to_dock(DOCK_SLOT_LEFT_UL, dock_instance)

func _exit_tree() -> void:
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
	
	# if dock_instance:
	# 	remove_control_from_docks(dock_instance)
	# 	dock_instance.free()
