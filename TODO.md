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
* [ ] **Animation Sync:** Link `RecursiveState` active path to `AnimationTree` playback.
* [x] **First Playable:** Construct `Idle` -> `Run` -> `Jump` character.
* [x] **Add UndoRedo to UI/Plugin** allow UndoRedo in Custom UI.

###  Phase 5: Debugging/Unit testing.
* [ ] **Memory Debugging** find out why data is displayed as empty in statedebugger, this might just be us not utilizing the blackboard rn.
* [x] **Add Transitions button Error** TODO: add ERROR here
* [x] **Unified Themes for all custom Inspectors** Transition Custom inspector resizes smaller than Behavior Custom Inspector, we should look into a theme to unify both.
* [x] **Test Custom UI somehow** :shrug:
* [ ] **Build example scenes to test all functionality** not sure what test cases we need, but we can use gdunit to run these and simulate input for each case.


###  Phase 6: Generic Tool Creation to streamline code creation.
* [ ] **Creation API** build generic state creation api that can both be called via external tooling.
* [ ] **Default Godot Editor Tooling** build godot tooling to streamline state creation (text boxes that allow you to only write an "atomic if" statement for transitions/triggers avoiding writing boilerplate), (code syntax highlighting, lsp etc).
* [ ] **Custom nvim tooling for making states** I use nvim btw, so this is the final cherry on top.
