@tool
class_name FlowValueNode
extends Resource

## A dynamic Node resolver for FlowHFSM.
## Allows behaviors/conditions to find nodes (targets, waypoints) flexibly.

enum Mode {
	SCENE_PATH,     ## Use a direct NodePath relative to the actor.
	BLACKBOARD_KEY, ## Fetch the node from the Blackboard.
	NEAREST_GROUP,  ## Find the nearest node in a specific Group.
	PROPERTY,       ## Get a node stored in a property of the actor.
	SELF            ## Return the actor itself.
}

@export var mode: Mode = Mode.SCENE_PATH:
	set(v):
		mode = v
		notify_property_list_changed()

@export var path: NodePath = NodePath("")
@export var blackboard_key: String = "target"
@export var group_name: String = "Player"
@export var property_name: String = "player"

func _validate_property(property: Dictionary) -> void:
	if property.name == "path" and mode != Mode.SCENE_PATH:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "blackboard_key" and mode != Mode.BLACKBOARD_KEY:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "group_name" and mode != Mode.NEAREST_GROUP:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "property_name" and mode != Mode.PROPERTY:
		property.usage = PROPERTY_USAGE_NONE

## Resolves the node based on the current mode.
## [param actor] is the node executing the behavior (context).
## [param blackboard] is the shared blackboard for the state machine.
func get_node(actor: Node, blackboard: Object) -> Node:
	if not actor: return null
	
	match mode:
		Mode.SCENE_PATH:
			if path.is_empty(): return null
			return actor.get_node_or_null(path)
			
		Mode.BLACKBOARD_KEY:
			if blackboard and blackboard.has_method("get_value"):
				var val = blackboard.get_value(blackboard_key)
				if val is Node:
					return val
			return null
			
		Mode.NEAREST_GROUP:
			var nodes = actor.get_tree().get_nodes_in_group(group_name)
			if nodes.is_empty(): return null
			
			var nearest: Node = null
			var min_dist: float = INF
			var actor_pos = actor.global_position if "global_position" in actor else Vector3.ZERO
			
			for node in nodes:
				if node == actor: continue # Don't find self
				if "global_position" in node:
					var dist = actor_pos.distance_squared_to(node.global_position)
					if dist < min_dist:
						min_dist = dist
						nearest = node
			return nearest
		
		Mode.PROPERTY:
			var val = actor.get(property_name)
			if val is Node:
				return val
			return null
			
		Mode.SELF:
			return actor
			
	return null
