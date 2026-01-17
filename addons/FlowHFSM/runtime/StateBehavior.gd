class_name StateBehavior extends Resource

## THE BRAIN
## Defines "What to do". Reusable across many nodes.
## stateless! Do not store variables here. Use node.memory.

# Virtual Functions - Override these!

## Called when the state is entered.
## Can be used to initialize memory, start animations, or apply immediate forces.
##
## @param node: The RecursiveState node using this behavior.
## @param actor: The owner of the state machine.
## @param blackboard: The shared data container.
func enter(node: RecursiveState, actor: Node, blackboard: Blackboard) -> void:
	pass

## Called when the state is exited.
## Can be used to clean up memory or stop effects.
##
## @param node: The RecursiveState node using this behavior.
## @param actor: The owner of the state machine.
## @param blackboard: The shared data container.
func exit(node: RecursiveState, actor: Node, blackboard: Blackboard) -> void:
	pass

## Called every frame while the state is active.
## Contains the main logic of the behavior (e.g., movement, timers).
##
## @param node: The RecursiveState node using this behavior.
## @param delta: Time elapsed since the last frame.
## @param actor: The owner of the state machine.
## @param blackboard: The shared data container.
func update(node: RecursiveState, delta: float, actor: Node, blackboard: Blackboard) -> void:
	pass

## Helper to get the structured memory object for this state.
func get_memory(node: RecursiveState) -> RefCounted:
	return node.memory_obj
