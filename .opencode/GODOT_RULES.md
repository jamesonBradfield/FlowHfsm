# Godot & GDScript Project Rules

## Core Principles
- **Version:** Godot 4.x
- **Style:** Use snake_case for variables/functions, PascalCase for classes/nodes.
- **Typing:** STRICT static typing is required. Always use `:=` for inferred types or explicit `: Type` definitions.
- **Performance:** Avoid `_process` and `_physics_process` unless absolutely necessary. Use signals.

## GDScript Syntax Preferences
1. **Static Typing:**
   - BAD: `var health = 100`
   - GOOD: `var health: int = 100` OR `var health := 100`
   - ARRAYS: Use typed arrays: `var enemies: Array[Node3D] = []`

2. **Signals:**
   - Connect signals in code via `_ready()`, not the editor UI, to keep logic searchable.
   - Naming: `signal health_changed(new_value: int)`

3. **Classes:**
   - Use `class_name` at the top of script files to make them globally accessible in the editor.

## Common Patterns
- **Composition:** Prefer small, single-responsibility components (Nodes) over deep inheritance trees.
- **Paths:** Use `release` export variables for node paths rather than hardcoded strings (e.g., `@export var player_path: NodePath`).

## ⚠️ Environment Specifics (Neovim / Godot LSP)
**Context:** The user is working in Neovim where the Godot LSP connection is unstable or fails to report diagnostics due to single-client limitations.

**Instructions for AI:**
1. **Do not trust "No Errors":** Just because the LSP returns no errors does not mean the code is safe.
2. **Double Check imports:** Verify `class_name` usage manually, as the LSP might not auto-resolve them in this environment.
3. **Diagnostic Fallback:** If you suspect a syntax error, try to `read` the file content again rather than asking the LSP for diagnostics.
