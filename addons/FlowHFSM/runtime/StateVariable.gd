@tool
class_name StateVariable extends Resource

## THE BLUEPRINT
## Defines a data entry that should exist in the Blackboard.
## The Root State "harvests" these from the hierarchy at startup.

@export_group("Definition")
## The key used in the Blackboard dictionary (e.g., "ammo", "target").
@export var variable_name: String = ""

## The initial value to set in the Blackboard.
@export var initial_value: Variant

@export_group("Scope")
## If true, this variable is created in the Root Blackboard (Persistent across states).
## If false, it acts as a local override (Concept for future expansion).
@export var is_global: bool = true
