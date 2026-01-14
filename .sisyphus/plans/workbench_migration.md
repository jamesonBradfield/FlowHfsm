# Migration Plan: AssetCreationDialog -> HFSMWorkbench

## 1. Overview
The goal is to replace the modal `AssetCreationDialog` with a persistent `HFSMWorkbench` dock at the bottom of the editor. This workbench will handle both asset creation (Dashboard mode) and state editing (Context mode).

## 2. Gap Analysis
| Feature | AssetCreationDialog (Old) | HFSMWorkbench (New Target) | Action |
| :--- | :--- | :--- | :--- |
| **Type** | `ConfirmationDialog` (Popup) | `Control` (Bottom Panel) | **Change Inheritance** |
| **Dashboard** | Template/Duplicate/Extend/Node | Template/Node | **Port Duplicate/Extend Logic** |
| **Context** | None | Variables & Behaviors Editor | **Implement using `HFSMPropertyFactory`** |
| **UI Construction**| Code-based `VBox` | Scene (`.tscn`) + Code | **Create .tscn & Link** |

## 3. Execution Steps

### Phase 1: Cleanup & Setup
1.  **Delete Obsolete File**: Remove `addons/FlowHFSM/editor/asset_creation_dialog.gd`.
2.  **Create Scene**: Use `godot_create_scene` to create `addons/FlowHFSM/editor/HFSMWorkbench.tscn` with root type `VBoxContainer`.
3.  **Update Plugin**: Modify `addons/FlowHFSM/plugin.gd` to load the `.tscn` instead of the `.gd` script directly.

### Phase 2: Script Implementation (`hfsm_workbench.gd`)
Rewrite `addons/FlowHFSM/editor/hfsm_workbench.gd` to act as the logic for the new scene.

#### A. Architecture
- **Inheritance**: `VBoxContainer` (matching the scene root).
- **Modes**:
    - `DASHBOARD`: Active when no `RecursiveState` is selected.
    - `CONTEXT`: Active when a `RecursiveState` node is selected.
- **Selection Monitoring**: Use `EditorInterface.get_selection()` in `_process()` (polled) or `_ready()` signals to detect changes.

#### B. Dashboard Mode (Ported Logic)
- **UI**: HBoxContainer with "Cards" for actions.
- **Actions**:
    - `New Behavior`: Opens Config Form (Template).
    - `New Condition`: Opens Config Form (Template).
    - `Duplicate`: Opens Config Form with Source Picker.
    - `Extend`: Opens Config Form with Parent Picker.
- **Config Form**: Re-implement the form from `asset_creation_dialog.gd` (Class Name, Folder, Source Script).

#### C. Context Mode (New Logic)
- **Header**: Display "Editing: [Node Name]".
- **Variables Editor**:
    - Iterate `node.declared_variables`.
    - Use `HFSMPropertyFactory` to create UI rows for each variable.
    - Add/Remove buttons modifying the array via `EditorUndoRedoManager`.
- **Behaviors Editor**:
    - Iterate `node.behaviors`.
    - Use `HFSMPropertyFactory` to create UI cards for each resource.
    - Add/Remove buttons modifying the array via `EditorUndoRedoManager`.
- **Child Creation**:
    - Keep existing "+ Add Child State" button.

### Phase 3: Verification
1.  **Dashboard Check**: Verify "New Behavior" creates files correctly.
2.  **Selection Check**: Verify clicking a `RecursiveState` switches to Context Mode.
3.  **Context Check**: Verify variables and behaviors can be added/edited inline.

## 4. Technical Details (Code Snippets)

### Selection Logic
```gdscript
func _check_selection() -> void:
    var selection = EditorInterface.get_selection().get_selected_nodes()
    var node = selection[0] if not selection.is_empty() else null
    if node != _last_selected_node:
        _last_selected_node = node
        _on_selection_changed()
```

### Context Editor Implementation
Use `HFSMPropertyFactory.create_property_list(resource, callback)` to generate inspectors for `StateBehavior` resources and `StateVariable` instances inline.

```gdscript
# Example: Adding a variable
func _on_add_variable_pressed():
    var ur = EditorInterface.get_editor_undo_redo()
    var new_list = active_node.declared_variables.duplicate()
    new_list.append(StateVariable.new())
    ur.create_action("Add Variable")
    ur.add_do_property(active_node, "declared_variables", new_list)
    ur.add_undo_property(active_node, "declared_variables", active_node.declared_variables)
    ur.commit_action()
```

## 5. Dependencies
- `addons/FlowHFSM/editor/property_factory.gd` (Crucial helper)
- `addons/FlowHFSM/editor/flow_hfsm_theme.tres` (Styling)

