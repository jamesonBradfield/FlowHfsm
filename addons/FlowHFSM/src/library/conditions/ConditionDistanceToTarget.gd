@tool
class_name ConditionDistanceToTarget
extends FlowCondition

const FlowValueNode = preload("res://addons/FlowHFSM/src/core/values/ValueNode.gd")

## Smart Condition: Checks distance to a target.
## Uses ValueNode to find the target and ValueFloat for the threshold.

@export_group("Targeting")
## How to find the target to check distance against.
@export var target: FlowValueNode = FlowValueNode.new()

@export_group("Settings")
## The distance threshold to check against.
@export var threshold: FlowValueFloat = FlowValueFloat.new()

## The comparison type.
@export_enum("Less Than (<)", "Greater Than (>)") var operator: int = 0 

func evaluate(actor: Node, blackboard: FlowBlackboard) -> bool:
	# 1. Validation (Safety First)
	if not actor: return false
	
	# 2. Find Target
	# If target resource is missing, fallback to safe default (fail)
	if not target: return false
	
	var target_node = target.get_node(actor, blackboard)
	if not target_node:
		# Fallback: Check if actor has "player" property for backward compatibility
		# Only if target was not configured (ValueNode defaults to SCENE_PATH with empty path)
		# But we can't easily detect "not configured" vs "failed".
		# Actually, let's just stick to the ValueNode. If it fails, it fails.
		return false

	# 3. Calculate
	# Check if both have global_position (3D) or position (2D)
	var dist: float = 0.0
	if "global_position" in actor and "global_position" in target_node:
		dist = actor.global_position.distance_to(target_node.global_position)
	elif "position" in actor and "position" in target_node:
		dist = actor.position.distance_to(target_node.position)
	else:
		return false
	
	if not threshold: return false
	var limit = threshold.get_value(actor, blackboard)

	# 4. Compare
	if operator == 0: # Less Than
		return dist < limit
	else: # Greater Than
		return dist > limit
