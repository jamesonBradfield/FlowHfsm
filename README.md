# FlowHFSM (Hierarchical Finite State Machine)

FlowHFSM is a standalone, general-purpose Hierarchical Finite State Machine addon for Godot 4. It provides a simple, structured, and flexible way to implement state logic, allowing anyone to organize complex behaviors in their Godot projects.

## Architecture and Core Philosophy

Managing complex states in game objects can quickly become overwhelming. FlowHFSM tackles this by focusing on clear hierarchy, stateless logic, and highly reusable components using standard Godot terminology (Nodes and Resources). 

### Stateless States as State Machines
The architectural core of FlowHFSM is that a `FlowState` is inherently **stateless**. Instead of storing variables within the behavior logic itself, state data is passed dynamically or handled by the parent actor's memory. Every `FlowState` acts as its own state machine, meaning it is capable of processing and managing its own children.

### Hierarchy as Blocking Behavior
Our core philosophy revolves around hierarchy acting as blocking behavior. In FlowHFSM, **parents are the only responsible code for their children**. This ensures execution flow is predictable, top-down, and strictly contained within the active branch of the hierarchy.

### Avoiding Node Explosion with `is_concurrent`
To prevent deep, unmanageable nesting and "node explosion," FlowHFSM introduces the `is_concurrent` flag on states. This allows non-nested, parallel states to be checked concurrently alongside exclusive state machines, granting you the flexibility to manage multiple behaviors (like moving and shooting) without complex branch duplication.

### Ultimate Reusability
Because states are driven by modular Resources and are stateless, reusability is incredibly simple: **You can copy a `walk` node, rename it `run`, change a single configuration value on its Behavior resource, and you instantly have a new working state!**

## Core Components

The system relies on familiar Godot constructs to build your behaviors visually in the scene tree:

- **`@addons/FlowHFSM/src/core/FlowState.gd` (Node):** The structural block of the hierarchy. Holds Behaviors and Conditions, handles concurrency, and evaluates transitions.
- **`@addons/FlowHFSM/src/core/FlowCharacter.gd` (Node):** The unified base that handles input, physics, and animation syncing automatically. Extended by your player or enemies.
- **`@addons/FlowHFSM/src/core/FlowBehavior.gd` (Resource):** Small, reusable, stateless scripts that execute logic while a state is active (e.g., applying movement velocity).
- **`@addons/FlowHFSM/src/core/FlowCondition.gd` (Resource):** Simple, evaluatable rules returning true/false that determine when to transition between states.

## Advanced Integration Example

If you want to see FlowHFSM pushed to its limits, including an advanced implementation of decoupled inputs, custom deadzones, `StatePackets`, and local split-screen multiplayer, please check out the **FlowState-Sandbox** repository:

👉 [**FlowState-Sandbox**](https://github.com/jamesonBradfield/FlowState-Sandbox)

*Note: FlowState-Sandbox is a complex, specialized implementation experiment meant to demonstrate advanced mechanics. This repository (FlowHFSM) remains the clean, standalone, and general-purpose tool intended for everyday use.*