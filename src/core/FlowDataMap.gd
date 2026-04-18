@tool
class_name FlowDataMap extends Resource

## The data map that defines what keys are available in the context.
## Lives on the actor (e.g. FlowCharacter). Each frame, the actor
## resolves all entries into a Dictionary[StringName, Variant] (the context)
## which flows DOWN through FlowState.process_state().
##
## Example entries:
##   { key: &"move_input",  binding: FlowBinding(path=":move_input") }
##   { key: &"camera",      binding: FlowBinding(path="Camera3D") }
##   { key: &"cam_move",    binding: FlowBinding(source=RESOLVER, resolver=MyResolver) }

@export var entries: Array[FlowDataEntry] = []

## Resolves all entries into a context dictionary.
## Passes partially-built context to resolvers so they can chain.
func resolve(actor: Node) -> Dictionary[StringName, Variant]:
	var context: Dictionary[StringName, Variant] = {}
	for entry: FlowDataEntry in entries:
		if entry and entry.key and entry.binding:
			context[entry.key] = entry.binding.get_value(actor, context)
	return context
