class_name StateBehavior extends Resource

## THE BRAIN
## Defines "What to do". Reusable across many nodes.
## stateless! Do not store variables here. Use node.memory.

@export_group("Visuals")
## The name of the animation to play when this state is entered.
@export var animation: String = ""

# Virtual Functions - Override these!

## Called when the state is entered.
## Can be used to initialize memory, start animations, or apply immediate forces.
##
## @param node: The RecursiveState node using this behavior.
## @param actor: The owner of the state machine.
## @param blackboard: Shared data dictionary.
func enter(node: RecursiveState, actor: Node, blackboard: Dictionary) -> void:
	if animation != "":
		# Assuming AnimationTree playback is in the blackboard or accessible on actor
		# For the Phase 1 setup, let's assume we just print for now
		print("Playing Anim: ", animation)

## Called when the state is exited.
## Can be used to clean up memory or stop effects.
##
## @param node: The RecursiveState node using this behavior.
## @param actor: The owner of the state machine.
## @param blackboard: Shared data dictionary.
func exit(node: RecursiveState, actor: Node, blackboard: Dictionary) -> void:
	pass

## Called every frame while the state is active.
## Contains the main logic of the behavior (e.g., movement, timers).
##
## @param node: The RecursiveState node using this behavior.
## @param delta: Time elapsed since the last frame.
## @param actor: The owner of the state machine.
## @param blackboard: Shared data dictionary.
func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary) -> void:
	pass
