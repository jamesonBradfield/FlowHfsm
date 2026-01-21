@tool
extends VBoxContainer

## HFSM Workbench: The Architect's Desk

var tabs: TabContainer
var palette: Control
var logic_editor: Control

var active_node: Node = null

func _ready() -> void:
	# NUCLEAR CACHE BUST: Force Godot to read the scripts from disk
	# This avoids the "Ghost UI" where you edit a file but the tool runs the old version.
	var PaletteView = ResourceLoader.load("res://addons/FlowHFSM/src/editor/workbench/palette_view.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var LogicEditorView = ResourceLoader.load("res://addons/FlowHFSM/src/editor/workbench/logic_editor_view.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	
	# 1. Clean Header
	for c in get_children():
		c.queue_free()

	var header = PanelContainer.new()
	add_child(header)
	var title = Label.new()
	title.text = " FlowHFSM Architect"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	
	# 2. The Main Workspace (Tabs)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(tabs)
	
	# Tab 1: Palette
	if PaletteView:
		palette = PaletteView.new()
		palette.name = "Library"
		tabs.add_child(palette)
	else:
		_add_error_tab("Library (Load Error)")
	
	# Tab 2: Logic Tuner
	if LogicEditorView:
		logic_editor = LogicEditorView.new() 
		logic_editor.name = "Logic Tuner"
		tabs.add_child(logic_editor)
	else:
		_add_error_tab("Logic Tuner (Load Error)")
	
	# Sync Selection
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	
	# Initial check
	_on_selection_changed()

func _add_error_tab(name: String) -> void:
	var lbl = Label.new()
	lbl.name = name
	lbl.text = "Error loading %s. Check Output for script errors." % name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tabs.add_child(lbl)

func _on_selection_changed() -> void:
	var selected = EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty(): return
	
	active_node = selected[0]
	
	# FIX: GDScript classes return "Node" for get_class() unless overridden.
	# Use 'is' keyword to check against the global class_name.
	if active_node is FlowState:
		if tabs.get_tab_count() > 1:
			tabs.current_tab = 1 # Switch to Logic Tuner
		
		if logic_editor and logic_editor.has_method("edit_state"):
			logic_editor.edit_state(active_node)
