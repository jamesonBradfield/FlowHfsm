class_name StateBehavior extends Resource

## THE BRAIN
## Defines "What to do". Reusable across many nodes.
## stateless! Do not store variables here. Use node.memory.

@export_group("Visuals")
@export var animation: String = ""

# Virtual Functions - Override these!
func enter(node: RecursiveState, actor: Node, blackboard: Dictionary):
	if animation != "":
		# Assuming AnimationTree playback is in the blackboard or accessible on actor
		# For the Phase 1 setup, let's assume we just print for now
		print("Playing Anim: ", animation)

func exit(node: RecursiveState, actor: Node, blackboard: Dictionary):
	pass

func update(node: RecursiveState, delta: float, actor: Node, blackboard: Dictionary):
	pass
