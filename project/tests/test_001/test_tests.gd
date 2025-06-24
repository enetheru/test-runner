@tool
extends TestBase

# This test should Succeed
func _run_test() -> RetCode:
	runcode &= TEST_TRUE( true )

	runcode &= TEST_EQ( 1, 1, "Testing EQUAL")

	runcode &= TEST_OP( 1, OP_EQUAL, 1, "Testing OP_EQUAL = true")
	runcode &= TEST_OP( 1, OP_NOT_EQUAL, 0, "Testing OP_NOT_EQUAL = true")
	runcode &= TEST_OP( 1, OP_GREATER_EQUAL, 0, "Testing OP_GREATER_EQUAL = true")
	runcode &= TEST_OP( 1, OP_GREATER_EQUAL, 1, "Testing OP_GREATER_EQUAL = true")
	runcode &= TEST_OP( 1, OP_GREATER, 0, "Testing OP_GREATER = true")
	runcode &= TEST_OP( 0, OP_LESS_EQUAL, 1, "Testing OP_LESS_EQUAL = true")
	runcode &= TEST_OP( 1, OP_LESS_EQUAL, 1, "Testing OP_LESS_EQUAL = true")
	runcode &= TEST_OP( 0, OP_LESS, 1, "Testing OP_LESS = true")

	# This will spit errors, but the test will succeed.
	runcode &= ~TEST_OP( 1, OP_EQUAL, 0, "Testing OP_EQUAL = false")
	runcode &= ~TEST_OP( 1, OP_NOT_EQUAL, 1, "Testing OP_NOT_EQUAL = false")
	runcode &= ~TEST_OP( 0, OP_GREATER_EQUAL, 1, "Testing OP_GREATER_EQUAL = false")
	runcode &= ~TEST_OP( 0, OP_GREATER, 1, "Testing OP_GREATER = false")
	runcode &= ~TEST_OP( 1, OP_LESS_EQUAL, 0, "Testing OP_LESS_EQUAL = false")
	runcode &= ~TEST_OP( 1, OP_LESS, 0, "Testing OP_LESS = false")

	runcode &= TEST_APPROX(1.1,1.1,"Testing APPROX")

	return runcode
