@tool
extends EditorPlugin

var dock_instance: Control

func _enter_tree() -> void:
	dock_instance = preload("res://addons/FlowHFSM/editor/SmartValueSnitchDock.gd").new()
	dock_instance.name = "HFSM Snitch"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, dock_instance)

func _exit_tree() -> void:
	remove_control_from_docks(dock_instance)
	dock_instance.free()
