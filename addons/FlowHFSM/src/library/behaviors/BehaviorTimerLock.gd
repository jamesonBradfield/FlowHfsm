@tool
class_name BehaviorTimerLock extends FlowBehavior

## Locks the state for a duration.
## Great for Attacks, Rolls, or Hit Reactions.

@export var duration: FlowValueFloat # Smart Value! (Constant or Blackboard)

func enter(node: Node, actor: Node, blackboard: FlowBlackboard) -> void:
	node.is_locked = true

	# Default to 0.5s if no value provided
	var time := 0.5
	if duration:
		time = duration.get_value(actor, blackboard)

	node.memory["lock_timer"] = time

func update(node: Node, delta: float, actor: Node, blackboard: FlowBlackboard) -> void:
	# Decrement timer
	if node.memory.has("lock_timer"):
		node.memory["lock_timer"] -= delta

		# Unlock when finished
		if node.memory["lock_timer"] <= 0:
			node.is_locked = false

func exit(node: Node, actor: Node, blackboard: FlowBlackboard) -> void:
	# CRITICAL: Always unlock on exit just in case
	node.is_locked = false
