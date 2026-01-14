# Plan: Flow HFSM Asset Creation Wizard

## Objective
Create a workflow tool ("Wizard") integrated into the Flow HFSM Inspector that streamlines the creation of `StateBehavior` and `StateCondition` assets. This replaces the manual "Create Script -> Extend Class -> Save -> Create Resource -> Assign" loop with a single UI flow.

## User Requirements
- "Workflows to create States from Behaviors, Conditions..."
- "Walk you through duplicating a premade condition and editing its if statement"
- "Writing your own conditional to create a new state condition"
- Support **Templates**, **Duplication** (Copy), and **Extension** (Inheritance).

## Architecture

### 1. `AssetCreationDialog` (New Tool)
A `ConfirmationDialog` that appears when the user clicks "Create New" in the Inspector.
**UI Sections:**
1.  **Mode Selector** (TabContainer):
    *   **Template**: Start fresh.
    *   **Duplicate**: Clone an existing script (Regex replace class_name).
    *   **Extend**: Inherit from an existing script.
2.  **Configuration**:
    *   **Class Name**: Input (Validation: Must be unique).
    *   **Folder**: DirAccess selector (Defaults to `res://`).
3.  **Preview**: Code preview of the generated script.

### 2. `ScriptGenerator` (Logic)
Helper class to handle text processing.
- `create_from_template(template_name, class_name)`
- `create_duplicate(source_path, new_class_name)`: Reads source, finds `class_name X`, replaces with `class_name Y`.
- `create_extension(parent_class_name, new_class_name)`: `class_name Y extends X`.

### 3. Editor Integration
Modify `behavior_editor.gd` and `condition_editor.gd`:
- Add **"Wizard"** button.
- On success:
    1.  Force filesystem scan.
    2.  Load the new script.
    3.  Create a `Resource` instance with that script.
    4.  Save the Resource (`.tres`).
    5.  Assign to the array.
    6.  Open script in Editor.

## Templates

### Condition: Empty
```gdscript
class_name {ClassName} extends StateCondition

func _evaluate(actor: Node, blackboard: Blackboard) -> bool:
    return false
```

### Condition: Blackboard Check
```gdscript
class_name {ClassName} extends StateCondition

@export var key: String = "some_key"
@export var target_value: bool = true

func _evaluate(actor: Node, blackboard: Blackboard) -> bool:
    return blackboard.get_value(key) == target_value
```

### Behavior: Empty
```gdscript
class_name {ClassName} extends StateBehavior

func enter(node: RecursiveState, actor: Node, blackboard: Blackboard) -> void:
    pass

func update(node: RecursiveState, delta: float, actor: Node, blackboard: Blackboard) -> void:
    pass

func exit(node: RecursiveState, actor: Node, blackboard: Blackboard) -> void:
    pass
```

## Implementation Steps

1.  **Create `addons/FlowHFSM/editor/asset_creation_dialog.gd`**:
    - Build the UI (Tabs for New/Copy/Extend).
    - Implement the `generate_script()` logic.
    - Implement `save_and_load()`.

2.  **Update `behavior_editor.gd` & `condition_editor.gd`**:
    - Instantiate `AssetCreationDialog`.
    - Handle the `resource_created` signal to update the list.

## Verification
1.  **New Template**: Create "MyJump" -> Verify file/class/resource exists and is assigned.
2.  **Duplicate**: Pick "MyJump" -> Duplicate as "MyDoubleJump" -> Verify code is identical except class name.
3.  **Extend**: Pick "MyJump" -> Extend as "MySuperJump" -> Verify `extends MyJump`.

