# Godot Common Tooling Mistakes & Solutions

A log of recurring pitfalls encountered during development, specifically regarding AI tooling and Godot engine quirks.

## 1. The ".tscn Text Edit" Trap
* **Mistake:** Attempting to edit `.tscn` files directly as text to change properties or swap resources.
* **Consequence:** File corruption, broken UIDs, lost node connections, and syntax errors due to Godot's specific serialization format.
* **Solution:** **Never text-edit a .tscn file.**
    * Use a `@tool` script to `load()`, `instantiate()`, modify, and `ResourceSaver.save()` the scene.
    * Example: `scripts/upgrade_scene.gd`.

## 2. The "Forward" Confusion (-Z vs +Z)
* **Mistake:** Assuming `Vector3(0, 0, 1)` is Forward.
* **Fact:** In Godot, **Forward is Negative Z (`Vector3(0, 0, -1)`)**.
* **Symptom:** Character faces the camera when walking away, or "moonwalks."
* **Fix:**
    * Ensure imported GLTF/FBX models are rotated 180° Y if they were authored facing +Z.
    * Use `Basis.looking_at(direction)` correctly (it aligns -Z to `direction`).

## 3. The "Resource Hell" Anti-Pattern
* **Mistake:** Creating a separate `.tres` file for every single variable to achieve "Type Safety" (e.g., `Key_Speed.tres`, `Key_Jump.tres`).
* **Consequence:** Project clutter, massive friction when adding new variables, "Project Fatigue."
* **Solution:** Use **Embedded Resources** (Value Suppliers).
    * Create a generic resource (e.g., `ValueFloat`) that can be instantiated *inside* the Inspector slot.
    * It handles the logic (Const vs Blackboard vs Property) internally.

## 4. The "Smart Controller" Fallacy
* **Mistake:** Putting gameplay logic (speed calculations, state management) inside `PlayerController.gd`.
* **Consequence:** The HFSM becomes redundant, animation syncing becomes a nightmare of "check if velocity > 0.1", and code is scattered.
* **Solution:** **Hardware Abstraction.**
    * Controller only reports: "Button A is held."
    * HFSM Behavior (Move) reads that and decides: "Speed is 10."

## 5. Typed Array (`Array[T]`) Serialization
* **Mistake:** Assigning a generic `[]` to a typed export `@export var items: Array[MyResource]`.
* **Consequence:** Runtime errors or Editor warnings about type mismatch.
* **Solution:** Use `.clear()` on the existing array or explicit casting `Array[MyResource]([])`.

## 6. The "Get Node" Frame Killer

    Mistake: Calling get_node() or get_path() inside _process() or heavily used get_value() functions.

    Consequence: Instant performance death. O(depth) operations running 60 times/sec per entity.

    Solution: Cache your nodes.

        Always use _cached_node variables.

        Check is_instance_valid(_cached_node) before fetching.

        Only call get_node() on cache miss.
