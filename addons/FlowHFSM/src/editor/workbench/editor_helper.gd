@tool
extends Object

## HFSMEditorHelper
## Static utility for common editor tasks.

static func is_state(node: Node) -> bool:
	if not is_instance_valid(node): return false
	# Check by class_name or by script path for robustness in volatile environments
	return node is FlowState or (node.get_script() and node.get_script().resource_path.ends_with("FlowState.gd"))

static func is_script_of_type(script: Script, type_name: String) -> bool:
	if not script: return false
	
	# Check global name (class_name)
	if script.get_global_name() == type_name:
		return true
		
	# Check direct base type (for built-in types)
	if script.get_instance_base_type() == type_name:
		return true
		
	# Check script hierarchy
	var base: Script = script.get_base_script()
	while base:
		if base.get_global_name() == type_name:
			return true
		base = base.get_base_script()
		
	return false

## Scans the project for valid HFSM blueprints (Scripts or Resources)
static func scan_blueprints() -> Dictionary:
	var results: Dictionary = {
		"behaviors": [], # Array of { "name": String, "path": String, "is_script": bool }
		"conditions": []
	}
	
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	var root: EditorFileSystemDirectory = fs.get_filesystem()
	if root:
		_traverse(root, results)
	
	return results

static func _traverse(dir: EditorFileSystemDirectory, results: Dictionary) -> void:
	var path: String = dir.get_path()
	if not path.ends_with("/"): path += "/"
	
	# Files
	for i in range(dir.get_file_count()):
		var file_name: String = dir.get_file(i)
		var full_path: String = path + file_name
		
		if file_name.ends_with(".gd"):
			var script: Script = load(full_path) as Script
			if script:
				if is_script_of_type(script, "FlowBehavior"):
					results.behaviors.append({"name": file_name.get_basename(), "path": full_path, "is_script": true})
				elif is_script_of_type(script, "FlowCondition"):
					results.conditions.append({"name": file_name.get_basename(), "path": full_path, "is_script": true})
					
		elif file_name.ends_with(".tres"):
			var res: Resource = load(full_path)
			if res is FlowBehavior:
				results.behaviors.append({"name": file_name.get_basename(), "path": full_path, "is_script": false})
			elif res is FlowCondition:
				results.conditions.append({"name": file_name.get_basename(), "path": full_path, "is_script": false})
				
	# Subdirs
	for i in range(dir.get_subdir_count()):
		_traverse(dir.get_subdir(i), results)
