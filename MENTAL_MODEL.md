# Mental Model: The HFSM Architecture

This document explains the architecture choices in this project, specifically focusing on the **HFSM (Hierarchical Finite State Machine)** and how it interacts with the Actor.

## 1. The Actor: "The Source of Truth"

The **Actor** (e.g., `PlayerController`, `EnemyAI`) is the owner of the state machine.
-   It holds the **DATA** (e.g., `input_direction`, `is_grounded`, `health`).
-   It acts as the bridge between the physics world (Godot) and the logic world (HFSM).

## 2. The Loop: Sense -> Think -> Act

1.  **SENSE (Physics/Input)**:
    -   The `PlayerController` polls input and checks physics in `_process` / `_physics_process`.
    -   It updates its own properties: `controller.is_moving = true`, `controller.input_direction = Vector3(...)`.

2.  **THINK (State Machine Transitions)**:
    -   The **HFSM** looks at the Actor to decide if it needs to change states.
    -   **Conditions** ask questions about the Actor:
        -   "Is `actor.is_grounded` true? Transition to `Idle`."
        -   "Is `actor.input_direction` non-zero? Transition to `Run`."

3.  **ACT (The State)**:
    -   The active **State Behavior** executes logic.
    -   It reads from the Actor to know *how* to act (e.g. `move_speed`).
    -   It applies forces/velocity back to the Actor.

## 3. Why No Blackboard?

We moved away from a generic "Blackboard" dictionary to direct **Property Access**.

-   **Type Safety:** Accessing `actor.health` is type-safe and autocompleted. `blackboard["health"]` is not.
-   **Simplicity:** No need to sync data into a middle-man dictionary. The Actor *is* the data source.
-   **Clarity:** It enforces a clear separation:
    -   **Actor:** Holds World State (Input, Physics, Health).
    -   **HFSM:** Holds Logical State (Idle, Run, Attack).
    -   **Memory:** Holds Temporary State (Timers, counters) inside `node.memory`.

## Summary

1.  **Actor** gathers Input/Physics -> Sets Public Properties.
2.  **Conditions** read Actor Properties -> Return True/False.
3.  **Behaviors** read Actor Properties -> Apply Forces/Animation.

The HFSM logic (Transitions) relies on the Actor's state, but the Actor doesn't know about the HFSM's internal logic. This keeps them decoupled but efficient.
