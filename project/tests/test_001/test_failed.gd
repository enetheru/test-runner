@tool
extends TestBase

# This test should fail.
func _run_test() -> int:
	return RetCode.TEST_FAILED
