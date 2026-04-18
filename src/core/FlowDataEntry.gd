@tool
class_name FlowDataEntry extends Resource

## A single key-binding pair for the data map.
## Maps a named key to a FlowBinding that resolves to a value.

@export var key: StringName = &""
@export var binding: FlowBinding
