@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Core
	add_custom_type("FlowCharacter", "CharacterBody3D", preload("res://addons/FlowHFSM/src/core/FlowCharacter.gd"), null)
	add_custom_type("FlowState", "Node", preload("res://addons/FlowHFSM/src/core/FlowState.gd"), null)
	
	# Logic
	add_custom_type("FlowBehavior", "Resource", preload("res://addons/FlowHFSM/src/core/FlowBehavior.gd"), null)
	add_custom_type("FlowCondition", "Resource", preload("res://addons/FlowHFSM/src/core/FlowCondition.gd"), null)

	# Library (Optional, usually we just let users instance scripts)
	# You can add specific behaviors here if you want them in the "Create Node" dialog, 
	# but usually Resources are created via the Inspector.

func _exit_tree() -> void:
	remove_custom_type("FlowCharacter")
	remove_custom_type("FlowState")
	remove_custom_type("FlowBehavior")
	remove_custom_type("FlowCondition")
