class_name FlowHost extends Node

## Attach this to any node (CharacterBody3D, Node3D, etc.).
## Owns the shared data dictionary and drives the state machine.

@export var root_state: FlowState

var data: Dictionary = {}

func _ready() -> void:
	_scrape_inputs()
	if root_state:
		root_state.host = get_parent()

func _process(delta: float) -> void:
	_poll_input()
	if root_state:
		root_state._walk(data, delta)

func _poll_input() -> void:
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		data["input/" + action] = Input.is_action_pressed(action)

func _scrape_inputs() -> void:
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		data["input/" + action] = false
