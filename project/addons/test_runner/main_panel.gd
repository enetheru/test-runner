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

# Scripts
const InfoBox = preload('info_box.gd')
const Shared = preload('scripts/shared.gd')

# Classes
const TestDef = Shared.TestDef
const TestResult = Shared.TestResult
const RetCode = Shared.RetCode

# Scenes
const INFO_BOX = preload('info_box.tscn')

# Resources
const ICON = preload('res/icon.png')

# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

# Icons
@export var schema_icon: Texture2D

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
	# TODO add debug and verbose checkboxes.
	# TODO add a button to select which path to use for tests
	# TODO add a button to select folder and file filters from a script.
}
@onready var help_popup: PopupPanel = $PopupPanel

@onready var stats_counter: RichTextLabel = $Buttons/StatsCounter

# tree control
@onready var tree: Tree = $TestOutput/Tree
@onready var info_list: VBoxContainer = $TestOutput/InfoList
@onready var info_scroller: ScrollContainer = $TestOutput/InfoList/ScrollContainer
@onready var info_items: VBoxContainer = $TestOutput/InfoList/ScrollContainer/InfoItems

@onready var rtl: RichTextLabel = $RichTextLabel

# Runtime
var test_list : Array[TestDef]
var test_selection : Dictionary = {}

# Configuration
var test_path : String = 'res://tests'
var test_script_filter : Callable = default_script_filter
var test_folder_filter : Callable = default_folder_filter


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
	process_test(file_item)

func _on_gui_input( event : InputEvent ) -> void:
	if not event is InputEventMouseButton: return
	var mb_event : InputEventMouseButton = event
	if not mb_event.pressed: return
	#var column = tree.get_column_at_position(mb_event.position)
	var tree_item : TreeItem = tree.get_item_at_position(mb_event.position)
	if not tree_item: return

	var metadata : Variant = tree_item.get_metadata(0)
	if not metadata: return
	var test_def : TestDef = metadata
	var test_file : String = tree_item.get_text(0)

	# FIXME it would be nice if I could get the file open in the text editor
	var file_path : String = "/".join([test_def.folder_path, test_file])
	if Engine.is_editor_hint():
		EditorInterface.get_file_system_dock().navigate_to_path(file_path)

	var item_results : TestResult = test_def.results.get(tree_item)
	if item_results and item_results.latest:
		item_results.latest.call_deferred( "grab_focus")


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

func _ready_play() -> void:
	# TODO replace the editor icons with ones from the addon.
	pass


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func default_script_filter( filename : String ) -> bool:
	return filename.begins_with("test") \
		and filename.ends_with(".gd") \
		and not filename.ends_with("_generated.gd")


func default_folder_filter( folder_path : String ) -> bool:
	var files : Array = DirAccess.get_files_at( folder_path )
	return not files.filter( test_script_filter ).is_empty()


func collect_tests( _path : String ) -> Array[TestDef]:
	var tests : Array[TestDef]

	var folders : Array = DirAccess.get_directories_at(_path)
	var folder_paths : Array = folders.map( func(folder : String) -> String:
			return "/".join([_path,folder]))
	folder_paths.sort()
	for folder_path : String in folder_paths.filter( test_folder_filter ):
		var files : Array = DirAccess.get_files_at( folder_path )
		var folder : String = folder_path.get_file()

		var def : TestDef = TestDef.new()
		def.name =  folder.to_pascal_case()
		def.folder_path =  folder_path
		def.test_scripts =  files.filter( test_script_filter )

		tests.append( def )

	return tests


var already_updating : bool = false
func update_stats() -> void:
	if already_updating: return
	already_updating = true
	stats_counter.clear()
	var groups : int = 0
	var results : int = 0
	var failures : int = 0
	var successes : int = 0
	for test_def : TestDef in test_list:
		groups += 1
		for result : TestResult in test_def.results.values():
			results += 1
			if result.retcode == RetCode.TEST_OK: successes += 1
			if result.retcode == RetCode.TEST_FAILED: failures += 1

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
	var test_def : TestDef = file_item.get_metadata(0)
	var file_name : String = file_item.get_text(0)

	var info_box : InfoBox = INFO_BOX.instantiate()
	info_items.add_child(info_box)
	info_box.show()
	if not info_box.is_node_ready(): await info_box.ready

	info_box.set_title( "/".join([test_def.name, file_name]) )

	return info_box


func process_selection() -> void:
	var selection : Array
	if test_selection.is_empty():
		selection = tree.get_root().get_children()
	elif tree.get_root() in test_selection.keys():
		selection = tree.get_root().get_children()
	else:
		selection = test_selection.keys()

	for folder_item : TreeItem in selection:
		for file_item : TreeItem in folder_item.get_children():
			var _test_def : TestDef = file_item.get_metadata(0)
			process_test(file_item)


func process_test( file_item : TreeItem ) -> void:
	print_rich("[b]STARTED - process_test( %s )[/b]" % file_item.get_text(0) )
	var info_box : InfoBox = await create_info( file_item )
	var test_def : TestDef = file_item.get_metadata(0)
	var script_file : String = file_item.get_text(0)
	var script_path : String = "/".join([test_def.folder_path, script_file])

	# We're only keeping around one rest result per test.
	var result : TestResult = test_def.results.get_or_add( file_item, TestResult.new() )
	result.latest = info_box
	result.retcode = RetCode.TEST_FAILED
	result.output = ["Only Just Created"]

	# Tests can be run three ways.
	# 	1. Headless as EditorScript
	# 	2. From the test runner as EditorScript
	# 	3. In a game from the test runner as Node
	# If the last, the script header needs to be re-written to extend Node
	if not Engine.is_editor_hint():
		script_path = re_write(script_path)
		# If Script path fails
		if script_path.is_empty():
			result.retcode = RetCode.TEST_FAILED
			result.output = ["Re-Writing the script for in-game testing failed."]
			set_item_fail(file_item)
			info_box.set_fail("Re-Writing the script for in-game testing failed.")
			return

	# Load up the script and run the test
	var script : GDScript = load( script_path )
	if not script.can_instantiate():
		result.output = ["Cannot instantiate '%s'" % script_path ]
	elif Engine.is_editor_hint():
		var instance : TestBase  = script.new()
		if instance : await run_test_base( instance, result )
	else:
		var instance : PlayBase  = script.new()
		if instance :
			get_tree().root.add_child(instance, true)
			await run_play_base( instance, result,  )
		instance.queue_free()

	#Erase our alternate script file after we are done.
	if not Engine.is_editor_hint():
		var err : Error = DirAccess.remove_absolute(script_path)
		if err != OK:
			printerr( error_string(err), " Failure to remove alternate script")


	var info_text : String = "Empty"
	if not result.output.is_empty():
		info_text = result.output.reduce(Shared.reducer_to_lines)

	# Update the tree_item
	if result.retcode == RetCode.TEST_FAILED:
		set_item_fail(file_item)
		info_box.set_fail(info_text)
	elif 'warn' in info_text.to_lower():
		set_item_warning(file_item)
		info_box.set_warning(info_text)
	else:
		set_item_success(file_item)
		info_box.set_success(info_text)
	update_stats()
	print_rich("[b]COMPLETED - process_test( %s )[/b]" % script_file )


func run_test_base( instance : TestBase, result : TestResult ) -> void:
	@warning_ignore('redundant_await')
	await instance.run_test()
	result.retcode = instance.runcode
	result.output = instance.output


func run_play_base( instance : PlayBase, result : TestResult ) -> void:
	@warning_ignore('redundant_await')
	await instance.run_test()
	result.retcode = instance.runcode
	result.output = instance.output


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
			test_def : TestDef,
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
	item.add_button(1, reload_icon, -1, false, "[Re]Run Test Action" )
	item.set_icon(0, script_icon)


func regenerate_tree() -> void:
	tree.clear()

	# re-build the test dictionary
	test_list = collect_tests( test_path )

	tree.set_column_title(0, "TestElement")
	tree.set_column_title(1, "  Result  ")
	tree.set_column_expand(1,false)
	var _top_item : TreeItem = tree.create_item()
	_top_item.set_text(0,"Tests")
	for test_def : TestDef in test_list:
		# Add Folder name
		var folder_item : TreeItem = tree.create_item()
		folder_item.set_text( 0, test_def.name )
		folder_item.set_selectable(1, false )

		# Add script items
		for file : String in test_def.test_scripts:
			add_action_row( test_def, file, folder_item )

	update_stats()
