@tool
class_name StateMemory extends RefCounted

## STRUCTURED STATE MEMORY
## Base class for instance-specific state data.
## Used by Behaviors to store information like timers, counters, or target references.

# Example:
# class MoveMemory extends StateMemory:
#     var start_position: Vector3 = Vector3.ZERO
#     var duration: float = 0.0

func clear() -> void:
	# Virtual method to reset the memory object
	pass
