@tool
class_name BehaviorTimerLock extends StateBehavior

## Locks the state for a duration.
## Great for Attacks, Rolls, or Hit Reactions.

@export var duration: ValueFloat # Smart Value! (Constant or Blackboard)

func enter(node: RecursiveState, actor: Node, blackboard: Blackboard) -> void:
	node.is_locked = true

	# Default to 0.5s if no value provided
	var time := 0.5
	if duration:
		time = duration.get_value(actor, blackboard)

	node.memory["lock_timer"] = time

func update(node: RecursiveState, delta: float, actor: Node, blackboard: Blackboard) -> void:
	# Decrement timer
	if node.memory.has("lock_timer"):
		node.memory["lock_timer"] -= delta

		# Unlock when finished
		if node.memory["lock_timer"] <= 0:
			node.is_locked = false

func exit(node: RecursiveState, actor: Node, blackboard: Blackboard) -> void:
	# CRITICAL: Always unlock on exit just in case
	node.is_locked = false
