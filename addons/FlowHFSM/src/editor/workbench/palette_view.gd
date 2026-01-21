@tool
extends VBoxContainer

## HFSMPaletteView
## Manages the blueprint list and template creation.

const EditorHelper = preload("res://addons/FlowHFSM/src/editor/workbench/editor_helper.gd")

signal blueprint_activated(path: String)
signal blueprint_rmb_requested(path: String, pos: Vector2)

var behaviors_list: ItemList
var conditions_list: ItemList
var tab_container: TabContainer

func _ready() -> void:
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tab_container)
	
	behaviors_list = _create_list("Behaviors")
	conditions_list = _create_list("Conditions")
	
	# Keep palette updated when files change
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(refresh)
	
	refresh()

func refresh() -> void:
	if not behaviors_list or not conditions_list: return
	
	behaviors_list.clear()
	conditions_list.clear()
	
	var data: Dictionary = EditorHelper.scan_blueprints()
	
	for item in data.behaviors:
		var icon_type: String = "Script" if item.is_script else "Resource"
		behaviors_list.add_item(item.name, get_theme_icon(icon_type, "EditorIcons"))
		behaviors_list.set_item_metadata(behaviors_list.item_count - 1, item.path)
		
	for item in data.conditions:
		var icon_type: String = "Script" if item.is_script else "Resource"
		conditions_list.add_item(item.name, get_theme_icon(icon_type, "EditorIcons"))
		conditions_list.set_item_metadata(conditions_list.item_count - 1, item.path)

func _create_list(tab_name: String) -> ItemList:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = tab_name
	tab_container.add_child(vbox)
	
	# Toolbar
	var toolbar: HBoxContainer = HBoxContainer.new()
	vbox.add_child(toolbar)
	
	var btn_new: Button = Button.new()
	btn_new.text = "New " + tab_name.trim_suffix("s")
	btn_new.icon = get_theme_icon("Add", "EditorIcons")
	btn_new.flat = true
	btn_new.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_new.pressed.connect(func(): print("FlowHFSM: New ", tab_name, " wizard WIP"))
	toolbar.add_child(btn_new)
	
	var list: ItemList = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.allow_rmb_select = true
	list.item_activated.connect(func(idx: int): blueprint_activated.emit(list.get_item_metadata(idx)))
	list.item_clicked.connect(func(idx: int, pos: Vector2, btn: int): 
		if btn == MOUSE_BUTTON_RIGHT:
			blueprint_rmb_requested.emit(list.get_item_metadata(idx), get_global_mouse_position())
	)
	vbox.add_child(list)
	
	return list
