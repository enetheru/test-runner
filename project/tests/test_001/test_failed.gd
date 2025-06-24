@tool
extends TestBase

# This test should fail.
func _run_test() -> RetCode:
	return RetCode.TEST_FAILED
