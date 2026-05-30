@tool
class_name BehaviorSetValue extends FlowBehavior

## Sets a value in the shared data dict every frame.

@export var data_key: String = ""
@export var value: Variant

func update(_host: Node, data: Dictionary, _delta: float) -> void:
	data[data_key] = value
