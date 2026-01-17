# Logic Smasher: State Compiler for FlowHFSM

## 1. Overview
The "Logic Smasher" is an optimization tool that "compiles" a branch of the HFSM hierarchy into a single, optimized GDScript. 

**Goal:** Reduce runtime overhead of traversing deep node trees and generic `process_state` loops by generating hardcoded, flat logic.

## 2. Architecture

### A. The Smashed Result
The compiler will generate a new Script that extends `RecursiveState` (or a subclass). This script replaces the generic dynamic logic with hardcoded checks.

**Optimization Targets:**
1.  **Child Selection Loop:** Instead of `get_children()` + iteration, generate an `if/else` chain based on Priority (Reverse Scene Tree Order).
2.  **Condition Evaluation:** Inline calls to condition resources (or referencing them directly in properties).
3.  **Behavior Execution:** Directly call behavior methods if possible, or manage them faster.

### B. The Compiler (`LogicSmasher.gd`)
A tool script that analyzes a `RecursiveState` node and its children.

**Input:** Root `RecursiveState` node.
**Output:** A generated `.gd` script text.

**Compiling Process:**
1.  **Analyze Children:**
    *   Gather all children `RecursiveState` nodes.
    *   Sort by Priority (Last child = Highest priority).
2.  **Extract Logic:**
    *   For each child: Get `activation_conditions`, `activation_mode`.
3.  **Generate `process_state` Override:**
    *   Write code that checks conditions in priority order.
    *   `if child_C_conditions: change_active_child(child_C); return`
    *   `elif child_B_conditions: ...`
    *   `else: change_active_child(child_A)` (Default/Lowest Prio)

## 3. Implementation Strategy

### Phase 1: The Compiler Class
Create `addons/FlowHFSM/editor/logic_smasher.gd`.

```gdscript
class_name LogicSmasher extends RefCounted

static func smash_state(root: RecursiveState, output_path: String) -> Error:
    var code = _generate_header()
    code += _generate_properties(root)
    code += _generate_process_state(root)
    # ... save to file ...
```

### Phase 2: Code Generation Rules
*   **Properties:** The generated script must hold references to the *original* children nodes and their condition resources.
    *   `@export var child_jump: RecursiveState`
    *   `@export var cond_jump_pressed: StateCondition`
*   **Wiring:** The compiler must not only generate the script but also *instantiate* it (or attach it) and wire up the exported properties to the actual nodes/resources in the scene.

### Phase 3: Integration
*   Add a "Smash This State" button in the `HFSMWorkbench` (Context Mode).
*   Add a "Unsmash / Revert" option? (Maybe just swap the script back to `RecursiveState.gd`).

## 4. Example Output

**Input Tree:**
```
Root
├─ Idle (Cond: None)
└─ Jump (Cond: JumpPressed)
```

**Generated Script (`Root_Smashed.gd`):**
```gdscript
extends RecursiveState

# Auto-wired references
@export var _child_jump: RecursiveState
@export var _cond_jump_pressed: StateCondition
@export var _child_idle: RecursiveState

func process_state(delta, actor, blackboard) -> void:
    # 1. Highest Priority: Jump
    if _cond_jump_pressed.evaluate(actor, blackboard):
        if active_child != _child_jump:
            change_active_child(_child_jump, actor, blackboard)
        
        # Update Behavior & Child
        _update_behavior(delta, actor, blackboard)
        _child_jump.process_state(delta, actor, blackboard)
        return

    # 2. Lowest Priority: Idle
    # (No conditions = always true)
    if active_child != _child_idle:
        change_active_child(_child_idle, actor, blackboard)
    
    _update_behavior(delta, actor, blackboard)
    _child_idle.process_state(delta, actor, blackboard)
```

## 5. Challenges
*   **Dynamic Children:** If children are added/removed at runtime, the smashed script will be invalid. (Assumption: Smashed states are static structures).
*   **Property Linking:** Automatically assigning the `@export` references after attaching the script is tricky in `tool` mode. We might need to use `set_script` and then `set` the properties immediately.

