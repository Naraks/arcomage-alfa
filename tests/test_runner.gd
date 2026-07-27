extends RefCounted

func run_tests():
	print("--- Running tests ---")
	test_apply_damage()
	print("--- All tests passed! ---")

func test_apply_damage():
	print("Running test_apply_damage...")
	var player = PlayerData.new()
	player.tower_hp = 20
	player.wall_hp = 5
	
	# Test damage against wall
	MatchManager.apply_damage(3, player, false)
	assert(player.wall_hp == 2, "Wall should be 2")
	assert(player.tower_hp == 20, "Tower should be 20")
	
	# Test damage that breaks wall and hits tower
	MatchManager.apply_damage(5, player, false)
	assert(player.wall_hp == 0, "Wall should be 0")
	assert(player.tower_hp == 17, "Tower should be 17")
	
	# Test ignore_wall
	MatchManager.apply_damage(5, player, true)
	assert(player.tower_hp == 12, "Tower should be 12")
	
	print("test_apply_damage passed!")
