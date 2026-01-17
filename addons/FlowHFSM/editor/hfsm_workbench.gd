@tool
extends VBoxContainer

## HFSM Workbench: The Architect's Desk

var tabs: TabContainer
var palette: Control
var logic_editor: Control

var active_node: Node = null

func _ready() -> void:
	# NUCLEAR CACHE BUST: Force Godot to read the scripts from disk
	var PaletteView = ResourceLoader.load("res://addons/FlowHFSM/editor/palette_view.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var LogicEditorView = ResourceLoader.load("res://addons/FlowHFSM/editor/logic_editor_view.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	
	# 1. Clean Header
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
	
	# Tab 2: Logic Tuner
	if LogicEditorView:
		logic_editor = LogicEditorView.new() 
		logic_editor.name = "Logic Tuner"
		tabs.add_child(logic_editor)
	
	# Sync Selection
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

func _on_selection_changed() -> void:
	var selected = EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty(): return
	
	active_node = selected[0]
	
	if active_node.has_method("get_class") and active_node.get_class() == "RecursiveState":
		tabs.current_tab = 1 # Switch to Logic
		if logic_editor and logic_editor.has_method("edit_state"):
			logic_editor.edit_state(active_node)
