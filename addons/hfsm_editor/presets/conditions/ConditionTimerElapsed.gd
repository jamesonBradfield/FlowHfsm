class_name ConditionTimerElapsed extends StateCondition

## Checks if a timer in node memory has elapsed.
## Useful for timed states (e.g., attack duration, dash cooldown).

@export_group("Timer Settings")
## Blackboard key to check for timer value (typically in node.memory).
@export var timer_key: String = "timer"
## Time threshold to check against (in seconds).
@export var threshold: float = 1.0
## If true, checks if timer is GREATER than threshold.
## If false, checks if timer is LESS than threshold.
@export var check_greater_than: bool = true

	# Node reference to access memory from.
	# This is set by the HFSM system when evaluating conditions.
	# @export var target_node: RecursiveState -> REMOVED: Cannot export Node in Resource

func _evaluate(actor: Node, blackboard: Dictionary) -> bool:
	# For conditions that need to access node memory,
	# we typically get the node reference from blackboard or actor
	var node: RecursiveState = blackboard.get("current_node", null) as RecursiveState

	if not node:
		push_warning("ConditionTimerElapsed: No node reference found in blackboard")
		return false

	# Get timer value from node memory
	var timer_value: float = node.memory.get(timer_key, 0.0)

	if check_greater_than:
		return timer_value > threshold
	else:
		return timer_value < threshold
