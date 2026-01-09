class_name ConditionInputPressed extends StateCondition

## Checks if an input action is pressed.
## Looks for a 'PlayerController' child node on the actor.

@export_group("Input Settings")
## Property name on the PlayerController.
## Example: "jump_pressed", "jump_just_pressed"
@export var input_property: String = "jump_pressed"

func _evaluate(actor: Node) -> bool:
	# Try to find the controller
	var controller = actor.get_node_or_null("PlayerController")
	if controller:
		return controller.get(input_property)
		
	# Fallback: Check if actor itself has the property
	return actor.get(input_property) if actor else false
