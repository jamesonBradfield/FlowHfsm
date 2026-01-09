# Mental Model: The Blackboard & State Machine Architecture

This document explains the architecture choices in this project, specifically focusing on the **Blackboard Pattern**, **State Machine**, and why we handle `is_grounded` the way we do.

## 1. The Blackboard: "The Source of Truth"

The **Blackboard** is a shared memory space for an entity (like the Player or an Enemy). Think of it as a whiteboard where different systems can write notes and read facts about the current situation.

-   **It holds DATA, not behavior.**
-   Examples: `is_grounded`, `health`, `target_position`, `can_double_jump`.

## 2. The Loop: Sense -> Think -> Act

To understand why `is_grounded` isn't "redundant", we must look at the flow of information:

1.  **SENSE (Physics/Sensors)**:
    -   The main character script (e.g., `Player.gd` or a `GroundSensor` node) runs in `_physics_process`.
    -   It casts rays or checks collisions.
    -   **It writes to the Blackboard:** `blackboard.set_value("is_grounded", true)`
    -   *Crucial Point:* The Blackboard gets updated *regardless* of what State the machine is in.

2.  **THINK (State Machine Transitions)**:
    -   The State Machine looks at the Blackboard to decide if it needs to change states.
    -   It uses **Conditions** (like `CheckBlackboardCondition`) to ask questions:
        -   "Is `is_grounded` true? If yes, transition to `Idle` or `Run`."
        -   "Is `is_grounded` false? If yes, transition to `Fall` or `Jump`."

3.  **ACT (The State)**:
    -   The active State (e.g., `AirState`) executes behavior.
    -   *It does NOT calculate if we are grounded.* It assumes we are in the air because we entered this state.
    -   It might apply gravity or air control.

## 3. Addressing the Redundancy Concern

> *"If `is_grounded` is active, the state itself should be active... checking for a variable... seems redundant."*

This feeling comes from conflating **Cause** and **Effect**.

-   **Scenario A (Bad - Circular):**
    -   State `Grounded` calculates if we are on the ground.
    -   If we are on the ground, it sets `is_grounded = true`.
    -   *Problem:* How do we *enter* the Grounded state in the first place? If we are in `Fall` state, we aren't calculating ground collision yet (or we are duplicating that logic in every state).

-   **Scenario B (Good - Decoupled):**
    -   **Sensors** (Global) check the ground *always*.
    -   **Blackboard** stores the result (`is_grounded`).
    -   **Transitions** check the Blackboard.
    -   **States** just do what they are told.

### Why `CheckBlackboardCondition`?

By using a generic `CheckBlackboardCondition` resource, we make our State Machine **data-driven**.

-   We don't need to write a new script `IsGroundedCondition.gd`, `IsHurtCondition.gd`, `IsDeadCondition.gd`.
-   We just create a Resource, set the key to `"is_grounded"`, and plug it into the transition.
-   This allows designers to tweak logic without coding.

## Summary

1.  **Sensors** update the Blackboard (Inputs -> Data).
2.  **Conditions** check the Blackboard (Data -> Decisions).
3.  **States** execute behavior (Decisions -> Actions).

The State doesn't *set* `is_grounded`; the physical world does. The State just responds to it.
