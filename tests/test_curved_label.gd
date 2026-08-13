extends GutTest
## Тесты геометрии изогнутого текста.

const CurvedLabelScript = preload("res://entities/card/curved_label.gd")


func test_compute_radius_zero_angle_returns_zero() -> void:
	assert_eq(CurvedLabelScript.compute_radius(100.0, 0.0), 0.0)


func test_compute_radius_zero_width_returns_zero() -> void:
	assert_eq(CurvedLabelScript.compute_radius(0.0, 20.0), 0.0)


func test_compute_radius_larger_angle_gives_smaller_radius() -> void:
	var r_gentle = CurvedLabelScript.compute_radius(100.0, 10.0)
	var r_sharp = CurvedLabelScript.compute_radius(100.0, 40.0)
	assert_true(r_sharp < r_gentle, "Больший угол дуги должен давать меньший радиус")


func test_compute_char_placements_empty_widths_returns_empty() -> void:
	var placements = CurvedLabelScript.compute_char_placements([], 100.0, Vector2.ZERO)
	assert_eq(placements.size(), 0)


func test_compute_char_placements_zero_radius_keeps_theta_zero_for_all_chars() -> void:
	var widths: Array[float] = [10.0, 10.0, 10.0]
	var placements = CurvedLabelScript.compute_char_placements(widths, 0.0, Vector2.ZERO)
	assert_eq(placements.size(), 3)
	for p in placements:
		assert_eq(p["theta"], 0.0)


func test_compute_char_placements_middle_char_of_odd_string_has_zero_theta() -> void:
	var widths: Array[float] = [10.0, 10.0, 10.0]
	var placements = CurvedLabelScript.compute_char_placements(widths, 100.0, Vector2.ZERO)
	assert_almost_eq(
		placements[1]["theta"], 0.0, 0.0001, "Средний символ должен быть в вершине дуги"
	)


func test_compute_char_placements_symmetric_for_symmetric_widths() -> void:
	var widths: Array[float] = [10.0, 10.0, 10.0, 10.0]
	var placements = CurvedLabelScript.compute_char_placements(widths, 100.0, Vector2.ZERO)
	assert_almost_eq(placements[0]["theta"], -placements[3]["theta"], 0.0001)
	assert_almost_eq(placements[1]["theta"], -placements[2]["theta"], 0.0001)


func test_compute_char_placements_thetas_increase_left_to_right() -> void:
	var widths: Array[float] = [8.0, 12.0, 6.0, 15.0, 9.0]
	var placements = CurvedLabelScript.compute_char_placements(widths, 200.0, Vector2.ZERO)
	for i in range(1, placements.size()):
		assert_true(
			placements[i]["theta"] > placements[i - 1]["theta"],
			"theta должна монотонно расти по мере движения слева направо"
		)


func test_compute_char_placements_positions_lie_on_the_circle() -> void:
	var widths: Array[float] = [10.0, 14.0, 8.0, 20.0]
	var radius := 150.0
	var center := Vector2(75, 300)
	var placements = CurvedLabelScript.compute_char_placements(widths, radius, center)
	for p in placements:
		var dist = (p["pos"] as Vector2).distance_to(center)
		assert_almost_eq(
			dist, radius, 0.01, "Точка символа должна лежать на окружности заданного радиуса"
		)


func test_compute_char_placements_apex_char_sits_directly_above_center() -> void:
	var widths: Array[float] = [10.0, 10.0, 10.0]
	var radius := 100.0
	var center := Vector2(50, 200)
	var placements = CurvedLabelScript.compute_char_placements(widths, radius, center)
	var apex: Vector2 = placements[1]["pos"]
	assert_almost_eq(apex.x, center.x, 0.01)
	assert_almost_eq(apex.y, center.y - radius, 0.01)


func test_compute_jitter_returns_one_entry_per_character() -> void:
	var jitter = CurvedLabelScript.compute_jitter(5, 2.0, 4.0, 1)
	assert_eq(jitter.size(), 5)


func test_compute_jitter_zero_amount_gives_zero_offsets() -> void:
	var jitter = CurvedLabelScript.compute_jitter(4, 0.0, 0.0, 42)
	for j in jitter:
		assert_eq(j["dx"], 0.0)
		assert_eq(j["dy"], 0.0)
		assert_eq(j["drot"], 0.0)


func test_compute_jitter_same_seed_is_deterministic() -> void:
	var a = CurvedLabelScript.compute_jitter(6, 3.0, 8.0, 777)
	var b = CurvedLabelScript.compute_jitter(6, 3.0, 8.0, 777)
	for i in a.size():
		assert_eq(a[i]["dx"], b[i]["dx"])
		assert_eq(a[i]["dy"], b[i]["dy"])
		assert_eq(a[i]["drot"], b[i]["drot"])


func test_compute_jitter_different_seeds_usually_differ() -> void:
	var a = CurvedLabelScript.compute_jitter(6, 3.0, 8.0, 1)
	var b = CurvedLabelScript.compute_jitter(6, 3.0, 8.0, 2)
	var all_equal := true
	for i in a.size():
		if a[i]["dx"] != b[i]["dx"]:
			all_equal = false
			break
	assert_false(all_equal, "Разные seed почти наверняка должны давать разные смещения")


func test_compute_jitter_offsets_stay_within_bounds() -> void:
	var position_amount := 2.5
	var rotation_amount := 6.0
	var jitter = CurvedLabelScript.compute_jitter(20, position_amount, rotation_amount, 99)
	for j in jitter:
		assert_true(abs(j["dx"]) <= position_amount)
		assert_true(abs(j["dy"]) <= position_amount)
		assert_true(abs(j["drot"]) <= deg_to_rad(rotation_amount) + 0.0001)


func test_compute_float_offset_zero_amplitude_is_always_zero() -> void:
	assert_eq(CurvedLabelScript.compute_float_offset(0, 5.0, 0.0, 1.0), 0.0)
	assert_eq(CurvedLabelScript.compute_float_offset(3, 100.0, 0.0, 2.5), 0.0)


func test_compute_float_offset_matches_sine_formula() -> void:
	var index := 2
	var time := 1.3
	var amplitude := 4.0
	var speed := 1.5
	var expected := amplitude * sin(time * speed + index * 0.9)
	assert_almost_eq(
		CurvedLabelScript.compute_float_offset(index, time, amplitude, speed), expected, 0.0001
	)


func test_compute_float_offset_stays_within_amplitude_bounds() -> void:
	var amplitude := 3.0
	for i in range(10):
		for t_step in range(20):
			var t: float = t_step * 0.37
			var offset = CurvedLabelScript.compute_float_offset(i, t, amplitude, 1.0)
			assert_true(abs(offset) <= amplitude + 0.0001)


func test_compute_float_offset_different_indices_differ_at_same_time() -> void:
	var a = CurvedLabelScript.compute_float_offset(0, 2.0, 3.0, 1.0)
	var b = CurvedLabelScript.compute_float_offset(1, 2.0, 3.0, 1.0)
	assert_ne(a, b)


func test_fitted_font_size_keeps_preferred_size_when_text_fits() -> void:
	assert_eq(CurvedLabelScript.compute_fitted_font_size(100.0, 120.0, 26, 16), 26)


func test_fitted_font_size_scales_down_proportionally() -> void:
	assert_eq(CurvedLabelScript.compute_fitted_font_size(150.0, 120.0, 26, 16), 20)


func test_fitted_font_size_never_drops_below_minimum() -> void:
	assert_eq(CurvedLabelScript.compute_fitted_font_size(400.0, 100.0, 26, 16), 16)
