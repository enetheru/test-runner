@tool
extends VBoxContainer

# Test Runner
# TODO - make the script names clickable to load them up in the editor.

#           ████ ███    ███ ██████   ██████  ██████  ████████ ███████          #
#            ██  ████  ████ ██   ██ ██    ██ ██   ██    ██    ██               #
#            ██  ██ ████ ██ ██████  ██    ██ ██████     ██    ███████          #
#            ██  ██  ██  ██ ██      ██    ██ ██   ██    ██         ██          #
#           ████ ██      ██ ██       ██████  ██   ██    ██    ███████          #
func                        _________IMPORTS_________              ()->void:pass

const InfoBox = preload('info_box.gd')

const INFO_BOX = preload('info_box.tscn')

const Shared = preload('scripts/shared.gd')


#                       ██████  ███████ ███████ ███████                        #
#                       ██   ██ ██      ██      ██                             #
#                       ██   ██ █████   █████   ███████                        #
#                       ██   ██ ██      ██           ██                        #
#                       ██████  ███████ ██      ███████                        #
func                        __________DEFS___________              ()->void:pass

#var test_dict : Dictionary = {
	#"name": folder.to_pascal_case(),
	#"folder_path": folder_path,
	#"test_scripts": files.filter( test_script_filter ),
	#"schema_files": files.filter( schema_file_filter )
#}

#var test_schema_spec : Dictionary = {
	#"folder_path": "",
#
	#"schema_files" : [""],
	#"test_scripts" : [""],
	#"results": {  }
#}

# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

# Icons
@export var schema_icon: Texture2D

const ICON = preload('res/icon.png')

var folder_icon: Texture2D = ICON
var reload_icon: Texture2D = ICON
var trash_icon: Texture2D = ICON
var script_icon: Texture2D = ICON
var error_icon: Texture2D = ICON
var success_icon: Texture2D = ICON
var warning_icon: Texture2D = ICON

@onready var buttons : Dictionary[StringName, Button] = {
	&"Reload": $Buttons/Reload,
	&"Test" : $Buttons/Test,
	&"ClearResults": $Buttons/ClearResults,
	&"Help":$Buttons/Help
}
@onready var help_popup: PopupPanel = $PopupPanel

@onready var stats_counter: RichTextLabel = $Buttons/StatsCounter

# tree control
@onready var tree: Tree = $TestOutput/Tree
@onready var info_list: VBoxContainer = $TestOutput/InfoList
@onready var info_scroller: ScrollContainer = $TestOutput/InfoList/ScrollContainer
@onready var info_items: VBoxContainer = $TestOutput/InfoList/ScrollContainer/InfoItems

@onready var rtl: RichTextLabel = $RichTextLabel

var test_list : Array[Dictionary]

var test_path : String = 'res://tests'

var test_selection : Dictionary = {}

# ██████ ████  █████  ███    ██  █████  ██     ██████
# ██      ██  ██      ████   ██ ██   ██ ██     ██
# ██████  ██  ██  ███ ██ ██  ██ ███████ ██     ██████
#     ██  ██  ██   ██ ██  ██ ██ ██   ██ ██         ██
# ██████ ████  █████  ██   ████ ██   ██ ██████ ██████

#             ███████ ██    ██ ███████ ███    ██ ████████ ███████              #
#             ██      ██    ██ ██      ████   ██    ██    ██                   #
#             █████   ██    ██ █████   ██ ██  ██    ██    ███████              #
#             ██       ██  ██  ██      ██  ██ ██    ██         ██              #
#             ███████   ████   ███████ ██   ████    ██    ███████              #
func                        __________EVENTS_________              ()->void:pass

func _on_reload_pressed() -> void:
	tree.clear()
	regenerate_tree()

func _on_test_pressed() -> void:
	process_selection()

func _on_clear_pressed() -> void:
	for child in info_items.get_children():
		child.call_deferred("queue_free")

func _on_multi_select( item : TreeItem, _column : int, is_selected : bool) -> void:
	if is_selected: test_selection[item] = true
	else:
		@warning_ignore('return_value_discarded')
		test_selection.erase(item)

func _on_item_button_clicked(
			file_item: TreeItem,
			_column: int,
			_id: int,
			_mouse_button_index: int
			) -> void:
	match file_item.get_metadata(1):
				&"test": process_test(file_item)

func _on_gui_input( event : InputEvent ) -> void:
	if not event is InputEventMouseButton: return
	var mb_event : InputEventMouseButton = event
	if not mb_event.pressed: return
	#var column = tree.get_column_at_position(mb_event.position)
	var item : TreeItem = tree.get_item_at_position(mb_event.position)
	if not item: return

	var metadata : Variant = item.get_metadata(0)
	if not metadata: return
	var test_def : Dictionary = metadata
	var test_file : String = item.get_text(0)

	# FIXME it would be nice if I could get the file open in the text editor
	var file_path : String = "/".join([test_def.folder_path, test_file])
	if Engine.is_editor_hint():
		EditorInterface.get_file_system_dock().navigate_to_path(file_path)

	var results : Dictionary = test_def.get('results', {})
	var item_results : Dictionary = results.get(item, {})

	var latest_info_box : InfoBox
	if item_results.has('latest') and item_results.get('latest'):
		latest_info_box = item_results.get('latest', null)
	if latest_info_box: latest_info_box.call_deferred( "grab_focus")


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _ready() -> void:
	if Engine.is_editor_hint():
		_ready_editor()

	# Icon helper snippet
	#for type_name in etheme.get_type_list():
		#for icon_name in etheme.get_icon_list(type_name):
			#rtl.add_image(etheme.get_icon(icon_name, type_name))
			#rtl.append_text("\t")
			#rtl.append_text("/".join([type_name,icon_name]))
			#rtl.newline()

	@warning_ignore_start('return_value_discarded')
	buttons[&"Reload"].pressed.connect( _on_reload_pressed )
	buttons[&"Reload"].icon = reload_icon
	buttons[&"Test"].pressed.connect( _on_test_pressed )
	buttons[&"ClearResults"].pressed.connect( _on_clear_pressed )
	buttons[&"Help"].pressed.connect( help_popup.popup )

	# TODO add a popup with information about recursive expansion
	# and contracting using the shift key.
	#info.pressed.connect( info_popup )

	tree.multi_selected.connect(_on_multi_select)
	tree.button_clicked.connect(_on_item_button_clicked)
	tree.gui_input.connect(_on_gui_input)
	@warning_ignore_restore('return_value_discarded')

	_on_reload_pressed()

func _ready_editor() -> void:
	var etheme : Theme = EditorInterface.get_editor_theme()
	folder_icon = etheme.get_icon( "Folder", "EditorIcons" )
	reload_icon = etheme.get_icon( "Reload", "EditorIcons" )
	trash_icon = etheme.get_icon( "Remove", "EditorIcons" )
	script_icon = etheme.get_icon( "GDScript", "EditorIcons" )
	error_icon = etheme.get_icon( "StatusError", "EditorIcons" )
	success_icon = etheme.get_icon( "StatusSuccess", "EditorIcons" )
	warning_icon = etheme.get_icon( "StatusWarning", "EditorIcons" )

func _redy_play() -> void:
	pass


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

var already_updating : bool = false
func update_stats() -> void:
	if already_updating: return
	already_updating = true
	stats_counter.clear()
	var groups : int = 0
	var results : int = 0
	var failures : int = 0
	var successes : int = 0
	for test_def : Dictionary in test_list:
		groups += 1
		var result_list : Dictionary = test_def.get('results', {})
		for key : String in result_list.keys():
			results += 1
			var result : Dictionary = result_list.get(key, {})
			var retcode : int = result.get('retcode', -1)
			if retcode == 0: successes += 1
			if retcode > 0: failures += 1

	stats_counter.add_text("%d:" % groups)
	stats_counter.add_image(folder_icon)
	stats_counter.add_text(", %d:" % results)
	stats_counter.add_image(script_icon)
	stats_counter.add_text(", %d:" % failures)
	stats_counter.add_image(error_icon)
	stats_counter.add_text(", %d:" % successes)
	stats_counter.add_image(success_icon)

	already_updating = false

func create_info( file_item : TreeItem ) -> Control:
	var test_def : Dictionary = file_item.get_metadata(0)
	var file_name : String = file_item.get_text(0)

	var info_box : InfoBox = INFO_BOX.instantiate()
	info_items.add_child(info_box)
	info_box.show()
	if not info_box.is_node_ready(): await info_box.ready

	info_box.set_title( "/".join([test_def.name, file_name]) )

	return info_box


func process_selection( action_type : StringName = &"all") -> void:
	var selection : Array
	if test_selection.is_empty():
		selection = tree.get_root().get_children()
	elif tree.get_root() in test_selection.keys():
		selection = tree.get_root().get_children()
	else:
		selection = test_selection.keys()

	for folder_item : TreeItem in selection:
		for file_item : TreeItem in folder_item.get_children():
			var _test_def : Dictionary = file_item.get_metadata(0)
			var _action_type : StringName = file_item.get_metadata(1)
			var process : bool = action_type == &"all"
			if _action_type == action_type: process = true
			if not process: continue
			match _action_type:
				&"test": process_test(file_item)


func process_test( file_item : TreeItem ) -> void:
	print_rich("[b]1STARTED - process_test( %s )[/b]" % file_item.get_text(0) )
	var info_box : InfoBox = await create_info( file_item )
	var test_def : Dictionary = file_item.get_metadata(0)
	var script_file : String = file_item.get_text(0)
	var script_path : String = "/".join([test_def.folder_path, script_file])

	var scene_tree : SceneTree
	if Engine.is_editor_hint():
		scene_tree = EditorInterface.get_base_control().get_tree()
	else:
		scene_tree = get_tree()

	var thread := Thread.new()
	var err : Error = thread.start( run_test_script.bind( script_path, scene_tree ) )
	if err != OK:
		print( error_string(err), " When attempting to run test" )
		return

	var thread_output : Variant = thread.wait_to_finish()
	print( thread_output )
	var results : Dictionary = {}

	results["latest"] = info_box
	var test_result : Dictionary = test_def.get_or_add( "results", {} )
	test_result[file_item] =  results

	# Update the tree_item
	var result_output : PackedStringArray = results.get('output', [])
	var info_text : String = "\n".join(result_output)
	if results.get('retcode', 1):
		set_item_fail(file_item)
		info_box.set_fail(info_text)
	elif 'warn' in info_text.to_lower():
		set_item_warning(file_item)
		info_box.set_warning(info_text)
	else:
		set_item_success(file_item)
		info_box.set_success(info_text)
	update_stats()
	print_rich("[b]1COMPLETED - process_test( %s )[/b]" % file_item )


func re_write( orig_path : String) -> String:
	var orig : Dictionary = {
		"dir":orig_path.get_base_dir(),
		"name":orig_path.get_file().get_basename()
	}
	var alt_path := "{dir}/{name}_alt.gd".format(orig)

	var orig_file := FileAccess.open(orig_path, FileAccess.READ)
	if not orig_file.is_open():
		printerr("Failed to open file: ", orig_path)
		return ""

	# skip the first three lines.
	for i : int in 3:
		var _line : String = orig_file.get_line()

	var alt_file := FileAccess.open( alt_path, FileAccess.WRITE)
	var header_replacement : String = "# This script is modified automatically to work in play mode.
extends PlayBase\n"
	if not alt_file.store_string(header_replacement):
		printerr( "Failed to write to script alternate")
		orig_file.close()
		alt_file.close()
		return ""


	while not orig_file.eof_reached():
		var line : String = orig_file.get_line()
		if not alt_file.store_string(line + "\n"):
			printerr( "Failed to write to script alternate")
			orig_file.close()
			alt_file.close()
			return ""

	orig_file.close()
	alt_file.close()
	return alt_path


func run_test_script( file_path : String ) -> Dictionary:
	var result : Dictionary = {
		'path':file_path,
		'retcode': 1,
		'output': []
	}
	# can i re-write it before i start?
	if not Engine.is_editor_hint():
		file_path = re_write(file_path)

	var script : GDScript = load( file_path )
	if not script.can_instantiate():
		result['retcode'] = FAILED
		result['output'] = ["Cannot instantiate '%s'" % file_path ]
		return result
	var instance : PlayBase  = script.new()

	if instance :
		@warning_ignore('redundant_await')
		result['retcode'] = await instance._run_test()
		result['output'] = instance.output
	else:
		result['retcode'] = FAILED
		result['output'] = ["Instantiation failed."]

	#Erase our alternate script file after we are done.
	if not Engine.is_editor_hint():
		var err : Error = DirAccess.remove_absolute(file_path)
		if err != OK:
			printerr( error_string(err), " Failure to remove alternate script")
	return result

#                       ████████ ██████  ███████ ███████                       #
#                          ██    ██   ██ ██      ██                            #
#                          ██    ██████  █████   █████                         #
#                          ██    ██   ██ ██      ██                            #
#                          ██    ██   ██ ███████ ███████                       #
func                        __________TREE___________              ()->void:pass

func set_item_fail( item : TreeItem ) -> void:
	item.set_text(1, "FAILURE")
	item.set_custom_bg_color(0, Color.DARK_RED, false)
	item.set_custom_bg_color(1, Color.DARK_RED, false)

func set_item_warning( item : TreeItem ) -> void:
	item.set_text(1, "!")
	item.set_custom_bg_color(0, Color.DARK_GOLDENROD, false)
	item.set_custom_color(0, Color.DARK_SLATE_GRAY)
	item.set_custom_bg_color(1, Color.DARK_GOLDENROD, false)
	item.set_custom_color(1, Color.DARK_SLATE_GRAY)

func set_item_success( item : TreeItem ) -> void:
	item.set_text(1, "OK")
	item.set_custom_bg_color(0, Color.DARK_GREEN, false)
	item.set_custom_bg_color(1, Color.DARK_GREEN, false)

func add_action_row(
			test_def : Dictionary,
			action_type : StringName,
			filename : String,
			parent_item : TreeItem
			) -> void:
	var item : TreeItem = parent_item.create_child()
	item.set_selectable(0, false )
	item.set_metadata(0, test_def )
	item.set_text( 0, filename )
	# Result
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_selectable(1, false )
	item.set_text(1, "PENDING")
	item.set_metadata(1, action_type )
	item.add_button(1, reload_icon, -1, false, "[Re]Run Test Action" )

	match action_type:
		&"test": item.set_icon(0, script_icon)
		&"schema": item.set_icon(0, schema_icon)

func regenerate_tree() -> void:
	tree.clear()

	# re-build the test dictionary
	test_list = Shared.collect_tests( test_path )

	tree.set_column_title(0, "TestElement")
	tree.set_column_title(1, "  Result  ")
	tree.set_column_expand(1,false)
	var _top_item : TreeItem = tree.create_item()
	_top_item.set_text(0,"Tests")
	for test_def : Dictionary in test_list:
		var test_name : String = test_def.name
		# Add Folder name
		var folder_item : TreeItem = tree.create_item()
		folder_item.set_text( 0, test_name )
		folder_item.set_selectable(1, false )

		# Add script items
		for file : String in test_def.test_scripts:
			add_action_row( test_def, &"test", file, folder_item )

	update_stats()
