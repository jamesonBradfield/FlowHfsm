@tool
extends EditorInspectorPlugin

# const AssetCreationDialog = preload("res://addons/FlowHFSM/editor/asset_creation_dialog.gd")
# var wizard_dialog: ConfirmationDialog

func _can_handle(object: Object) -> bool:
	return object is RecursiveState

func _parse_begin(object: Object) -> void:
	if not object is RecursiveState: return
	
	# WORKBENCH MIGRATION: 
	# The "Add Child State" button is removed.
	# Users should use the HFSM Workbench (Bottom Panel) or the Scene Tree.
	
	# Optional: Add a label hinting at the workbench?
	var lbl: Label = Label.new()
	lbl.text = "Tip: Use HFSM Workbench to add states."
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_custom_control(lbl)

	# --- SMASHER INTEGRATION ---
	# Check for Logic Smasher integrity
	if object.has_method("validate_smashed_logic"):
		var error_msg: String = object.call("validate_smashed_logic")
		
		if not error_msg.is_empty():
			# DIRTY STATE: Show Warning + Fix
			var warn_panel: PanelContainer = PanelContainer.new()
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color(0.3, 0.1, 0.1) # Dark Red
			style.border_width_left = 2
			style.border_color = Color(0.9, 0.2, 0.2)
			warn_panel.add_theme_stylebox_override("panel", style)
			
			var vbox: VBoxContainer = VBoxContainer.new()
			warn_panel.add_child(vbox)
			
			var lbl_err: Label = Label.new()
			lbl_err.text = "⚠️ LOGIC OUT OF SYNC"
			lbl_err.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			lbl_err.add_theme_font_size_override("font_size", 14)
			vbox.add_child(lbl_err)
			
			var lbl_desc: Label = Label.new()
			lbl_desc.text = error_msg
			lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			vbox.add_child(lbl_desc)
			
			var btn_fix: Button = Button.new()
			btn_fix.text = "Re-Smash (Fix Logic)"
			# btn_fix.icon = btn_fix.get_theme_icon("Reload", "EditorIcons") # Context safety
			btn_fix.pressed.connect(func(): _re_smash_script(object as Node))
			vbox.add_child(btn_fix)
			
			add_custom_control(warn_panel)
			
		elif object.get_script() and object.get_script().get_script_constant_map().has("SMASHED_CHILD_COUNT"):
			# CLEAN SMASHED STATE
			var clean_panel: PanelContainer = PanelContainer.new()
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.25, 0.15) # Dark Green
			clean_panel.add_theme_stylebox_override("panel", style)
			
			var hbox: HBoxContainer = HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			clean_panel.add_child(hbox)
			
			var lbl_ok: Label = Label.new()
			lbl_ok.text = "⚡ Optimized (O(1))"
			lbl_ok.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
			hbox.add_child(lbl_ok)
			
			var btn_re: Button = Button.new()
			btn_re.flat = true
			# btn_re.icon = btn_re.get_theme_icon("Reload", "EditorIcons")
			btn_re.tooltip_text = "Force Re-Smash"
			btn_re.pressed.connect(func(): _re_smash_script(object as Node))
			hbox.add_child(btn_re)
			
			add_custom_control(clean_panel)

func _re_smash_script(node: Node) -> void:
	var path: String = node.get_script().resource_path
	var smasher_script: Script = load("res://addons/FlowHFSM/editor/logic_smasher.gd")
	if not smasher_script: return
	
	# Assuming static method 'smash' and 'wire_references' exist
	var code: String = smasher_script.call("smash", node)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(code)
		f.close()
		EditorInterface.get_resource_filesystem().scan()
		
		# Small delay to ensure scan picks it up
		await EditorInterface.get_base_control().get_tree().create_timer(0.1).timeout
		
		var res: Script = load(path)
		node.set_script(res)
		smasher_script.call("wire_references", node)
		EditorInterface.inspect_object(node) # Refresh Inspector
		print("FlowHFSM: Re-smashed logic for ", node.name)

func _parse_property(object: Object, _type: int, name: String, _hint_type: int, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	# Intercept behaviors to inline it
	if name == "behaviors":
		add_property_editor(name, preload("res://addons/FlowHFSM/editor/behavior_editor.gd").new())
		return true

	# Intercept activation_conditions to inline them
	if name == "activation_conditions":
		add_property_editor(name, preload("res://addons/FlowHFSM/editor/condition_editor.gd").new())
		return true

	# Intercept declared_variables to inline them
	if name == "declared_variables":
		add_property_editor(name, preload("res://addons/FlowHFSM/editor/variable_editor.gd").new())
		return true

	return false
