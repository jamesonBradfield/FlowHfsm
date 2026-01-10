class_name Blackboard extends RefCounted

## A shared data container for the HFSM.
## Wraps a Dictionary to provide a single source of truth for data.
## States can Read/Write. Transitions can Read.

var _data: Dictionary = {}

## Sets a value in the blackboard.
func set_value(key: String, value: Variant) -> void:
	_data[key] = value

## Gets a value from the blackboard. Returns default if key not found.
func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)

## Returns true if the key exists.
func has_value(key: String) -> bool:
	return _data.has(key)

## Removes a value from the blackboard.
func erase_value(key: String) -> void:
	_data.erase(key)

## Clears all data.
func clear() -> void:
	_data.clear()

## Returns the raw dictionary (Use carefully!).
func get_data() -> Dictionary:
	return _data
