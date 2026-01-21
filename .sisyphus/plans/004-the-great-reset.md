Status: Draft Author: Jamie (via Iris) Context: "Burning the Editor"
1. The Variable Lane: "Inspector Driven"

You felt StateVariables and SmartValues were fighting because the Editor tried to abstract them. Without the Editor, the distinction is clear and necessary:

    Lane Selected: The "Producer / Consumer" Model.

        Producer (StateVariable): You add these to a FlowState in the Inspector to create data on the Blackboard. (e.g., "I declare a float named speed").

        Consumer (SmartValue): You assign these to a FlowBehavior in the Inspector to read data. (e.g., "I want to read speed from the Blackboard").

    The Change: We change nothing in the core logic. We simply stop trying to build a custom UI for them. We trust the Inspector.

2. The Execution: Operation Scorched Earth

We are deleting the entire editor folder. This removes the Graph, the Palette, the Variable Editor, and the complexity.

Files to DELETE:

    addons/FlowHFSM/src/editor/ (The entire directory)

3. The Survivor: A Minimal plugin.gd

Since we are deleting the editor, the current plugin.gd (which tries to load the Workbench) will crash Godot. We must replace it with a "Headless" plugin that simply registers our types.

New addons/FlowHFSM/plugin.gd:
GDScript

@tool
extends EditorPlugin

func _enter_tree() -> void:
    # Core
    add_custom_type("FlowCharacter", "CharacterBody3D", preload("res://addons/FlowHFSM/src/base/FlowCharacter.gd"), preload("res://addons/FlowHFSM/icon.svg"))
    add_custom_type("FlowState", "Node", preload("res://addons/FlowHFSM/src/core/FlowState.gd"), preload("res://addons/FlowHFSM/icon.svg"))
    
    # Logic
    add_custom_type("FlowBehavior", "Resource", preload("res://addons/FlowHFSM/src/core/FlowBehavior.gd"), preload("res://addons/FlowHFSM/icon.svg"))
    add_custom_type("FlowCondition", "Resource", preload("res://addons/FlowHFSM/src/core/FlowCondition.gd"), preload("res://addons/FlowHFSM/icon.svg"))

    # Library (Optional, usually we just let users instance scripts)
    # You can add specific behaviors here if you want them in the "Create Node" dialog, 
    # but usually Resources are created via the Inspector.

func _exit_tree() -> void:
    remove_custom_type("FlowCharacter")
    remove_custom_type("FlowState")
    remove_custom_type("FlowBehavior")
    remove_custom_type("FlowCondition")

Next Steps

This is a one-way trip. Once we do this, you will build your State Machines by adding Nodes in the Scene Tree (Just like standard Godot nodes) and editing properties in the Inspector.

To execute:

    Overwrite addons/FlowHFSM/plugin.gd with the code above.

    Delete the addons/FlowHFSM/src/editor folder.

    Reload your project.
