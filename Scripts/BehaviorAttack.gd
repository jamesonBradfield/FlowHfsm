class_name BehaviorAttack extends StateBehavior

## Attack behavior with timer-based duration.
## Applies damage, plays animation, and locks the state during attack.

@export_group("Attack Settings")
## Duration of the attack in seconds.
@export var attack_duration: float = 1.0
## Damage to deal (placeholder for now).
@export var damage: float = 10.0
## Attack animation name.
@export var attack_animation: String = "attack"

func enter(node: RecursiveState, actor: Node, blackboard: Dictionary) -> void:
	# Initialize attack timer
	node.memory["attack_timer"] = 0.0

	# Lock this state to prevent interruption
	node.is_locked = true

	print("Attack started! Duration: ", attack_duration, " seconds")

func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary) -> void:
	# Increment timer
	var timer: float = node.memory.get("attack_timer", 0.0)
	timer += delta
	node.memory["attack_timer"] = timer

	# Check if attack is complete
	if timer >= attack_duration:
		# Unlock the state
		node.is_locked = false
		print("Attack completed!")
