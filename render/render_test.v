module render

fn test_fixed_point_scaling() {
	assert fixed(1.0) == 65536
	assert fixed(0.5) == 32768
	assert fixed(-2.0) == -131072
	assert fixed(0.0) == 0
}
