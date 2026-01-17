@tool
extends VBoxContainer

## HFSM Workbench: The Architect's Desk
## Replaces the old "Hierarchy View" with a focused Logic Editor.

# PRELOADS (The fix is here: We point to LogicEditorView, not HierarchyView)
# const PaletteView = preload("res://addons/FlowHFSM/editor/palette_view.gd")
# const LogicEditorView = preload("res://addons/FlowHFSM/editor/logic_editor_view.gd")

var tabs: TabContainer
var palette: Control
var logic_editor: Control

var active_node: Node = null

func _ready() -> void:
	var PaletteView = load("res://addons/FlowHFSM/editor/palette_view.gd")
	var LogicEditorView = load("res://addons/FlowHFSM/editor/logic_editor_view.gd")
	# 1. Clean Header
	var header = PanelContainer.new()
	add_child(header)
	var title = Label.new()
	title.text = "  FlowHFSM Architect"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	# 2. The Main Workspace (Tabs)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(tabs)

	# Tab 1: Palette (The Library)
	palette = PaletteView.new()
	palette.name = "Library"
	tabs.add_child(palette)

	# Tab 2: Logic (The Tuner)
	logic_editor = LogicEditorView.new()
	logic_editor.name = "Logic Tuner"
	tabs.add_child(logic_editor)

	# Sync Selection
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

func _on_selection_changed() -> void:
	var selected = EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty(): return

	active_node = selected[0]

	# Auto-Switch logic:
	# If we selected a State, switch to "Logic Tuner" tab to edit it.
	if active_node.has_method("get_class") and active_node.get_class() == "RecursiveState":
		tabs.current_tab = 1 # Switch to Logic
		logic_editor.edit_state(active_node)
	else:
		# Otherwise stay on Library (or switch back)
		pass
