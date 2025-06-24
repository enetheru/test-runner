@tool
extends TestBase

# This test should fail.
func _run_test() -> int:
	assert(false, "run command must fail to return")
	return RetCode.TEST_OK
