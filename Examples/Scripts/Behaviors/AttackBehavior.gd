class_name AttackBehavior extends StateBehavior

func enter(node: RecursiveState, _actor: Node, blackboard: Blackboard) -> void:
	node.memory["timer"] = 0.5
	node.is_locked = true

func update(node: RecursiveState, delta: float, _actor: Node, blackboard: Blackboard) -> void:
	if not node.memory.has("timer"):
		return
		
	node.memory["timer"] -= delta
	if node.memory["timer"] <= 0:
		print("Attack Complete")
		node.is_locked = false
		# Optional: Reset timer or mark complete in memory if needed
		node.memory.erase("timer")
