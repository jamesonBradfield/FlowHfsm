# FlowHfsm — Design Notes

Rough notes on where the architecture landed and where it could go.

## What the current implementation does

Shared `data: Dictionary` (blackboard) passed through the state hierarchy.
Behaviors write to it, conditions read from it. `FlowHost` owns the dict and
drives the walk each frame.

## The problem

The dict is an untyped global blackboard with no enforcement. Any behavior can
write any key, any condition can read any key — implicit coupling that's
invisible until something breaks, and no type safety to help find it.

## Ideas explored

### Cascading data through the hierarchy
States transform data before passing it down to children. Interesting but
conflates control flow (what HFSM hierarchy is actually for) with data flow.
Raises hard questions: mutation vs. copy? Can children push data back up?
Starts feeling more like a behavior tree with a working memory stack than an
HFSM. Cool, different beast.

### Flat untyped blackboard with scoped string keys
Drop the cascading idea. Keep one global dict, but scope keys by convention:
`player/health`, `input/jump`, `combat/last_hit_time`. States don't need to
know who wrote what, just read/write their keys. Works with GDScript's dynamic
nature instead of fighting it. Probably the right call for a Godot addon.

### Local vs global dict split
Two dicts: global persists across states, local is created on `_enter` and
destroyed on `_exit`. Children read global, write local, explicitly promote to
global if a value needs to outlive the state. Limits blast radius.

### Optional typed schema (most promising)
A `BlackboardSchema.tres` Resource maps string keys to expected Variant types.
Edited through a custom editor panel (rows of key/type/default) — you never
touch the `.tres` directly, same pattern as AnimationTree or TileSet.

`FlowHost` loads the schema and validates reads/writes via
[`_get_configuration_warnings()`](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-get-configuration-warnings) — mismatches surface as editor warnings, zero
runtime cost. Opt-in, so the simple case stays simple. This would make the
addon legitimately production-ready.

### Expression-based bindings (longer term)
Instead of static typed keys, entries could be GDScript expressions evaluated
via Godot's [`Expression`](https://docs.godotengine.org/en/stable/classes/class_expression.html) class — e.g.
`current_health = clampf(current_health, 0, damage_object.damage - current_health)`
or `spider_leg1.pos = spider_leg2.pos - xyz`. Dependencies are named variables,
NodePaths resolve to actual nodes. Similar to Blender's driver system.

The editor safety problem: there's no way to LSP-check a string export today,
but a `@tool` script could parse and dry-run expressions on save and surface
errors as warnings — catches syntax at least.

### Why expression bindings matter: LLM-assisted tuning
If behaviors are small isolated resources and the blackboard is named
expressions, you've created a search space a small local LLM can navigate.
"Adjust these expressions until the walk feels floaty" is tractable — the
model can read blackboard state and propose edits without touching behavior
logic. The architecture separates *what a state does* (stable, written once by
a human) from *how it's tuned* (malleable expressions, iterable by tooling).
A human stays in the loop because the expressions are readable, not an opaque
float array. Rapid iteration on character feel without rewriting controllers.

### Set/Get behaviors as the output layer
The blackboard is internal state only. `SetBehavior` and `GetBehavior` are the
boundary — they push blackboard values out to external nodes (AnimationPlayer,
CharacterBody, UI, anything with a property) each tick. External nodes never
write back into the machine. Unidirectional, state machine is the single source
of truth.

This keeps external nodes as dumb consumers. They don't need to know the state
machine exists, and the state machine doesn't need to know what's consuming it.
Similar to flux/redux — the machine owns the data, outside world just receives
what it's given.

## Current verdict

Not recommended for production as-is. The blackboard coupling gets unmanageable
as the machine grows. The typed schema approach is the cleanest next step if
this gets revisited.
