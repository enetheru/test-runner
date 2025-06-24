@tool
extends PanelContainer

@onready var stylebox : StyleBox = preload('res/info_style_box.tres').duplicate()
const ICON = preload('res/icon.png')

var error_icon: Texture2D = ICON
var success_icon: Texture2D = ICON
var warning_icon: Texture2D = ICON

@onready var label: RichTextLabel = $Elements/Label
@onready var rtl: RichTextLabel = $Elements/RichTextLabel

var title : String

func _ready() -> void:
	if Engine.is_editor_hint():
		_ready_editor()

	focus_mode = Control.FOCUS_CLICK
	add_theme_stylebox_override("panel", stylebox)

	focus_entered.connect(func(): stylebox.bg_color = Color(0.275, 0.439, 0.584) )
	focus_exited.connect(func(): stylebox.bg_color = Color(0.216, 0.31, 0.4) )

	label.add_theme_stylebox_override("normal", stylebox)

func _ready_editor() -> void:
	var etheme : Theme = EditorInterface.get_editor_theme()
	error_icon = etheme.get_icon( "StatusError", "EditorIcons" )
	success_icon = etheme.get_icon( "StatusSuccess", "EditorIcons" )
	warning_icon = etheme.get_icon( "StatusWarning", "EditorIcons" )


func set_title( new_title : String ):
	title = new_title
	label.clear()
	label.append_text(new_title)

func set_success( _txt : String ):
	stylebox.border_color = Color.DARK_GREEN
	label.clear()
	label.add_image(success_icon)
	label.append_text(title)
	rtl.clear()
	rtl.hide()

func set_warning( txt : String ):
	stylebox.border_color = Color.DARK_KHAKI
	label.clear()
	label.add_image(warning_icon)
	label.append_text(title)
	rtl.clear()
	rtl.append_text(txt)

func set_fail( txt : String ):
	stylebox.border_color = Color.DARK_RED
	label.clear()
	label.add_image(error_icon)
	label.append_text(title)
	rtl.clear()
	rtl.append_text(txt)
