@tool
class_name LogicSmasher extends RefCounted

# UPDATED: Removes Blackboard, Injects Custom Code
const TEMPLATE = """extends FlowState

# SMASHED STATE: {target_node_name}
# {timestamp}

{property_declarations}

func _get_property_list() -> Array[Dictionary]:
	return {property_list_data}

func process_state(delta: float, actor: Node) -> void:
	# 1. PRIORITY EVALUATION
	var best_child: FlowState = null
	
{logic_body}
	
	if best_child != null and best_child != active_child:
		if not active_child or not active_child.is_hierarchy_locked():
			change_active_child(best_child, actor)
			
	# 2. BEHAVIOR UPDATE
	{behavior_logic}

	# 3. CUSTOM CODE
	{custom_code_injection}
		
	# 4. RECURSION
	if active_child:
		active_child.process_state(delta, actor)
"""

static func smash(node: FlowState) -> String:
	var children: Array[FlowState] = []
	for c in node.get_children():
		if c is FlowState: children.append(c)
	
	var prop_decls: PackedStringArray = []
	var prop_list_items: PackedStringArray = []
	var logic_lines: PackedStringArray = []
	
	var count = children.size()
	var first_check = true
	
	for i in range(count - 1, -1, -1):
		var child = children[i]
		var safe_name = child.name.validate_node_name()
		var child_var = "_child_%s_%d" % [safe_name, i]
		
		prop_decls.append("var %s: FlowState" % child_var)
		prop_list_items.append('\t\t{ "name": "%s", "type": TYPE_OBJECT, "usage": PROPERTY_USAGE_STORAGE },' % child_var)
		
		var cond_checks: PackedStringArray = []
		var conditions = child.get("activation_conditions")
		
		if conditions.is_empty():
			cond_checks.append("true")
		else:
			for j in range(conditions.size()):
				var cond_var = "_cond_%s_%d_%d" % [safe_name, i, j]
				prop_decls.append("var %s: FlowCondition" % cond_var)
				prop_list_items.append('\t\t{ "name": "%s", "type": TYPE_OBJECT, "usage": PROPERTY_USAGE_STORAGE },' % cond_var)
				cond_checks.append("%s.evaluate(actor)" % cond_var)
		
		var expr = "true"
		if not (cond_checks.size() == 1 and cond_checks[0] == "true"):
			var mode = child.get("activation_mode")
			var joiner = " and " if mode == 0 else " or "
			expr = joiner.join(cond_checks)
			
		var if_kw = "if" if first_check else "elif"
		logic_lines.append("\t%s %s:" % [if_kw, expr])
		logic_lines.append("\t\tbest_child = %s" % child_var)
		first_check = false

	var behavior_lines: PackedStringArray = []
	var behaviors = node.get("behaviors")
	if behaviors:
		for i in range(behaviors.size()):
			var beh_var = "_beh_%d" % i
			prop_decls.append("var %s: FlowBehavior" % beh_var)
			prop_list_items.append('\t\t{ "name": "%s", "type": TYPE_OBJECT, "usage": PROPERTY_USAGE_STORAGE },' % beh_var)
			behavior_lines.append("if %s: %s.update(self, delta, actor)" % [beh_var, beh_var])

	var custom_code = node.get("custom_code")
	if not custom_code: custom_code = ""

	var prop_list_str = "[\n" + "\n".join(prop_list_items) + "\n\t]"

	return TEMPLATE.format({
		"target_node_name": node.name,
		"timestamp": Time.get_datetime_string_from_system(),
		"property_declarations": "\n".join(prop_decls),
		"property_list_data": prop_list_str,
		"logic_body": "\n".join(logic_lines),
		"behavior_logic": "\n\t".join(behavior_lines),
		"custom_code_injection": custom_code
	}) + "\nconst SMASHED_CHILD_COUNT = %d\n" % count

static func wire_references(node: FlowState) -> void:
	pass
