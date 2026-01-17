description: Execute a standalone GDScript using the Godot headless runtime.
agent: godot-expert
Command: Run GDScript

Use this to test logic without launching the full game window.

Usage: /run_gd <path_to_script>

Execution Logic:

    Verify the Godot binary is in the PATH (or alias godot).

    Run: godot --headless --script <path_to_script>

    Capture stdout/stderr.