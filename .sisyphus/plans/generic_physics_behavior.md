# Plan: Generic Physics Behavior & PhysicsManager Upgrade

## 1. Goal
Create a robust, data-driven `BehaviorPhysics` resource that can replace bespoke behaviors like `BehaviorMove` or `BehaviorImpulse`. This behavior will interface with an upgraded `PhysicsManager` to apply forces, impulses, or direct velocity changes based on flexible inputs (Static, Node-relative, Blackboard, or Input).

## 2. Architecture Changes

### A. PhysicsManager Upgrade (`Examples/PhysicsManager.gd`)
We will move away from behaviors directly modifying `character.velocity`. The `PhysicsManager` will expose a clean API.

**New Methods:**
- `apply_impulse(vector: Vector3)`: Adds to current velocity immediately.
- `apply_force(vector: Vector3, delta: float)`: Adds `vector * delta` (for continuous acceleration).
- `set_planar_velocity(vector: Vector3)`: Overwrites X/Z velocity while preserving Y (gravity).
- `set_velocity(vector: Vector3)`: Overwrites full velocity (useful for zero-G or hard resets).

### B. Generic Behavior (`addons/FlowHFSM/presets/behaviors/BehaviorPhysics.gd`)
A new `StateBehavior` that calculates a final force vector and applies it via the new `PhysicsManager` API.

**Features:**
- **Operation Mode:** `Impulse`, `Constant Force`, `Set Velocity`.
- **Direction Source:** `Vector`, `Node`, `Input`, `Blackboard`.
- **Magnitude Source:** `Float`, `Blackboard`.
- **Reference Frame:** `World`, `Local`, `Camera/Node Relative`.

## 3. Implementation Steps

### Step 1: Update PhysicsManager
Modify `Examples/PhysicsManager.gd` to include the helper methods.
- Ensure strict typing.
- Ensure it still handles `move_and_slide()` in `_physics_process`.

### Step 2: Create BehaviorPhysics Resource
Create `addons/FlowHFSM/presets/behaviors/BehaviorPhysics.gd`.

**Properties:**
- `mode`: Enum (IMPULSE, FORCE, SET_VELOCITY)
- `magnitude`: Float
- `magnitude_blackboard_key`: String (Optional override)
- `direction_mode`: Enum (VECTOR, NODE_FORWARD, INPUT, BLACKBOARD_KEY)
- `direction_vector`: Vector3
- `direction_node_path`: String (Path to node for basis, e.g., "Camera3D")
- `space`: Enum (WORLD, LOCAL, RELATIVE_TO_NODE)

**Logic:**
1. **Resolve Magnitude:** Base `magnitude` + check blackboard/memory.
2. **Resolve Direction:**
   - If `VECTOR`: Use `direction_vector`.
   - If `NODE_FORWARD`: Get node from path, use `-node.global_transform.basis.z`.
   - If `INPUT`: Read `PlayerController.input_direction`.
   - If `BLACKBOARD_KEY`: Read Vector3 from blackboard.
3. **Apply Transform:** If `space` is LOCAL, rotate by Actor basis. If RELATIVE, rotate by Reference Node basis.
4. **Execute:** Call corresponding `PhysicsManager` method.

### Step 3: Integration & Testing
1. Create a test scene or update `CharacterBody3D` setup.
2. Replace `Jump` behavior (currently `BehaviorImpulse`) with `BehaviorPhysics` (Mode: Impulse, Dir: Up).
3. Replace `Move` behavior (currently `BehaviorMove`) with `BehaviorPhysics` (Mode: Set Velocity, Dir: Input).
   - *Note:* `BehaviorPhysics` will NOT handle rotation (looking at target). Keep `BehaviorMove` for complex locomotion or create a separate `BehaviorOrient` later. For now, we focus on the physics forces.

## 4. Verification
- **Jump:** Character should jump when state activates.
- **Move:** Character should slide when state activates.
- **Errors:** Graceful failure if Reference Node is missing or Blackboard key is invalid.

