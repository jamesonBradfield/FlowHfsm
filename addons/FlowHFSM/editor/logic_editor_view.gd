@tool
extends ScrollContainer

## LogicEditorView (The "Tuner")
## Displays Behaviors and Conditions as horizontal cards for the selected state.
## Replaces cramped vertical Inspector for deep logic work.

const HFSMPropertyFactory = preload("res://addons/FlowHFSM/editor/property_factory.gd")

var current_state: Node
var content_box: HBoxContainer

func _ready() -> void:
	name = "Logic Tuner"
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

	content_box = HBoxContainer.new()
	content_box.size_flags_horizontal = SIZE_EXPAND_FILL
	content_box.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(content_box)

	# Style it to look like a "Desk" - Darker background for focus
	var style = StyleBoxFlat.new()
	style.bg_color = Color("1e1e1e")
	add_theme_stylebox_override("panel", style)

func edit_state(node: Node) -> void:
	current_state = node
	_rebuild_ui()

func _rebuild_ui() -> void:
	# Clear previous UI
	for c in content_box.get_children():
		c.queue_free()

	if not current_state: return

	# --- COLUMN 1: ACTIVATION (The "IF") ---
	var cond_panel = _create_column("Activation Logic (IF)", Color("ff5d5d")) # Red-ish header
	content_box.add_child(cond_panel)
	content_box.add_child(VSeparator.new())

	var conditions = current_state.get("activation_conditions")
	if conditions:
		for i in range(conditions.size()):
			var card = _create_resource_card(conditions[i], "Condition %d" % i)
			cond_panel.add_child(card)

	# --- COLUMN 2: BEHAVIORS (The "THEN") ---
	var beh_panel = _create_column("Behaviors (THEN)", Color("4fabff")) # Blue-ish header
	content_box.add_child(beh_panel)

	var behaviors = current_state.get("behaviors")
	if behaviors:
		for i in range(behaviors.size()):
			var res = behaviors[i]
			var card_title = res.resource_path.get_file().get_basename() if res else "Null Behavior"
			var card = _create_resource_card(res, card_title)
			beh_panel.add_child(card)

func _create_column(title_text: String, color: Color) -> VBoxContainer:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.custom_minimum_size.x = 200 # Minimum width for readability

	var lbl = Label.new()
	lbl.text = title_text
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl)
	col.add_child(HSeparator.new())
	return col

func _create_resource_card(res: Resource, title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = title
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# Edit Button
	if res:
		var btn = Button.new()
		btn.text = "Edit Resource"
		btn.icon = get_theme_icon("Edit", "EditorIcons")
		# This opens the resource in the main Inspector for fine-tuning
		btn.pressed.connect(func(): EditorInterface.edit_resource(res))
		vbox.add_child(btn)
	else:
		var lbl = Label.new()
		lbl.text = "(Empty)"
		lbl.modulate = Color.GRAY
		vbox.add_child(lbl)

	return panel
