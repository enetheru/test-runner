# This script is a copy of TestBase.gd
class_name PlayBase
extends Node
var cycleref : Node


#██████  ███████ ███████ ██ ███    ██ ██ ████████ ██  ██████  ███    ██ ███████#
#██   ██ ██      ██      ██ ████   ██ ██    ██    ██ ██    ██ ████   ██ ██     #
#██   ██ █████   █████   ██ ██ ██  ██ ██    ██    ██ ██    ██ ██ ██  ██ ███████#
#██   ██ ██      ██      ██ ██  ██ ██ ██    ██    ██ ██    ██ ██  ██ ██      ██#
#██████  ███████ ██      ██ ██   ████ ██    ██    ██  ██████  ██   ████ ███████#
func                        _______DEFINITIONS_______              ()->void:pass

## Handy Constants
const u32 = 2083138172				#= |**|
const u32_ = 2084585596				#= |@@|
const u64 = 8947009970309311100		#= |******|
const u64_ = 8953226703912583292	#= |@@@@@@|

#NOTE: When a function bails due to assert, or crash, it returns the default
# value in the case of an integer that is 0, which unfortunately equates to OK
# So unfortunately in this case we have to flip the expectation and not rely
# on the builtin constants OK and FAILED
enum {
	TEST_FAILED = 0,
	TEST_OK = 1
}

# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

var scene_tree : SceneTree

var _verbose : bool = true
var _debug : bool = false
var runcode : int = TEST_OK
var output : Array = []
var max_runtime_s : float = 3


#            ███████ ██  ██████  ███    ██  █████  ██      ███████             #
#            ██      ██ ██       ████   ██ ██   ██ ██      ██                  #
#            ███████ ██ ██   ███ ██ ██  ██ ███████ ██      ███████             #
#                 ██ ██ ██    ██ ██  ██ ██ ██   ██ ██           ██             #
#            ███████ ██  ██████  ██   ████ ██   ██ ███████ ███████             #
func                        _________SIGNALS_________              ()->void:pass

signal test_finished


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

# This is the function to override in derived test functions.
func _run_test() -> int:
	var msg : String = "This function needs to be overridden in a derived script."
	logp(msg)
	assert(false, msg)
	return TEST_OK


# Calling as an editor script
func _run() -> void:
	logp("_run() as editorscript - Started")
	assert( OS.get_thread_caller_id() == OS.get_main_thread_id(),
		"A _run() must not be called in a threaded context.\n" + \
		"TestBase relies on the 'await' keyword and functionality which is." + \
		"not usable in a threaded context.\n")

	# NOTE: Maintain a reference to ourself, because no-one else will.
	# Without this, we will be cleaned up before we have had time to do any
	# asynchronous work.
	cycleref = self

	# In case of failure of some unforseen way, I want to make sure the name
	# of our timer node is unique
	var script : Script = get_script()
	var test_name : String = script.resource_path.validate_node_name()

	# Find, or create our timer.
	scene_tree = get_tree()
	var timer : Timer = scene_tree.root.find_child(test_name, false)
	if timer:
		logd( "Error: Timer was not removed in last run.")
		timer.queue_free()

	timer = Timer.new()
	timer.name = test_name
	scene_tree.root.add_child(timer)
	@warning_ignore('return_value_discarded')
	timer.timeout.connect( test_finished.emit )

	# Start the timer, and call the test function and await its finish.
	timer.start(max_runtime_s)
	# NOTE: We run asynchronously so that a crash doesnt prevent reporting
	# the retults
	run_test.call_deferred()
	await test_finished

	# printing output.
	logp("_run() - %s" % ("OK" if runcode == TEST_OK else "FAILED"))
	if _verbose or _debug:
		output.reduce(reducer_to_lines)

	# Cleanup after ourselves.
	timer.queue_free()
	cycleref = null


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func run_test() -> void:
	@warning_ignore('redundant_await')
	runcode = await _run_test()
	test_finished.emit()

func reducer_to_lines(a:String = "", v:Variant = null) -> String:
	return (a + "\n%s" if a else "%s") % v

func logd( msg : Variant = "" ) -> void:
	if msg is Array:
		var array : Array = msg
		msg = array.reduce( reducer_to_lines )
	if _debug:
		print_rich( msg )
		output.append( msg )

func logp( msg : Variant ) -> void:
	if msg is Array:
		var array : Array = msg
		msg = array.reduce( reducer_to_lines )
	if _debug or _verbose: print_rich( msg )
	output.append( msg )

func sbytes( bytes : PackedByteArray, cols : int = 8 ) -> String:
	if bytes.is_empty(): return "Empty"
	var retval : Array = ["size: %d" % bytes.size()]
	var position := 0
	while true:
		var slice : PackedByteArray = bytes.slice(position, position + cols)
		if not slice.size(): break

		# new line
		var line : String = ""
		# Position
		line += "%08X: " % position
		# bytes as hex pairs
		for v in slice: line += "%02X " % v
		# pad to width
		line = line.rpad( 10 + cols*3, ' ')
		# ascii
		for v in slice: line += char(v) if v > 32 else '.'

		retval.append(line)
		position += cols
		if slice.size() < cols: break

	return '\n'.join( retval )

#                  ████████ ███████ ███████ ████████ ███████                   #
#                     ██    ██      ██         ██    ██                        #
#                     ██    █████   ███████    ██    ███████                   #
#                     ██    ██           ██    ██         ██                   #
#                     ██    ███████ ███████    ██    ███████                   #
func                        __________TESTS__________              ()->void:pass

func TEST_EQ( want_v : Variant, got_v : Variant, desc : String = "" ) -> int:
	if want_v == got_v:
		logd("TEST_EQ('%s' == '%s'): %s" % [want_v, got_v, desc])
		return TEST_OK
	var msg := "[b][color=salmon]Failed: '%s'[/color][/b]\nwanted: '%s'\n   got: '%s'" % [desc, want_v, got_v ]
	output.append.call( msg )
	if _verbose: print_rich( msg )
	return TEST_FAILED

func TEST_APPROX( want_v : float, got_v : float, desc : String = "" ) -> int:
	if is_equal_approx(want_v, got_v):
		logd("TEST_APPROX('%s' ~= '%s'): %s" % [want_v, got_v, desc])
		return TEST_OK
	var msg := "[b][color=salmon]TEST_EQ Failed: '%s'[/color][/b]\nwanted: '%s'\n   got: '%s'" % [desc, want_v, got_v ]
	output.append.call( msg )
	if _verbose: print_rich( msg )
	return TEST_FAILED


func TEST_TRUE( value : Variant, desc : String = "" ) -> int:
	if value:
		logd("TEST_TRUE('%s'): %s" % [value, desc])
		return TEST_OK
	var msg : String = "[b][color=salmon]TEST_TRUE Failed: '%s'[/color][/b]\nwanted: true | value != (0 & null)\n   got: '%s'" % [desc, value ]
	output.append.call( msg )
	if _verbose: print_rich( msg )
	return TEST_FAILED

func TEST_OP( val1 : Variant, op : int, val2 : Variant, desc : String = ""  ) -> int:
	var op_s : String
	var op_result : bool = false
	match op:
		OP_EQUAL:  op_s='==';  op_result = val1 == val2
		OP_NOT_EQUAL: op_s='!='; op_result = val1 != val2
		OP_GREATER_EQUAL: op_s='>='; op_result = val1 >= val2
		OP_GREATER:  op_s='>';  op_result = val1 > val2
		OP_LESS_EQUAL: op_s='<='; op_result = val1 <= val2
		OP_LESS:  op_s='<';  op_result = val1 < val2
	if op_result: return TEST_OK
	var msg : String = "[b][color=salmon]TEST_OP Failed: '%s'[/color][/b]" % desc
	msg += "\n\tOp: ('%s' %s '%s') is false" % [val1, op_s, val2]
	output.append.call( msg )
	if _verbose: print_rich( msg )
	return TEST_FAILED
