class_name MockAnimationTree extends AnimationTree

## Mock AnimationTree for testing HFSM integration.
## Returns a MockPlayback object when "parameters/playback" is requested.

const MockPlaybackScript = preload("res://addons/FlowHFSM/tests/Mocks/MockPlayback.gd")

var mock_playback: MockPlayback
var set_properties: Dictionary = {}

func _init() -> void:
	mock_playback = MockPlaybackScript.new()
	active = true

func _get(property: StringName) -> Variant:
	if property == "parameters/playback":
		return mock_playback
	if set_properties.has(property):
		return set_properties[property]
	return null

func _set(property: StringName, value: Variant) -> bool:
	set_properties[property] = value
	return true
