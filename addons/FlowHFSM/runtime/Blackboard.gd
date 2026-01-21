class_name Blackboard extends RefCounted

const BlackboardKeyScript = preload("res://addons/FlowHFSM/runtime/BlackboardKey.gd")

## A shared data container for the HFSM.
## Wraps a Dictionary to provide a single source of truth for data.
## States can Read/Write. Transitions can Read.
## 
## REACTIVE: Emits signals when values change.
## TYPED: Supports BlackboardKey resources for validation.

signal value_changed(key: String, old_value: Variant, new_value: Variant)

var _data: Dictionary = {}

## Sets a value in the blackboard.
func set_value(key: String, value: Variant) -> void:
	var old_value: Variant = _data.get(key, null)
	if old_value == value:
		return
		
	_data[key] = value
	value_changed.emit(key, old_value, value)

## Sets a value using a BlackboardKey resource for validation.
func set_typed_value(key_res: Resource, value: Variant) -> void:
	if not key_res: return
	
	var name: String = key_res.get("key_name")
	var type: int = key_res.get("key_type")
	
	# Type validation
	if type != TYPE_NIL and typeof(value) != type:
		push_error("FlowHFSM: Type mismatch for BlackboardKey '%s'. Expected %d, got %d" % [name, type, typeof(value)])
		return
		
	set_value(name, value)

## Gets a value from the blackboard. Returns default if key not found.
func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)

## Gets a value using a BlackboardKey resource.
func get_typed_value(key_res: Resource) -> Variant:
	if not key_res: return null
	var name: String = key_res.get("key_name")
	var default: Variant = key_res.get("default_value")
	return get_value(name, default)

## Returns true if the key exists.
func has_value(key: String) -> bool:
	return _data.has(key)

## Removes a value from the blackboard.
func erase_value(key: String) -> void:
	if _data.has(key):
		var old_value: Variant = _data[key]
		_data.erase(key)
		value_changed.emit(key, old_value, null)

## Clears all data.
func clear() -> void:
	_data.clear()

## Returns the raw dictionary (Use carefully!).
func get_data() -> Dictionary:
	return _data
