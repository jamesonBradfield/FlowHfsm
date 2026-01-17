📜 FlowHFSM Architecture Rules
1. The "Driver" Rule (No Magic Strings)

Principle: Systems must never rely on hardcoded strings to find data.

    🔴 Bad: blackboard.get_value("move_speed") inside a Behavior.

    🟢 Good: speed_input.get_value(actor) where speed_input is an exported ValueFloat.

    Why: Strings are invisible dependencies. Typed Resources (ValueFloat, ValueBool) make dependencies explicit, validating, and refactor-proof.

2. The "No Pollution" Rule (Embedded Resources)

Principle: Configuration data that is specific to a Scene must live inside that Scene.

    🔴 Bad: Creating Key_PlayerSpeed.tres, Key_EnemySpeed.tres, Key_BossSpeed.tres in the FileSystem.

    🟢 Good: Using New ValueFloat (Local-to-Scene) directly in the Inspector slot of the Behavior.

    Why: Reduces project clutter. External .tres files should be reserved only for data truly shared across multiple disparate scenes (e.g., global game settings).

3. The "Hardware Abstraction" Rule (Controller SRP)

Principle: The PlayerController reports Input Reality, not Game Logic.

    🔴 Bad: Controller calculating target_speed = 10.0 because the sprint button is held.

    🟢 Good: Controller reports is_sprinting = true. The Move State reads that and decides the speed is 10.0.

    Why: Keeps the HFSM as the "Brain." If the Controller does the thinking, the State Machine becomes a "Zombie" that just plays animations based on what the Controller already decided.

4. The "Inspector Test" Rule

Principle: Wiring systems together must be done via Drag-and-Drop or Dropdown selection.

    Rule: If a user has to type a string into the Inspector to link System A to System B, the feature is incomplete.

    Mechanism: Use NodePath exports for scene references, and Resource exports for data definitions.

5. Blackboard vs. Driver Distinction

Principle: Distinct uses for the Blackboard and Smart Values.

    Smart Values (Value<T>): Used for Inputs (Speed, Damage, Direction). Things that drive logic.

    Blackboard: Used for State Communication (Output). "I am currently attacking," "I was hit."

    Rule: Behaviors consume Smart Values and write to the Blackboard.
