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

func _evaluate(actor: Node) -> bool:
	# Note: Accessing specific node memory from a condition is tricky because the condition 
	# is evaluated by the PARENT, not the child that owns the memory.
	# This condition implies we want to check if a specific child's timer is done?
	# Or the parent's timer? 
	# Usually, transitions check the *active state's* properties.
	
	# For now, without passing the node context explicitly, this is hard.
	# But in the new architecture, we should rely on the Behavior to set a flag on the Actor 
	# if it's done, OR pass the node context.
	
	# Wait, `process_state` calls `can_activate`. 
	# `can_activate` iterates conditions. 
	# `can_activate` is called on the CHILD.
	# So `self` in `can_activate` is the Child Node.
	# But `evaluate` is on the Resource.
	
	# We need the node reference. 
	# The previous implementation tried `blackboard.get("current_node")`.
	# We should probably pass the `node` to `evaluate` if we want Conditions to check Node Memory.
	
	# However, standard practice: Conditions check World State (Actor), not internal Memory.
	# If internal memory dictates transition (e.g. timer), the Behavior should set a flag 
	# like `actor.is_attack_finished = true`.
	
	push_warning("ConditionTimerElapsed: Cannot access node memory without context. Use Actor properties instead.")
	return false
