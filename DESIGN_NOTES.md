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

**Cascading data through the hierarchy**
States transform data before passing it down to children. Interesting but
conflates control flow (what HFSM hierarchy is actually for) with data flow.
Raises hard questions: mutation vs. copy? Can children push data back up?
Starts feeling more like a behavior tree with a working memory stack than an
HFSM. Cool, different beast.

**Flat untyped blackboard with scoped string keys**
Drop the cascading idea. Keep one global dict, but scope keys by convention:
`player/health`, `input/jump`, `combat/last_hit_time`. States don't need to
know who wrote what, just read/write their keys. Works with GDScript's dynamic
nature instead of fighting it. Probably the right call for a Godot addon.

**Local vs global dict split**
Two dicts: global persists across states, local is created on `_enter` and
destroyed on `_exit`. Children read global, write local, explicitly promote to
global if a value needs to outlive the state. Limits blast radius.

**Optional typed schema (most promising)**
A `BlackboardSchema.tres` Resource maps string keys to expected Variant types:

```gdscript
entries = {
    "player/health": TYPE_FLOAT,
    "player/velocity": TYPE_VECTOR3,
    "input/jump": TYPE_BOOL,
}
```

`FlowHost` loads the schema and validates reads/writes via
`_get_configuration_warnings()` — mismatches surface as editor warnings, zero
runtime cost. Opt-in, so the simple case stays simple. This would make the
addon legitimately production-ready.

## Current verdict

Not recommended for production as-is. The blackboard coupling gets unmanageable
as the machine grows. The typed schema approach is the cleanest next step if
this gets revisited.
