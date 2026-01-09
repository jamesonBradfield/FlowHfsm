# Flow HFSM - Architecture Reference

**Version:** 1.0.0
**Last Updated:** 2025-01-08

---

## Overview

Flow HFSM (Hierarchical Finite State Machine) is a recursive, resource-based state machine system designed for Godot 4. It provides a clean, editor-friendly architecture for complex state logic with priority-based automatic transitions.

---

## Core Architecture

### 1. The Container (`RecursiveState`)

**File:** `addons/hfsm_editor/runtime/RecursiveState.gd`

The `RecursiveState` class is the core node that holds the state machine together. Each `RecursiveState` can act as both a state and a container for child states, enabling deep nesting.

#### Responsibilities:

- **Lifecycle Management:** Calls `enter`, `exit`, and `update` on the assigned Behavior
- **Recursion:** Passes the update loop down to the active child state
- **Memory:** Holds a `memory` Dictionary for the Behavior to store runtime data
- **Priority Selection:** Automatically selects the highest-priority child based on conditions

#### Key Variables:

```gdscript
var behavior: StateBehavior           # The logic resource
var activation_conditions: Array[StateCondition]  # Activation requirements
var activation_mode: int               # AND or OR logic
var is_starting_state: bool          # Default child when parent is entered
var has_history: bool                # Resume active child on re-entry
var is_locked: bool                 # Prevent parent from transitioning out
var active_child: RecursiveState     # Currently active child
var parent: RecursiveState           # Parent in hierarchy
var memory: Dictionary               # Runtime data storage
```

#### Priority-Based Child Selection (CRITICAL):

**IMPORTANT:** The priority system works on Scene Tree order.

- **Mechanism:** When `process_state` runs, it iterates through **all** child states
- **Evaluation:** Each child is checked via `can_activate(actor, blackboard)`
- **Selection:** The **LAST** child that can activate becomes the active child
- **Result:** Lower nodes in the Scene Tree (Inspector) **override** higher nodes

**Example:**
```
Root
├─ Idle      (Index 0 - Lowest Priority)
├─ Run       (Index 1 - Medium Priority)
└─ Combat    (Index 2 - Highest Priority)
```

If all three states have `can_activate()` returning `true`:
1. `Idle` is evaluated first → `best_child = Idle`
2. `Run` is evaluated → `best_child = Run` (overwrites)
3. `Combat` is evaluated → `best_child = Combat` (overwrites)
4. **Result:** `Combat` wins (last in list)

**Why This Design:**
- Mirrors Godot's Scene Tree rendering order (lower nodes render on top)
- Allows higher-priority states (Combat) to override lower-priority ones (Idle)
- Makes priority visually obvious in the Inspector (lower = higher priority)

**Code Reference:**
```gdscript
# Line 79-82 in RecursiveState.gd
for child in get_children():
    if child is RecursiveState:
        if child.can_activate(actor, blackboard):
            best_child = child  # Overwrites previous - last wins
```

---

### 2. The Brain (`StateBehavior`)

**File:** `addons/hfsm_editor/runtime/StateBehavior.gd`

The `StateBehavior` is a **stateless resource** that defines "what" a state does.

#### Key Principle: Stateless Design

**CRITICAL:** Do **NOT** store variables in `StateBehavior` subclasses.

**Why:** Resources are shared across all instances. If you store a timer in a Behavior, it will be shared by all states using that Behavior.

**Correct Pattern:**
```gdscript
class_name AttackBehavior extends StateBehavior

func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary) -> void:
    # ✅ CORRECT: Use node.memory for instance-specific data
    if not node.memory.has("attack_timer"):
        node.memory["attack_timer"] = 0.0

    node.memory["attack_timer"] += delta
```

**Incorrect Pattern:**
```gdscript
class_name AttackBehavior extends StateBehavior

var attack_timer: float = 0.0  # ❌ WRONG: Shared by all Attack states!

func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary) -> void:
    attack_timer += delta  # Will affect ALL Attack states!
```

#### Virtual Functions to Override:

```gdscript
# Called when state is entered
func enter(node: RecursiveState, actor: Node, blackboard: Dictionary)

# Called every frame while state is active
func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary)

# Called when state is exited
func exit(node: RecursiveState, actor: Node, blackboard: Dictionary)
```

---

### 3. The Atom (`StateCondition`)

**File:** `addons/hfsm_editor/runtime/StateCondition.gd`

The `StateCondition` is a **stateless resource** that returns a boolean. It represents the "when" logic for state activation.

#### Usage:

Conditions are evaluated by the **Parent** state to determine if a child should become active.

**Example:**
```
Root (RecursiveState)
├─ Idle (RecursiveState)
│   └─ activation_conditions: [IsGroundedCondition]
├─ Jump (RecursiveState)
│   └─ activation_conditions: [JumpPressedCondition]
└─ Fall (RecursiveState)
    └─ activation_conditions: [NotGroundedCondition]
```

When `Root.process_state()` runs:
1. Check `Idle.can_activate()` → True if grounded
2. Check `Jump.can_activate()` → True if jump pressed
3. Check `Fall.can_activate()` → True if not grounded
4. **Last valid state wins** (Priority)

#### Logic Modes:

```gdscript
enum ActivationMode { AND, OR }

# AND Mode (default): All conditions must be true
activation_conditions = [cond1, cond2, cond3]
# Result: cond1 AND cond2 AND cond3

# OR Mode: At least one condition must be true
activation_conditions = [cond1, cond2, cond3]
# Result: cond1 OR cond2 OR cond3
```

#### Reverse Result:

The `reverse_result` flag inverts the condition's output:

```gdscript
var reverse_result: bool = false  # Normal: returns evaluate() result
var reverse_result: bool = true   # Inverted: returns NOT evaluate()
```

**Use Case:** Create negative conditions without writing new classes.

---

## Hierarchy Mechanics

### State Transition Flow

When `process_state(delta, actor, blackboard)` is called on a `RecursiveState`:

```
1. [SELECTOR] Evaluate all children in order
   ├─ For each child:
   │  └─ if child.can_activate(actor, blackboard):
   │      └─ best_child = child  (overwrites previous)
   └─ best_child = last valid child (highest priority)

2. [SWITCH] If best_child != active_child AND not locked:
   ├─ active_child.exit(actor, blackboard)
   ├─ active_child = best_child
   └─ best_child.enter(actor, blackboard)

3. [BEHAVIOR] Update current state's logic:
   └─ behavior.update(self, delta, actor, blackboard)

4. [RECURSION] Pass control down:
   └─ if active_child:
      └─ active_child.process_state(delta, actor, blackboard)
```

### Locking Mechanism

The `is_locked` flag prevents transitions out of a state.

```gdscript
# Local lock (only this state)
is_locked = true

# Hierarchical lock check
is_hierarchy_locked() -> bool
  # Returns true if this state OR any active descendant is locked
```

**Use Cases:**
- Animation locks (can't jump during attack animation)
- Input blocking (can't dodge while stunned)
- Committed actions (cannot interrupt special moves)

### History Mechanism

The `has_history` flag allows a state to remember which child was active.

**Example:**
```
Grounded (has_history = true)
├─ Idle (active)
└─ Run
```

Transition flow with history:
1. `Grounded` exits → Saves `active_child = Idle` in memory
2. Enter `Air` state (transition to jump/fall)
3. Return to `Grounded` → Resumes `Idle` automatically

**Without history:**
- Returns to the starting child (defined by `is_starting_state`)

---

## Blackboard System

The blackboard is a shared Dictionary passed through the entire hierarchy.

```gdscript
var blackboard: Dictionary = {
    "inputs": {"jump": false, "attack": false},
    "is_grounded": true,
    "health": 100,
    "enemy_target": null
}
```

**Benefits:**
- Decoupled data access
- No tight coupling between states
- Easy to pass information across hierarchy
- Behaviors can read/write without knowing each other

**Access Patterns:**

```gdscript
# Read from blackboard
func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary):
    var grounded: bool = blackboard.get("is_grounded", false)

# Write to blackboard
    blackboard["last_jump_time"] = Time.get_ticks_msec()

# Read in conditions
func _evaluate(actor: Node, blackboard: Dictionary) -> bool:
    return blackboard.get("inputs", {}).get("jump", false)
```

---

## Common Patterns

### 1. Basic Movement State Machine

```
PlayerRoot (RecursiveState)
├─ Grounded (RecursiveState)
│   ├─ Idle (RecursiveState)
│   │   └─ activation_conditions: [NotMovingCondition]
│   └─ Run (RecursiveState)
│       └─ activation_conditions: [IsMovingCondition]
└─ Air (RecursiveState)
    ├─ Jump (RecursiveState)
    │   └─ activation_conditions: [JumpJustPressedCondition]
    └─ Fall (RecursiveState)
        └─ activation_conditions: [NotGroundedCondition, NotJumpingCondition]
```

**Priority Logic:**
- If grounded and not moving → `Idle`
- If grounded and moving → `Run`
- If not grounded and jump pressed → `Jump`
- If not grounded and not jumping → `Fall`

### 2. Combat State Machine with Locks

```
CombatRoot (RecursiveState)
├─ Idle (RecursiveState)
│   └─ activation_conditions: [NoCombatActionCondition]
├─ Attack (RecursiveState)
│   ├─ LightAttack (RecursiveState)
│   │   ├─ behavior: LightAttackBehavior
│   │   ├─ activation_conditions: [LightAttackPressedCondition]
│   │   └─ is_locked: true
│   └─ HeavyAttack (RecursiveState)
│       ├─ behavior: HeavyAttackBehavior
│       ├─ activation_conditions: [HeavyAttackPressedCondition]
│       └─ is_locked: true
└─ Dodge (RecursiveState)
    ├─ behavior: DodgeBehavior
    └─ activation_conditions: [DodgePressedCondition]
```

**Priority Logic:**
- `Idle` is the lowest priority (default)
- Attacks override Idle (higher priority)
- Dodge overrides attacks (highest priority) because it's lower in the tree

**Lock Behavior:**
- During `LightAttack` or `HeavyAttack`, `is_locked = true`
- Parent (`CombatRoot`) checks `is_hierarchy_locked()` before switching
- Result: Cannot interrupt attacks unless Dodge (which has even higher priority)

### 3. Deep Hierarchy Example

```
Root
└─ Movement (RecursiveState)
    ├─ Grounded (RecursiveState)
    │   └─ Walk (RecursiveState)
    │       ├─ NormalWalk (RecursiveState)
    │       └─ Sprint (RecursiveState)
    └─ Air (RecursiveState)
        ├─ Jump (RecursiveState)
        └─ Fall (RecursiveState)
            └─ FastFall (RecursiveState)
```

**Activation Flow:**
1. `Root` evaluates children → Selects `Movement` or other
2. `Movement` evaluates → Selects `Grounded` or `Air`
3. `Grounded` evaluates → Selects `Walk`
4. `Walk` evaluates → Selects `NormalWalk` or `Sprint`

Each level operates independently based on its own conditions.

---

## Testing Strategy

### Test Architecture

**Files:**
- `Scripts/Tests/HFSMTestHarness.gd` - Test infrastructure
- `Scripts/Tests/AtomicTransitionStressTest.gd` - Priority and transition tests
- `Scripts/Tests/HierarchyBlockingStressTest.gd` - Lock and hierarchy tests
- `Scripts/Tests/AnimationIntegrationTest.gd` - Animation sync tests
- `Scripts/Tests/MainTestRunner.gd` - Test coordinator

### Key Test Cases

#### 1. Priority Order Test

**File:** `AtomicTransitionStressTest.gd` - Line 50

Tests that "last in list = highest priority":
```gdscript
# Create: State1, State2, State3 (all active, no conditions)
# Expected: State3 becomes active (last in list)
```

#### 2. Lock Propagation Test

Tests that locks prevent transitions at any level:
```gdscript
# Deep hierarchy with locked state in middle
# Expected: Cannot transition from child or parent of locked state
```

#### 3. History Resume Test

Tests that `has_history` saves and restores the active child:
```gdscript
# Set: Grounded > Run (has_history = true)
# Exit: Grounded (saves Run)
# Re-enter: Grounded (should resume Run)
```

---

## Best Practices

### DO ✅

1. **Use `node.memory` for state-specific data**
   ```gdscript
   node.memory["timer"] = delta
   ```

2. **Keep Behaviors stateless**
   ```gdscript
   func update(node: RecursiveState, ...):
       # Use node.memory, not instance variables
   ```

3. **Use descriptive state names**
   - ✅ `Idle`, `Run`, `Combat`, `Air`
   - ❌ `State1`, `State2`, `State3`

4. **Lower states = higher priority in the Scene Tree**
   - Put high-priority states lower in the Inspector
   - Makes priority visually obvious

5. **Use Conditions for transitions**
   - Let the parent state select children based on conditions
   - Don't manually call `change_active_child()` unless necessary

### DON'T ❌

1. **Don't store state in Behaviors**
   ```gdscript
   class_name BadBehavior extends StateBehavior
   var timer: float = 0.0  # ❌ Shared across all instances!
   ```

2. **Don't create circular dependencies**
   - State A references State B, State B references State A
   - Use blackboard for shared data instead

3. **Don't skip the hierarchy**
   - Don't jump from a deep child to a sibling's deep child
   - Use `change_active_child()` at the appropriate parent level

4. **Don't forget to unlock**
   - If you set `is_locked = true`, remember to clear it
   - Use the behavior lifecycle (enter/exit) to manage locks

---

## Troubleshooting

### State Not Activating

**Symptom:** A state never becomes active even when conditions are true.

**Checklist:**
1. Is the state lower in the Scene Tree than its siblings? (Priority)
2. Are `activation_conditions` set correctly?
3. Is `activation_mode` (AND/OR) correct for the logic?
4. Is a sibling state with higher priority also active?

### State Locking In

**Symptom:** Stuck in a state, can't transition out.

**Checklist:**
1. Is `is_locked` true on the current state?
2. Is `is_hierarchy_locked()` true due to a child lock?
3. Did you forget to clear `is_locked` in `exit()`?

### Memory Issues

**Symptom:** Shared data between state instances.

**Checklist:**
1. Are you storing variables in `StateBehavior` instead of `node.memory`?
2. Are you using the same `StateBehavior` resource on multiple nodes?

---

## Performance Considerations

### State Evaluation Overhead

Each frame, the HFSM evaluates all children at each level.

**Optimization:**
- Keep state trees reasonably shallow (3-5 levels is typical)
- Avoid hundreds of sibling states (10-20 is typical)
- Use efficient conditions (avoid expensive checks in `_evaluate()`)

### Memory Management

The `node.memory` Dictionary is cleared on state entry.

**Best Practices:**
- Clean up resources in `exit()` if needed
- Use weak references for large objects if needed
- Don't accumulate data indefinitely

---

## Editor Integration

### Inline Editing

Flow HFSM provides a custom Inspector plugin (`hfsm_inspector.gd`) that:

- Displays Behavior and Condition properties directly on the Node
- Eliminates "Sub-Resource Click" fatigue
- Shows all relevant settings at a glance

### Scene Tree Visualization

The Scene Tree shows the hierarchy clearly:

```
PlayerRoot (RecursiveState)
├─ Grounded (RecursiveState)
│   ├─ Idle (RecursiveState)
│   └─ Run (RecursiveState)
└─ Air (RecursiveState)
    ├─ Jump (RecursiveState)
    └─ Fall (RecursiveState)
```

**Visual Priority:** Lower nodes are visually lower → intuitively "heavier" (higher priority).

---

## API Quick Reference

### RecursiveState

#### Key Functions

```gdscript
func process_state(delta: float, actor: Node, blackboard: Dictionary) -> void
func enter(actor: Node, blackboard: Dictionary) -> void
func exit(actor: Node, blackboard: Dictionary) -> void
func can_activate(actor: Node, blackboard: Dictionary) -> bool
func change_active_child(new_node: RecursiveState, actor: Node, blackboard: Dictionary) -> void
func is_hierarchy_locked() -> bool
func get_active_hierarchy_path() -> Array[String]
```

#### Key Variables

```gdscript
var behavior: StateBehavior
var activation_conditions: Array[StateCondition]
var activation_mode: int
var is_starting_state: bool
var has_history: bool
var is_locked: bool
var active_child: RecursiveState
var parent: RecursiveState
var memory: Dictionary
```

### StateBehavior

#### Virtual Functions

```gdscript
func enter(node: RecursiveState, actor: Node, blackboard: Dictionary) -> void
func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary) -> void
func exit(node: RecursiveState, actor: Node, blackboard: Dictionary) -> void
```

#### Variables

```gdscript
@export var animation: String = ""
```

### StateCondition

#### Virtual Functions

```gdscript
func _evaluate(actor: Node, blackboard: Dictionary) -> bool
func evaluate(actor: Node, blackboard: Dictionary) -> bool  # Public wrapper
```

#### Variables

```gdscript
@export var reverse_result: bool = false
```

---

## Version History

### v1.0.0 (2025-01-08)
- Initial documentation
- Fixed misleading comment about priority order (was "first", corrected to "last")
- Documented Scene Tree priority mechanism
- Comprehensive API reference

---

## Appendix: Priority System FAQ

**Q: Why is priority "last wins" instead of "first wins"?**

A: This mirrors Godot's Scene Tree rendering where lower nodes render on top (higher z-order). It also makes priority visually intuitive in the Inspector - lower position = higher priority.

**Q: Can I change the priority order?**

A: Yes! Simply reorder child states in the Scene Tree (Inspector). Drag a state lower to increase its priority.

**Q: What if two states have the same conditions?**

A: The one lower in the tree wins. This is by design - you can think of it as a "fallback" system. The higher states are defaults, overridden by lower states.

**Q: How do I make a state unconditionally activate?**

A: Leave `activation_conditions` empty. `can_activate()` returns `true` automatically when there are no conditions.

**Q: Can I have a state that never activates?**

A: Yes, set `activation_conditions` to conditions that are never true (e.g., `reverse_result = true` on a condition that returns `false`).

---

## Contact & Support

For issues, questions, or contributions, refer to the project repository or documentation.

**Remember:** The Scene Tree order is your primary tool for managing state priority. Lower = Higher Priority!
