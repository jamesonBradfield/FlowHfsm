@tool
class_name FlowResolver extends Resource

## Base class for custom data resolution scripts.
## Override resolve() to provide a value from the actor/context.
##
## Example:
##   class_name ResolveCameraRelativeInput extends FlowResolver
##   func resolve(actor: Node, context: Dictionary) -> Variant:
##       var input = context.get(&"move_input", Vector3.ZERO)
##       var cam = actor.get_node_or_null("Camera3D")
##       if cam:
##           return cam.global_transform.basis * input
##       return input

## Override this to produce a value.
## @param actor: The owner of the state machine.
## @param context: The current data context (already-resolved values).
## @return: The resolved value.
func resolve(actor: Node, context: Dictionary) -> Variant:
	return null
