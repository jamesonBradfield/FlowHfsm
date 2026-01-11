# Flow HFSM

**Flow HFSM** (Hierarchical Finite State Machine) is a recursive, resource-based state machine system for Godot 4. Designed for complex character controllers, AI behavior, and animation systems with automatic priority-based transitions.

**Version:** 1.0.0

---

## 🚀 Key Features

- **Recursive Hierarchy:** States can contain other states. Build deep, nested logic trees effortlessly.
- **Resource-Based Logic:** Behaviors are reusable Resources. Write once, use everywhere.
- **Priority-Based Transitions:** No wiring spaghetti. Child states are evaluated in order; the last valid state wins.
- **Automatic State Selection:** Parents automatically select the best child based on conditions.
- **Blackboard System:** Decoupled data sharing via a generic Dictionary passed through the hierarchy.
- **Inline Editor:** Custom Inspector tools allow editing behaviors and conditions directly on nodes.
- **Locking & History:** Prevent interruptions or resume state automatically on re-entry.

---

## 📦 Installation

1. Copy the `addons/FlowHFSM` folder into your project's `addons/` directory.
2. Go to **Project > Project Settings > Plugins**.
3. Enable **Flow HFSM**.

---

## ⚡ Quick Start

### 1. Scene Setup

Create the basic HFSM structure on your character:

```
CharacterBody3D
├─ PhysicsManager (Node - Component)
├─ PlayerController (Node - Driver)
└─ RootState (RecursiveState - Container)
   ├─ Idle (RecursiveState)
   └─ Run (RecursiveState)
```

**Steps:**
1. Add `RecursiveState` as a child of your `CharacterBody3D`. Rename it to `RootState`.
2. In `PlayerController`, assign `root_state` to `RootState` and `physics_manager` to `PhysicsManager`.

### 2. Defining States

**Add Child States:**
- Under `RootState`, add child `RecursiveState` nodes.
- Name them clearly (e.g., `Idle`, `Run`, `Jump`).

**Assign Behaviors (The "What"):**
1. Create a new `StateBehavior` resource (e.g., `BehaviorMove.tres`).
2. Assign it to the `Behavior` slot in the State's Inspector.
3. *Example:* `Run` state uses `BehaviorMove` with `speed = 8.0` and `direction_source = INPUT`.

### 3. Transitions (The "When")

**Create Conditions:**
1. Create `StateCondition` resources (e.g., `is_grounded.tres`, `input_jump.tres`).
2. **Wire them up:**
   - Select a State node.
   - In the Inspector, expand `Activation Conditions`.
   - Add a Condition resource.
   - *Logic:* If the condition is met (and the state is higher priority), the system automatically switches to it.

### 4. Priority System (CRITICAL)

**The Rule:** In the Scene Tree, **lower nodes = higher priority**.

```
RootState
├─ Idle      (Low priority - First)
├─ Run       (Medium priority - Middle)
└─ Jump      (High priority - Last)
```

If all three states can activate, **Jump wins** because it's last in the list.

**To change priority:** Simply reorder states in the Scene Tree/Inspector.

### 5. Animation Sync

1. Add `HFSMAnimationController` node to your character.
2. Assign `animation_tree` and `root_state`.
3. Use an `AnimationNodeStateMachine` in your AnimationTree.
4. **Crucial:** Name Animation States exactly the same as your HFSM States (e.g., "Run", "Jump").
5. Map Blackboard keys to Animation Parameters (for BlendSpaces).

---

## 🧠 Mental Model

### The Three Pillars

| Component | Role | Description |
|-----------|------|-------------|
| **RecursiveState** | Container | The Node in the scene tree. Manages lifecycle, recursion, memory, and priority selection. |
| **StateBehavior** | Brain | A stateless Resource that defines "what" the state does. Reusable across entities. |
| **StateCondition** | Atom | A stateless Resource that returns true/false. Evaluated by the Parent to determine activation. |

### How It Works

1. **Driver** (`PlayerController`) polls input and calls `root_state.process_state()` every frame.
2. **Selector Logic:** Each state evaluates all children. The **last valid child** becomes active.
3. **Recursion:** The active state's behavior runs, then control passes down to its active child.
4. **Blackboard:** A shared Dictionary carries data (input, physics state, timers) through the entire hierarchy.

---

## ⚙️ Architecture Deep Dive

### RecursiveState (The Container)

The core node that holds everything together. Can act as both a state and a container for child states.

**Key Properties:**
- `behavior: StateBehavior` - The logic resource assigned to this state.
- `activation_conditions: Array[StateCondition]` - Requirements for this state to activate.
- `activation_mode: int` - AND or OR logic for combining conditions.
- `is_starting_state: bool` - Default child when parent is entered.
- `has_history: bool` - Resume active child on re-entry.
- `is_locked: bool` - Prevent parent from transitioning out.
- `memory: Dictionary` - Runtime data storage for the behavior.

**Lifecycle:**
```gdscript
enter(actor, blackboard)  # Clears memory, enters behavior, enters child
process_state(delta, actor, blackboard)  # Selects best child, updates behavior, recurses
exit(actor, blackboard)  # Exits child, exits behavior, clears child (unless has_history)
```

### StateBehavior (The Brain)

**CRITICAL:** Behaviors are **stateless**. Do NOT store variables in them!

**Why?** Resources are shared across all instances. If you store a timer in a Behavior, it will be shared by all states using that Behavior.

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

### StateCondition (The Atom)

A logic gate that returns true or false. Evaluated by the **Parent** to determine if a child should activate.

**Logic Modes:**
- `AND` (default): All conditions must be true.
- `OR`: At least one condition must be true.

**Reverse Result:**
The `reverse_result` flag inverts the condition's output (acts as a NOT gate).

---

## 🔒 Advanced Features

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

1. Exit `Grounded` → Saves `active_child = Idle` in memory
2. Enter `Air` state (transition to jump/fall)
3. Return to `Grounded` → Resumes `Idle` automatically

**Without history:** Returns to the starting child (defined by `is_starting_state`).

---

## 📝 Common Patterns

### Basic Movement State Machine

```
PlayerRoot
├─ Grounded
│  ├─ Idle      [NotMovingCondition]
│  └─ Run       [IsMovingCondition]
└─ Air
   ├─ Jump      [JumpJustPressedCondition]
   └─ Fall      [NotGroundedCondition]
```

### Combat with Locks

```
CombatRoot
├─ Idle
├─ Attack
│  ├─ LightAttack  [is_locked: true]
│  └─ HeavyAttack  [is_locked: true]
└─ Dodge
```

**Priority Logic:**
- `Idle` is lowest priority (default)
- Attacks override Idle (higher priority)
- Dodge overrides attacks (highest priority) because it's lower in the tree

**Lock Behavior:**
- During `LightAttack` or `HeavyAttack`, `is_locked = true`
- Parent checks `is_hierarchy_locked()` before switching
- Result: Cannot interrupt attacks unless Dodge (which has even higher priority)

---

## ✅ Best Practices

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

## 🐛 Troubleshooting

### State Not Activating

**Symptom:** A state never becomes active even when conditions are true.

**Checklist:**
1. Is the state **lower** in the Scene Tree than its siblings? (Priority)
2. Are `activation_conditions` set correctly?
3. Is `activation_mode` (AND/OR) correct for the logic?
4. Is a sibling state with **higher priority** also active?

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

## 📚 Further Reading

For comprehensive architecture details, API reference, and testing strategies, see:
- **[REFERENCE.md](addons/hfsm_editor/REFERENCE.md)** - The complete architecture reference

---

## 🎯 Example Resources

The plugin includes example behaviors and conditions to help you get started:

### Behaviors (`Resources/behaviors/`)
- `run.tres` - Movement behavior with speed settings
- `jump.tres` - Impulse behavior for jumping

### Conditions (`Resources/conditions/`)
- `is_grounded.tres` - Checks if character is on floor
- `is_moving.tres` - Checks if input magnitude > threshold
- `input_jump.tres` - Checks if jump action is pressed
- `is_airborne.tres` - Inverted grounded check
- `not_moving.tres` - Inverted movement check
- `input_jump_just_pressed.tres` - Frame-perfect jump input

These are **examples** - you can create your own by extending `StateBehavior` or `StateCondition` classes.

---

## 📄 License

See project repository for license details.

---

**Remember:** The Scene Tree order is your primary tool for managing state priority. **Lower = Higher Priority!**

## 🛠️ Editor Tools

Flow HFSM includes a custom Inspector plugin (`hfsm_inspector.gd`) to improve quality of life.

*   **Inline Editing:** Instead of clicking into a Resource to edit its properties, the Inspector displays Behavior and Condition properties *inline*.
*   **Context:** See everything at a glance without navigating back and forth between sub-resources.
