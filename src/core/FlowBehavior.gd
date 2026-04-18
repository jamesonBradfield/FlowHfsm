@tool
class_name FlowBehavior extends Resource

## THE BRAIN
## Defines "What to do". Reusable across many nodes.
## Stateless! Do not store variables here. Use node.memory.
##
## Behaviors receive a context dict (pushed from FlowDataMap)
## instead of pulling data from actor properties.

# Virtual Functions - Override these!

## Called when the state is entered.
func enter(node: Node, actor: Node) -> void:
	pass

## Called when the state is exited.
func exit(node: Node, actor: Node) -> void:
	pass

## Called every frame while the state is active.
## @param context: The data context pushed down from the actor's FlowDataMap.
func update(node: Node, delta: float, actor: Node, context: Dictionary[StringName, Variant]) -> void:
	pass

## Helper to get the structured memory object for this state.
func get_memory(node: Node) -> RefCounted:
	return node.get("memory_obj")
