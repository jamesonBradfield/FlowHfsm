# Flux HFSM: Quick Start Guide

## 1. Scene Setup
1.  **CharacterBody3D**: The root of your player.
    *   Add `PhysicsManager` node (Component).
    *   Add `PlayerController` node (Driver).
    *   Add `RootState` node (Script: `RecursiveState`).
2.  **Connections**:
    *   Assign `PhysicsManager` and `RootState` slots in the `PlayerController` inspector.

## 2. Defining States
1.  **Add Child States**: Under `RootState`, add child nodes with the `RecursiveState` script.
2.  **Naming**: Name them clearly (e.g., `Idle`, `Run`, `Jump`).
3.  **Behaviors (The "What")**:
    *   Create a new `StateBehavior` resource (e.g., `BehaviorMove.tres`, `BehaviorImpulse.tres`).
    *   Assign it to the `Behavior` slot in the Inspector.
    *   *Example:* `Run` state uses `BehaviorMove` with `speed = 8.0` and `direction_source = INPUT`.

## 3. Transitions (The "When")
1.  **Conditions**: Create `StateCondition` resources (e.g., `is_grounded.tres`, `input_jump.tres`).
2.  **Wiring**:
    *   Select a State node.
    *   In the Inspector, expand `Activation Conditions`.
    *   Add a Condition resource.
    *   *Logic:* If the condition is met (and the state is higher priority/later in the list), the system automatically switches to it.

## 4. Animation Sync
1.  **Add Linker**: Add a `StateAnimationLink` node to your character.
2.  **Assign**: Drag in your `AnimationTree` and `RootState`.
3.  **Animation Tree**:
    *   Use an `AnimationNodeStateMachine`.
    *   **Crucial:** Name your Animation States exactly the same as your HFSM States (e.g., "Run", "Jump").
4.  **BlendSpaces (Blackboard Mapping)**:
    *   In `StateAnimationLink`, expand `Property Mapping`.
    *   Map a **Blackboard Key** (e.g., "input_dir") to an **Animation Parameter** (e.g., "parameters/Run/blend_position").
