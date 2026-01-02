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

### 🔲 Phase 4: Integration & Visuals
* [ ] **Debug UI:** `StateDebugger` (Visualize Tree Path + Memory).
* [ ] **Animation Sync:** Link `RecursiveState` active path to `AnimationTree` playback.
* [ ] **First Playable:** Construct `Idle` -> `Run` -> `Jump` character.
