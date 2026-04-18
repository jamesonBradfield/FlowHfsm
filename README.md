# FlowHFSM (Hierarchical Finite State Machine)

FlowHFSM is a standalone, general-purpose Hierarchical Finite State Machine addon for Godot 4. It provides a simple, structured, and flexible way to implement state logic, allowing anyone to organize complex behaviors in their Godot projects.

## Architecture and Core Philosophy

Managing complex states in game objects can quickly become overwhelming. FlowHFSM tackles this by focusing on clear hierarchy, stateless logic, and highly reusable components using standard Godot terminology (Nodes and Resources).

### Push-Data-Down Architecture

Data flows **downward** through the hierarchy. The actor (e.g. `FlowCharacter`) resolves a `FlowDataMap` into a context dictionary each frame, which gets passed through `process_state()` to all children and behaviors. Behaviors and conditions **never reach into actor properties directly** — they read from the context dict by key name.

This means:
- **Decoupled:** Behaviors don't need to know what node owns them or what properties it has
- **Testable:** You can feed any context dict to test behaviors in isolation
- **Extensible:** Custom resolvers can transform data before behaviors see it

### Stateless States as State Machines
The architectural core of FlowHFSM is that a `FlowState` is inherently **stateless**. Instead of storing variables within the behavior logic itself, state data is passed dynamically via the context dict. Every `FlowState` acts as its own state machine, meaning it is capable of processing and managing its own children.

### Hierarchy as Blocking Behavior
Our core philosophy revolves around hierarchy acting as blocking behavior. In FlowHFSM, **parents are the only responsible code for their children**. This ensures execution flow is predictable, top-down, and strictly contained within the active branch of the hierarchy.

### Context Filtering with `required_keys`
A `FlowState` can declare `required_keys` — an array of `StringName` keys. If non-empty, only those keys are passed to children, narrowing the info hose. If empty, the full context passes through.

### Avoiding Node Explosion with `is_concurrent`
To prevent deep, unmanageable nesting and "node explosion," FlowHFSM introduces the `is_concurrent` flag on states. This allows non-nested, parallel states to be checked concurrently alongside exclusive state machines, granting you the flexibility to manage multiple behaviors (like moving and shooting) without complex branch duplication.

### Ultimate Reusability
Because states are driven by modular Resources and are stateless, reusability is incredibly simple: **You can copy a `walk` node, rename it `run`, change a single configuration value on its Behavior resource, and you instantly have a new working state!**

## Core Components

The system relies on familiar Godot constructs to build your behaviors visually in the scene tree:

### State Machine
- **`FlowState` (Node):** The structural block of the hierarchy. Holds Behaviors and Conditions, handles concurrency, and evaluates transitions. Receives a context dict and passes it down.

### Data Flow
- **`FlowDataMap` (Resource):** An array of `FlowDataEntry` items. Lives on the actor. Each frame, `resolve(actor)` builds a `Dictionary[StringName, Variant]` (the context).
- **`FlowDataEntry` (Resource):** A key (`StringName`) + `FlowBinding` pair. Maps a named key to a value source.
- **`FlowBinding` (Resource):** Resolves a value from either a `NodePath` (property on the actor) or a `FlowResolver` (custom script).
  - **PATH mode:** `^":move_input"` reads the `move_input` property from the actor. `^"Camera3D"` gets a child node.
  - **RESOLVER mode:** Delegates to a custom `FlowResolver` script for complex logic (e.g. camera-relative input transformation).
- **`FlowResolver` (Resource):** Base class for custom data resolution. Override `resolve(actor, context) -> Variant`. Receives the partially-built context so resolvers can chain.

### Actor
- **`FlowCharacter` (CharacterBody3D):** The unified base. Has a `data_map: FlowDataMap` export. If none is assigned, auto-builds one from common properties (`move_input`, `camera`, `is_moving`, `state_packet`, `last_actions`, `animation_tree`, `model`).

### Logic
- **`FlowBehavior` (Resource):** Stateless scripts that execute logic while a state is active. `update(node, delta, actor, context)` — reads from context by configurable key names.
- **`FlowCondition` (Resource):** Evaluatable rules returning true/false. `_evaluate(actor, context)` — reads from context by configurable key names.

## Data Flow Diagram

```
FlowCharacter._physics_process()
  │
  ├── _poll_input()          # Updates move_input, is_moving, etc.
  ├── data_map.resolve(self)  # Builds context dict
  │     └── FlowDataEntry[] → FlowBinding.get_value()
  │           ├── PATH:     actor.get_indexed(NodePath)
  │           └── RESOLVER: FlowResolver.resolve(actor, context)
  │
  └── root_state.process_state(delta, self, context)
        │
        ├── Filter context via required_keys
        ├── Process concurrent children
        ├── Select exclusive child (via conditions)
        ├── Run behaviors: b.update(self, delta, actor, context)
        └── Recurse into active_child
```

## Creating Custom Resolvers

Extend `FlowResolver` and override `resolve()`:

```gdscript
class_name CameraRelativeInput extends FlowResolver

func resolve(actor: Node, context: Dictionary) -> Variant:
    var input = context.get(&"move_input", Vector3.ZERO)
    var cam = context.get(&"camera")
    if cam is Node3D:
        var basis = cam.global_transform.basis
        basis.y = Vector3.ZERO
        return (basis.x * input.x + basis.z * input.z).normalized()
    return input
```

Then assign it to a `FlowBinding` with `source = RESOLVER` and point the `resolver` export to your script.

## Writing Behaviors

Behaviors read from context by configurable key names:

```gdscript
class_name BehaviorPhysics extends FlowBehavior

@export var move_input_key: StringName = &"move_input"
@export var camera_key: StringName = &"camera"

func update(_node: Node, delta: float, actor: Node, context: Dictionary[StringName, Variant]) -> void:
    var input_vec = context.get(move_input_key, Vector3.ZERO)
    # ... apply movement
```

## Writing Conditions

Conditions also read from context:

```gdscript
class_name ConditionIsMoving extends FlowCondition

@export var is_moving_key: StringName = &"is_moving"

func _evaluate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
    return context.get(is_moving_key, false) == true
```

## Advanced Integration Example

If you want to see FlowHFSM pushed to its limits, including an advanced implementation of decoupled inputs, custom deadzones, `StatePackets`, and local split-screen multiplayer, please check out the **FlowState-Sandbox** repository:

👉 [**FlowState-Sandbox**](https://github.com/jamesonBradfield/FlowState-Sandbox)

*Note: FlowState-Sandbox is a complex, specialized implementation experiment meant to demonstrate advanced mechanics. This repository (FlowHFSM) remains the clean, standalone, and general-purpose tool intended for everyday use.*
