extends AnimationTree
class_name MockAnimationTree

## Mock AnimationTree for testing HFSM integration.
## Returns a MockPlayback object when "parameters/playback" is requested.

var mock_playback

func _init() -> void:
	mock_playback = load("res://Scripts/Tests/Mocks/MockPlayback.gd").new()
	active = true

var set_properties: Dictionary = {}

func _get(property: StringName):
	if property == "parameters/playback":
		return mock_playback
	if set_properties.has(property):
		return set_properties[property]
	return null

func _set(property: StringName, value: Variant) -> bool:
	set_properties[property] = value
	return true
