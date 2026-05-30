@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Core
	add_custom_type("FlowHost", "Node", preload("res://addons/FlowHFSM/src/core/FlowHost.gd"), null)
	add_custom_type("FlowState", "Node", preload("res://addons/FlowHFSM/src/core/FlowState.gd"), null)

	# Logic
	add_custom_type("FlowBehavior", "Resource", preload("res://addons/FlowHFSM/src/core/FlowBehavior.gd"), null)
	add_custom_type("FlowCondition", "Resource", preload("res://addons/FlowHFSM/src/core/FlowCondition.gd"), null)

func _exit_tree() -> void:
	remove_custom_type("FlowHost")
	remove_custom_type("FlowState")
	remove_custom_type("FlowBehavior")
	remove_custom_type("FlowCondition")
