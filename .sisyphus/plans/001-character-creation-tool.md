# Plan: Flow HFSM Character Creation Tool

## Objective
Create an editor tool (Dock) that automates the setup of a Flow HFSM character, reducing boilerplate and ensuring correct node hierarchy and connections as described in `BUILDING_A_CHARACTER.md`.

## User Requirements
- "Separate window that let's us handle most if not all of the boiler plate"
- "One click -> ready character"
- Generate full skeleton: `CharacterBody3D` + `PlayerController` + `PhysicsManager` + `RootState` + `HFSMAnimationController`.
- Pre-made connections.

## Context
- **Framework**: Godot 4 (GDScript).
- **Existing Plugin**: `FlowHFSM` (in `addons/FlowHFSM`).
- **Docs**: `BUILDING_A_CHARACTER.md` outlines the specific structure and "Pain Points".

## Implementation Plan

### 1. Create Editor Dock Script
**File**: `addons/FlowHFSM/editor/character_creation_dock.gd`
**Inheritance**: `VBoxContainer` (or `Control`)
**Functionality**:
- **UI**:
    - Header Label: "Flow HFSM Character Creator"
    - Input: Character Name (default: "NewCharacter")
    - Button: "Create Character"
    - Status Label: Feedback
- **Logic (`_on_create_pressed`)**:
    1.  **Instantiate Root**: `CharacterBody3D`.
    2.  **Create Components**:
        - `PhysicsManager` (Node): Check for global class `PhysicsManager`. If found, attach script.
        - `RootState` (`RecursiveState`): Main HFSM container.
        - `HFSMAnimationController`: Logic-Animation bridge. Connect `root_state`.
        - `PlayerController` (Node): Check for global class `PlayerController`.
    3.  **Script Generation/Attachment**:
        - If `PlayerController` class exists, attach it.
        - If NOT exists, generate `res://PlayerController.gd` with template code from `BUILDING_A_CHARACTER.md` (lines 40-53) and attach it.
    4.  **Wiring**:
        - Set `PlayerController.root_state` = `RootState`.
        - Set `PlayerController.physics_manager` = `PhysicsManager`.
    5.  **Persistence**:
        - Pack scene (`PackedScene`).
        - Save to `res://[name].tscn` (handle duplicates).
        - Open in Editor.

### 2. Register Dock in Plugin
**File**: `addons/FlowHFSM/plugin.gd`
**Action**:
- Preload `character_creation_dock.gd`.
- In `_enter_tree()`: Instantiate dock and add to `DOCK_SLOT_LEFT_UL`.
- In `_exit_tree()`: Remove and free dock.

### 3. Template Management
- The tool should generate `PlayerController.gd` if it doesn't exist to ensure the "ready character" promise is met.
- **Template Content**:
    ```gdscript
    class_name PlayerController extends Node

    @export var root_state: RecursiveState
    @export var physics_manager: Node
    var blackboard := Blackboard.new()

    func _process(delta: float) -> void:
        blackboard.set_value("input_direction", Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
        blackboard.set_value("jump_just_pressed", Input.is_action_just_pressed("ui_accept"))
        
        if root_state:
            root_state.process_state(delta, owner, blackboard)
    ```

## Verification Steps
1.  **Enable Plugin**: Ensure no errors in Output.
2.  **Check UI**: Verify "Flow Creator" dock appears.
3.  **Test Creation**:
    - Click "Create Character".
    - Check file system for `NewCharacter.tscn` (and `PlayerController.gd` if missing).
    - Check Scene Tree:
        - `NewCharacter` (CharacterBody3D)
            - `PhysicsManager`
            - `RootState`
            - `HFSMAnimationController` (root_state assigned?)
            - `PlayerController` (Script attached? root_state assigned?)
4.  **Test Duplicate**: Click again, verify `NewCharacter_1.tscn`.

