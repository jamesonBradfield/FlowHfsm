# Building a Character with Flow HFSM

## The 30-Second Pitch: Why HFSM for Game Jams?

In a game jam, **speed is everything**. Traditional FSMs often lead to "spaghetti wiring" or massive `match` statements that are hard to debug at 3 AM. 

**Flow HFSM** flips the script: your **Scene Tree IS your logic tree**. 
- **Rapid Prototyping:** Build your brain by dragging and dropping nodes.
- **Visual Clarity:** See exactly what your character is thinking just by looking at the active nodes in the remote debugger.
- **Extreme Reusability:** Write a "Jump" behavior once, and use it for players, enemies, and bouncing boxes.

---

## Core Concepts (5-Min Read)

To master Flow HFSM, you need to understand four pillars:

1.  **Scene Tree = State Hierarchy:** Your state machine is literally a collection of nodes. A `Grounded` node contains `Idle` and `Run` regardless of whether it transitions to another parent. This nesting allows for shared logic - anything under `Grounded` happens while the character is grounded.
2.  **States vs. Behaviors:** The node (`RecursiveState`) is the container. The **Behavior** is a scriptable Resource that defines what happens (Movement, Attacking).
3.  **Priority System:** Flow uses a "last-child-wins" approach by default. If both `Idle` and `Run` conditions are true, the one lower in the scene tree is selected.
4.  **Blackboard:** A shared data dictionary (`input_direction`, `is_on_floor`) passed through the hierarchy so states can talk to each other without being coupled.

> ⚠️ **PAIN POINT: The "Last-Wins" Counter-Intuition**
> Beginners often expect the *first* valid state to win (like a standard if/else). In Flow, the **last child** in the tree has the highest priority. If you want "Dodge" to override "Run", put "Dodge" below "Run" in the scene tree.
> **Severity:** Minor (requires mental shift)
> **SOLUTION:** Add an enum option to choose between "First-Wins" and "Last-Wins" logic. Low priority TODO item, but easy to implement.

---

## Step 1: Character Scene Setup (5 Minutes)

Every Flow character follows a "Three Pillar" architecture: **Driver, Brain, Motor**.

1.  **The Motor:** Create a `CharacterBody3D`. This handles the physical representation.
2.  **The Driver:** Add a `Node` called `PlayerController`. This polls input and updates the **Blackboard**.
3.  **The Brain:** Add a `RecursiveState` node named `RootState`.

### Minimal PlayerController Example
```gdscript
class_name PlayerController extends Node

@export var root_state: RecursiveState
var blackboard := Blackboard.new()

func _process(delta: float) -> void:
    # 1. Update Blackboard with inputs
    blackboard.set_value("input_direction", Input.get_vector("left", "right", "up", "down"))
    blackboard.set_value("jump_just_pressed", Input.is_action_just_pressed("jump"))
    
    # 2. Drive the Brain
    if root_state:
        root_state.process_state(delta, owner, blackboard)
```

> ⚠️ **PAIN POINT: Boilerplate for Every Component**
> You have to manually wire the `PlayerController` to the `RootState` and ensure the `Blackboard` keys match what your conditions expect. Setting up a new character means creating multiple nodes and wiring them together manually.
> **Severity:** Moderate (Slows down initial setup)
> **SOLUTION:** A creation tool script that automates the tedious stuff. Could generate the full character skeleton (CharacterBody3D + PlayerController + PhysicsManager + RootState + HFSMAnimationController) with all connections pre-made. One click → ready character.

---

## Step 2: Build State Hierarchy (3 Minutes)

This is where the magic happens. Instead of drawing lines in a graph, you structure your nodes.

### Scene Tree Structure
```text
RootState (RecursiveState)
 ├── Grounded (RecursiveState)
 │   ├── Idle (RecursiveState)
 │   ├── Walk (RecursiveState)
 │   └── Jump (RecursiveState) - Applies upward force, auto-exits Grounded
 └── Air (RecursiveState)
      ├── Idle (RecursiveState) - Copied from Grounded (air strafing)
      └── Walk (RecursiveState) - Copied from Grounded (air strafing)
```

### KEY CONCEPT: Hierarchy IS Your Logic Tree

Think of it this way: **Leaf states = "What you're trying to do", Container states = "What context you're in"**

```
Grounded (RecursiveState) - Context: Character is on ground
 ├── Idle (RecursiveState) - Leaf: Not trying to move
 ├── Walk (RecursiveState) - Leaf: Trying to move
 └── Jump (RecursiveState) - Leaf: Trying to jump (applies upward force, exits Grounded)

Air (RecursiveState) - Context: Character is airborne
 ├── Idle (RecursiveState) - Leaf: Copied from Grounded (air strafing)
 └── Walk (RecursiveState) - Leaf: Copied from Grounded (air strafing)
```

**How it works in practice:**
- `Idle` and `Walk` are **copied** to both `Grounded` and `Air` - same logic, different contexts
- `Jump` lives under `Grounded` - it's a grounded action that makes you airborne
- Jump's behavior applies upward force, which makes `is_grounded = false`
- HFSM automatically transitions from `Grounded` → `Air` when grounded condition fails
- Once in `Air`, the copied `Idle`/`Walk` states handle movement (air strafing)

**Benefit:** Copy leaf states to any container to "try" that functionality in that context.

**Benefit:** You can organize logic by condition (grounded vs airborne) and reuse states across different contexts. The hierarchy reflects your character's logical structure.

---

## Step 3: Add State Behaviors (10 Minutes per Behavior)

Behaviors are **Stateless Resources**. This means one `JumpBehavior.tres` file can be used by 100 different enemies.

### BehaviorAttack Example
```gdscript
class_name BehaviorAttack extends StateBehavior

@export var duration: float = 0.5

func enter(node: RecursiveState, _actor: Node, _blackboard: Blackboard) -> void:
    # ✅ CORRECT: Use node.memory for instance-specific data
    node.memory["timer"] = 0.0
    node.is_locked = true # Prevent switching states until done

func update(node: RecursiveState, delta: float, _actor: Node, _blackboard: Blackboard) -> void:
    node.memory["timer"] += delta
    if node.memory["timer"] >= duration:
        node.is_locked = false # Release the lock
```

> ⚠️ **PAIN POINT: Stateless Behavior Trap (node.memory)**
> You **cannot** use member variables (like `var timer = 0.0`) in a Behavior script. Because it's a Resource, that variable would be shared across every character using that behavior. You **must** use `node.memory`.
> **Severity:** **HIGH** (Causes extremely confusing bugs if forgotten)
> **SOLUTION:** Transitions/conditions as **expressions** working on blackboard data. If done right, this allows state variables/blackboard data to be used everywhere without accessing blackboard via script. The expression engine would parse `blackboard.velocity.length() > 0.1` directly, making conditions much more powerful and less error-prone.

> ⚠️ **PAIN POINT: String Keys in Memory (No Autocomplete)**
> `node.memory["timer"]` is prone to typos and lacks IDE autocomplete.
> **WORKAROUND:** Use a `Constants.gd` script or local constants to manage keys.
> **SOLUTION:** Expression-based transitions would eliminate string keys entirely - you'd reference blackboard variables directly in expressions like `timer > duration`.

### The Constants Workaround
```gdscript
# BB.gd (Autoload or Static Class)
class_name BB
const INPUT_DIR = "input_direction"
const IS_MOVING = "is_moving"
const ATTACK_TIMER = "attack_timer"

# Then use: node.memory[BB.ATTACK_TIMER]
```

---

## Step 4: Add State Conditions (5 Minutes per Condition)

Conditions are the "Gates" that allow a state to activate. They are also Resources attached to nodes.
 
### Generic Condition Example (ConditionFloatCmp)

**Old Way (Deleted):**
```gdscript
class_name ConditionIsMoving extends StateCondition

func _evaluate(_actor: Node, blackboard: Blackboard) -> bool:
    var input = blackboard.get_value("input_direction", Vector2.ZERO)
    return input.length() > 0.1
```

**New Way (Generic):**
Use `ConditionFloatCmp` with two ValueFloat resources:
- **value_a**: Set to input_direction (Blackboard mode)
- **value_b**: Set to constant 0.1
- **operator**: GREATER

No code required! Just configure in Inspector.

> ✅ **SHARP KNIVES: Zero Gameplay Logic in GDScript**
> All logic belongs in the Inspector. Use generic conditions/behaviors:
> - `ConditionFloatCmp`: Compare any two numbers
> - `ConditionBoolCmp`: Compare any two booleans
> - `ConditionInput`: Check any input action
> - `BehaviorSetProperty`: Set any property on any node
>
> **No more custom scripts for simple logic!**
> To create one condition or behavior, you need to: Create Script → Save Script → Create Resource → Assign Script to Resource → Assign Resource to Node. Multiply this by dozens of states and it becomes tedious.
> **Severity:** Moderate (Slows down iteration)
> **SOLUTION:** Editor tooling that streamlines this process. Could include:
> - "Create State from Template" right-click menu option
> - Inline behavior/condition creation directly in inspector (no separate resource file)
> - Expression-based conditions that don't require separate script files
> - Resource duplication shortcuts with smart renaming

---

## Step 5: Animation Integration (3 Minutes)

The `HFSMAnimationController` node automates the link between logic and visuals.

1.  Add `HFSMAnimationController` to your character.
2.  Assign your `AnimationTree` and `RootState`.
3.  **Convention:** Name your states in the `AnimationNodeStateMachine` exactly the same as the nodes in your HFSM (e.g., node `Run` -> animation state `Run`).

> ⚠️ **PAIN POINT: String-Based Name Matching**
> If you rename a node in the scene tree (e.g., `Run` to `Sprinting`), your animation will stop playing unless you also rename the state in the `AnimationTree`. This convention-based coupling is fragile.
> **Severity:** Moderate (Maintenance burden)
> **SOLUTION:** Editor tooling that provides explicit mapping between HFSM states and AnimationTree states. Instead of relying on name matching, you'd have a dictionary/property editor to map `RecursiveState` → `AnimationState`. Renaming either side would auto-update the mapping.

---

## Step 6: Put It All Together (Full Example)

Imagine a **Walk → Jump → Air Strafing** sequence:

1.  **Frame 1 (Walking):** `Grounded` is valid. `Walk` is valid (input present). `Walk` wins priority over `Idle`.
2.  **Frame 2 (Press Jump):** `PlayerController` sets `jump_just_pressed = true`. `Jump` state (under Grounded) activates.
3.  **Frame 3 (Jump Executes):**
    *   `Jump` behavior applies upward force to character
    *   This makes `is_grounded = false`
    *   `Grounded` condition fails, HFSM automatically transitions to `Air`
4.  **Frame 4 (Airborne):**
     *   Now in `Air` container, `Idle` activates (default state)
     *   Player presses walk direction
     *   `Walk` (copied from Grounded to Air) activates - **air strafing!**
     *   Same `Walk` behavior works in both contexts

**Key Flow:**
- Jump is a **grounded action** that makes you airborne
- Once airborne, **copied leaf states** (`Idle`, `Walk`) handle input
- No need to write "AirWalk" or "AirIdle" - just copy grounded states

> **Future Enhancement:** If you want granular air physics (Rise/Apogee/Fall), each would need its own `Idle`/`Walk` copies. For now, keep it simple with a single `Air` container.

> ⚠️ **PAIN POINT: O(n) Child Evaluation Cost**
> Every frame, every child of the active parent is evaluated. If you have 50 states at the same level, it checks 50 conditions every frame.
> **Optimization:** Keep hierarchies deep rather than wide. 3 parents with 3 children each is faster than 1 parent with 9 children.
> **Severity:** Minor for jams (Only becomes issue with extreme complexity)
> **SOLUTION:** Could add optimizations like:
> - Gate states that skip branch evaluation when disabled
> - Condition caching for expensive checks
> - Early exit when high-priority state is found (for first-wins mode)
> - **Reality:** For game jams, this is a non-issue until it becomes one. Not worth pre-optimizing for jam use case.

---

## Advanced Features

### State Locking
Setting `node.is_locked = true` is your best friend for attacks. It tells the parent: "Do not switch away from me, no matter what happens."
> ⚠️ **PAIN POINT:** You must manually clear `is_locked`. If your attack script crashes or exits early, your character will be stuck forever.

### History
Enable `has_history` on a parent (like `Grounded`) so it remembers if it was in `Idle` or `Walk` when it returns from the `Air` state. This way, after landing from a jump, you automatically resume walking instead of defaulting to Idle.

---

## Game Jam Cheat Sheet

### Quick Start Checklist
- [ ] `CharacterBody3D` setup with `PlayerController` and `RootState`.
- [ ] `PlayerController` calls `root_state.process_state()` in `_process`.
- [ ] Hierarchy structured by priority (highest priority = bottom).
- [ ] All logic in `StateBehavior` uses `node.memory`.
- [ ] `HFSMAnimationController` node added for visual sync.

### Troubleshooting Guide
| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| State won't trigger | Priority | Move the state lower in the Scene Tree. |
| Character stuck | Lock | Check if `is_locked` was ever set to `false`. |
| Variables "leak" | Stateless Trap | Move variable to `node.memory`. |
| Animation won't play | Naming | Match Node name to AnimationTree state name. |

---

## Appendix: Pain Points Deep Dive

| Pain Point | Category | Severity | Solution |
|------------|----------|----------|------------|
| **Stateless Trap** | Logic | **Critical** | **Expression-based transitions** - Let conditions be expressions working on blackboard data (`blackboard.velocity.length() > 0.1`) instead of scripts. Eliminates need for node.memory string keys. |
| **Last-Wins Priority** | Concept | Minor | **Enum selector** - Add dropdown to choose "First-Wins" or "Last-Wins" logic. Low priority TODO item, but trivial to implement. |
| **Boilerplate** | Workflow | Moderate | **Creation tool script** - One-click character skeleton generator that creates CharacterBody3D + PlayerController + PhysicsManager + RootState + HFSMAnimationController with all connections pre-made. |
| **String Keys** | UX | Moderate | **Expression engine** - Reference blackboard variables directly in expressions like `timer > duration`. No more string-based memory access. |
| **Script + Resource Boilerplate** | Workflow | Moderate | **Editor tooling** - Inline behavior/condition creation, template system, resource duplication with smart renaming. |
| **String-Based Animation Matching** | UX | Moderate | **Explicit mapping editor** - Dictionary/property UI to map RecursiveState → AnimationState instead of relying on name matching. |
| **Manual Lock Cleanup** | Safety | Moderate | Use `try/finally` patterns or clear locks on `exit()`. |
| **O(n) Evaluation** | Performance | Minor | **Not a jam issue** - Only matters with extreme complexity. Could add gates/caching if needed later. |

### Priority for Solutions

**High Priority (Biggest Impact for Jams):**
1. Creation tool script - Removes setup friction
2. Expression-based conditions - Eliminates script boilerplate

**Medium Priority:**
3. Explicit animation mapping - Prevents rename bugs

**Low Priority (Nice to Have):**
4. Priority logic enum - Minor UX improvement
5. Evaluation optimizations - Not needed until it's a problem
