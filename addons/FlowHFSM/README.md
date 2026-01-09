# Flow HFSM (Hierarchical Finite State Machine)

A robust, editor-friendly Hierarchical Finite State Machine for Godot 4. Designed for decoupled logic, reusable behaviors, and deep nesting.

## 🚀 Key Features

*   **Recursive Hierarchy:** States can contain other States. Build complex logic trees (e.g., `Move` > `Run` > `Sprint`) effortlessly.
*   **Resource-Based Logic:** Behaviors are reusable Resources. Write a `JumpBehavior` once, use it on Player, Enemy, and NPC.
*   **Inline Editor:** Custom Inspector tools allow you to edit State Behaviors and Conditions directly on the Node, skipping the "Sub-Resource Click" fatigue.
*   **Priority-Based Transitions:** No messy wire spaghetti. Child states are evaluated in order; the best valid state wins.
*   **Actor-Centric:** Logic reads directly from the Actor (Entity), ensuring type safety and clarity.

---

## 📦 Installation

1. Copy the `addons/hfsm_editor` folder into your project's `addons/` directory.
2. Go to **Project > Project Settings > Plugins**.
3. Enable **Flow HFSM**.

---

## ⚡ Quick Start

### 1. The Container (RecursiveState)
The core of the system is the `RecursiveState` node. It holds the logic and manages its children.

1. Add a `RecursiveState` node to your scene (e.g., as a child of your `CharacterBody3D`).
2. This is your **Root State**.

### 2. The Brain (StateBehavior)
States need logic. We call this a **Behavior**.

1. Select your `RecursiveState` node.
2. In the Inspector, locate the **Behavior** slot.
3. Create a new `StateBehavior` (or your custom class, e.g., `RunBehavior`).
4. **Crucial:** Behaviors are *stateless*. Do not store variables in the script. Use `node.memory` to store data (counters, timers, etc.).

### 3. The Hierarchy (Child States)
1. Add child nodes to your Root State. These are also `RecursiveState` nodes.
2. Assign Behaviors to them (e.g., `Idle`, `Run`, `Attack`).

### 4. The Atom (StateCondition)
Transitions are handled automatically by **Conditions**.

1. Select a child state (e.g., `Run`).
2. In the Inspector, expand **Activation Conditions**.
3. Add a new `StateCondition` resource (e.g., `IsMovingCondition`).
4. The parent state will now check this condition. If it returns `true`, this state becomes active.

---

## 🧠 Mental Model

### 1. The Container (`RecursiveState.gd`)
The Node in the scene tree. It is responsible for:
*   **Lifecycle:** Calling `enter`, `exit`, and `update` on the Behavior.
*   **Recursion:** passing the update loop down to the Active Child.
*   **Memory:** Holding the `memory` Dictionary for the Behavior to use.

### 2. The Brain (`StateBehavior.gd`)
The "What". A **Stateless Resource** that defines logic.
*   Reused across multiple entities.
*   **Must not** store local variables (they would be shared across all instances!).
*   Access `node.memory` to store instance-specific data.
*   Access `actor` (passed in `update`) to read input/physics data.

### 3. The Atom (`StateCondition.gd`)
The "When". A **Logic Gate** that returns true or false.
*   Attached to a State.
*   Evaluated by the *Parent* to determine if this child should be active.
*   Can be reversed (NOT gate) via the `Reverse Result` checkbox.

---

## 🛠️ Editor Tools

Flow HFSM includes a custom Inspector plugin (`hfsm_inspector.gd`) to improve quality of life.

*   **Inline Editing:** Instead of clicking into a Resource to edit its properties, the Inspector displays Behavior and Condition properties *inline*.
*   **Context:** See everything at a glance without navigating back and forth between sub-resources.
