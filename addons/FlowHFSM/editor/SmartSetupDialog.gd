@tool
extends ConfirmationDialog

## Smart Setup Dialog
## 
## Handles atomic creation of a RecursiveState node along with its initial
## behaviors and conditions to ensure valid wiring from the start.

const EditorHelper = preload("res://addons/FlowHFSM/editor/editor_helper.gd")

signal state_configured(name: String, behavior_resource: Resource, conditions: Array[Resource])

var name_edit: LineEdit
var behavior_opt: OptionButton
var condition_list: ItemList
var preview_label: RichTextLabel

# Internal list of available resources found during scan
var _available_behaviors: Array[Dictionary] = []
var _available_conditions: Array[Dictionary] = []

func _ready() -> void:
	title = "Smart Setup: New State"
	size = Vector2i(550, 420)
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# 1. Top Form (Grid for compact layout)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)
	
	# Row 1: Name
	var name_lbl: Label = Label.new()
	name_lbl.text = "State Name:"
	name_lbl.modulate = Color(0.6, 0.8, 1.0)
	grid.add_child(name_lbl)
	
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "e.g. Grounded, Attack"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(func(_t): _update_preview())
	grid.add_child(name_edit)
	
	# Row 2: Behavior
	var beh_lbl: Label = Label.new()
	beh_lbl.text = "Primary Behavior:"
	beh_lbl.modulate = Color(0.6, 0.8, 1.0)
	grid.add_child(beh_lbl)
	
	behavior_opt = OptionButton.new()
	behavior_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	behavior_opt.item_selected.connect(func(_idx): _update_preview())
	grid.add_child(behavior_opt)
	
	# 2. Conditions Section (Full width)
	var cond_lbl: Label = Label.new()
	cond_lbl.text = "Activation Conditions (Multi-Select):"
	cond_lbl.modulate = Color(0.6, 0.8, 1.0)
	vbox.add_child(cond_lbl)
	
	condition_list = ItemList.new()
	condition_list.select_mode = ItemList.SELECT_MULTI
	condition_list.custom_minimum_size.y = 100 # Smaller list
	condition_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	condition_list.multi_selected.connect(func(_idx, _s): _update_preview())
	vbox.add_child(condition_list)
	
	# 3. Preview (Compact)
	var prev_panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 1.0)
	style.border_width_left = 3
	style.border_color = Color(0.3, 0.5, 0.8)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	prev_panel.add_theme_stylebox_override("panel", style)
	vbox.add_child(prev_panel)
	
	preview_label = RichTextLabel.new()
	preview_label.bbcode_enabled = true
	preview_label.fit_content = true
	prev_panel.add_child(preview_label)
	
	confirmed.connect(_on_confirmed)
	
	# Initial Scan
	refresh_resources()

func refresh_resources() -> void:
	_available_behaviors.clear()
	_available_conditions.clear()
	
	# Add 'None' option
	behavior_opt.clear()
	behavior_opt.add_item("None (Empty State)")
	
	var data: Dictionary = EditorHelper.scan_blueprints()
	
	# Populate behaviors (both scripts and resources)
	for item in data.behaviors:
		_available_behaviors.append(item)
		behavior_opt.add_item(item.name)
	
	condition_list.clear()
	for item in data.conditions:
		_available_conditions.append(item)
		condition_list.add_item(item.name)
		
	_update_preview()

func _update_preview() -> void:
	var s_name: String = name_edit.text.strip_edges()
	if s_name.is_empty(): s_name = "NewState"
	
	var beh_idx: int = behavior_opt.selected
	var cond_indices: PackedInt32Array = condition_list.get_selected_items()
	
	var msg: String = "[b]Smart Setup Plan:[/b]\n"
	msg += "• [color=cyan]Node:[/color] Create RecursiveState '%s'\n" % s_name
	
	if beh_idx > 0:
		var item: Dictionary = _available_behaviors[beh_idx - 1]
		msg += "• [color=green]Behavior:[/color] Use %s\n" % item.path.get_file()
	
	if not cond_indices.is_empty():
		msg += "• [color=orange]Conditions:[/color] Attach %d existing resources\n" % cond_indices.size()
		
	preview_label.text = msg

func _on_confirmed() -> void:
	var s_name: String = name_edit.text.strip_edges()
	if s_name.is_empty(): s_name = "NewState"
	
	var selected_res: Resource = null
	if behavior_opt.selected > 0:
		selected_res = load(_available_behaviors[behavior_opt.selected - 1].path)
		
	var selected_conditions: Array[Resource] = []
	for idx in condition_list.get_selected_items():
		selected_conditions.append(load(_available_conditions[idx].path))
		
	state_configured.emit(s_name, selected_res, selected_conditions)
