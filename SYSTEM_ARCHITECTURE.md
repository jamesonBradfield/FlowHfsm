# Flux HFSM: Universal Kinematic State Machine
**Status:** In Development (Pre-Alpha)
**Target:** Patch Notes Jam (Jan 10/12)

---

## 1. System Overview
Flux HFSM is a **Hierarchical Finite State Machine (HFSM)** designed to be the "Standard Library" for character controllers in Godot 4.5+.

**Core Philosophy:**
1.  **Universal Kinematics:** Logic defines *intent* (Move, Jump, Dodge), while a decoupled Motor handles the math (Camera-Relative vs World-Relative). This allows one codebase to support 2D, 3D, FPS, and Top-Down.
2.  **Strategy Pattern (Logic as Resources):** State Nodes (`RecursiveState`) are generic containers. Logic is injected via reusable **Behavior Resources**.
3.  **Data-Driven Logic:** Transitions are assets, not code. Logic gates (AND/OR/NOT) are composed in the Inspector.
4.  **Recursive Hierarchy:** States manage their children. Prohibitive logic flows down (Parent checks transitions -> Child ticks).

---

## 2. The Architecture Components

### A. The Motor: `PhysicsManager`
A Node component attached to the `CharacterBody`.
* **Role:** The "Executor". Receives velocity requests, applies gravity/friction, and calls `move_and_slide()`.
* **The "Frame of Reference" Switch:**
    * `Frame.WORLD`: 2D Platformers / Isometric.
    * `Frame.CAMERA`: Third-Person / FPS (Forward = Camera Look).
    * `Frame.ACTOR`: Tank Controls / Vehicles / Dodges (Forward = Actor Model Z).

### B. The Container: `RecursiveState` (Node)
The generic Node script attached to the Scene Tree.
* **Role:** The "Hardware". It holds the position in the hierarchy and the runtime data.
* **Memory:** Contains a `memory: Dictionary` for ephemeral data (timers, counters) unique to *this* instance.
* **Recursion:** Ticks its `active_child`. If a Parent transitions, the Child is implicitly exited.

### C. The Brain: `StateBehavior` (Resource)
The reusable logic asset (e.g., `BehaviorMove.tres`, `BehaviorImpulse.tres`).
* **Role:** The "Software". Defines *what* the state does.
* **Stateless:** Stores **no** variables. Reads from `blackboard` (Global) and reads/writes to `node.memory` (Local).
* **Capabilities:**
    * **Direction Source:** Can use `INPUT` (WASD) or `FIXED` (Hardcoded Vector for Dodges).
    * **Orientation:** Can choose to face movement direction or remain locked.

### D. The Glue: `StateTransition` & `StateCondition` (Resources)
* **Condition:** Atomic query scripts (`IsGrounded`, `InputPressed`, `AmmoEmpty`).
* **Transition:** A container holding an Array of Conditions and an Operation (`AND` / `OR`).
* **Workflow:** Logic is wired in the Inspector by dragging Condition resources into Transition slots.

### E. The Hierarchy Strategy (Weapons as Parents)
Weapons/Modes are **Parent States** that impose physics constraints on movement.
* **Hierarchy Example:**
    * `Root`
        * `UnarmedState` (Behavior: None) -> `Move` (Child)
        * `RifleState` (Behavior: Apply Speed Penalty) -> `Move` (Reused Child!)
        * `MinigunState` (Behavior: Disable Jumping) -> `Move` (Reused Child!)

---

## 3. Data Flow

1.  **Input:** `PlayerController` polls input -> Updates **Blackboard** (Global Dictionary).
2.  **Machine Tick:** `PlayerController` ticks `RootState`.
3.  **Gatekeeping:** Active State (and Parents) check **Transitions**.
    * Conditions read **Blackboard** (e.g., `blackboard["is_jump_pressed"]`).
4.  **Logic Execution:** If no transition, `StateBehavior` runs `update()`.
    * Behavior reads/writes **Node Memory** (e.g., `node.memory["charge_timer"]`).
5.  **Intent:** Behavior sends `move_intent()` to **PhysicsManager**.
6.  **Physics:** **PhysicsManager** resolves `Frame` (Camera vs Actor), Gravity, and Friction -> Moves Body.
7.  **Visuals:** (Upcoming) `AnimationTree` reads velocity/state path to blend animations.

---

## 4. Development Roadmap

### ✅ Phase 1: The Motor
* [x] `PhysicsManager` (Gravity, Friction, World/Camera/Actor Frames).
* [x] `PlayerController` (Input -> Blackboard pipeline).

### ✅ Phase 2: The Structure
* [x] `RecursiveState` (Node Container, Memory Dict).
* [x] `StateBehavior` (Base Resource, Generic Move Logic).
* [x] **Feature:** `BehaviorMove` supports Fixed Direction (Dodges) vs Input (Run).

### ✅ Phase 3: The Logic Gates
* [x] `StateCondition` (Base Resource).
* [x] `StateTransition` (AND/OR Logic).
* [x] Standard Lib: `ConditionInput`, `ConditionIsGrounded`.

### ✅ Phase 4: Integration & Visuals
* [x] **Debug UI:** `StateDebugger` (Visualize Tree Path + Memory).
* [ ] **Animation Sync:** Link `RecursiveState` active path to `AnimationTree` playback, be able to define blending for movement, and linking data in the blackboard to animationTree (so users can utilize AnimationStateMachine in their own custom states).
* [x] **First Playable:** Construct `Idle` -> `Run` -> `Jump` character.
* [ ] **Add UndoRedo to UI/Plugin** allow UndoRedo in Custom UI.

###  Phase 5: Debugging/Unit testing.
* [ ] **Memory Debugging** find out why data is displayed as empty in statedebugger, this might just be us not utilizing the blackboard rn.
* [ ] **Add Transitions button Error** TODO: add ERROR here
* [ ] **Unified Themes for all custom Inspectors** Transition Custom inspector resizes smaller than Behavior Custom Inspector, we should look into a theme to unify both.
* [ ] **Test Custom UI somehow** :shrug:
* [ ] **Build example scenes to test all functionality** not sure what test cases we need, but we can use gdunit to run these and simulate input for each case.


###  Phase 6: Generic Tool Creation to streamline code creation.
* [ ] **Creation API** build generic state creation api that can both be called via external tooling.
* [ ] **Default Godot Editor Tooling** build godot tooling to streamline state creation (text boxes that allow you to only write an "atomic if" statement for transitions/triggers avoiding writing boilerplate), (code syntax highlighting, lsp etc).
* [ ] **Custom nvim tooling for making states** I use nvim btw, so this is the final cherry on top.


## 5. Recent Refactors
*   **PlayerController:** Parameterized input action names for easier remapping.
*   **PhysicsManager:** Added `terminal_velocity` and documentation updates.
*   **StateDebugger:** Implemented recursive path visualization and memory inspection.
*   **BehaviorImpulse:** Refactored `BehaviorJump` to `BehaviorImpulse` to support generic instantaneous force application.
