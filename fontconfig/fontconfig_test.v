module fontconfig

fn test_patterns_charset_and_owned_copies() {
	mut pattern := parse('monospace:pixelsize=20')!
	defer { pattern.close() }
	assert pattern.string_value(family)! == 'monospace'
	pattern.set_integer(weight, weight_bold)!
	pattern.set_double(pixel_size, 22)!
	pattern.set_bool(antialias, true)!
	assert pattern.integer(weight)! == weight_bold
	assert pattern.double_value(pixel_size)! == 22
	mut chars := charset_for([`A`, `Ω`])!
	assert chars.contains(`Ω`)!
	pattern.set_charset(chars)!
	chars.close()
	chars.close()
	mut matched := pattern.match_font()!
	assert matched.string_value(file)!.len > 0
	name := matched.string_value(family)!
	matched.close()
	assert name.len > 0
	mut set := pattern.sorted_fonts()!
	assert set.len()! > 0
	mut first := set.pattern(0)!
	set.close()
	assert first.string_value(file)!.len > 0
	first.close()
	mut copy := pattern.copy()!
	raw := copy.release()!
	pattern_destroy(raw)
	mut closed := false
	copy.raw() or { closed = true }
	assert closed
	pattern.close()
	pattern.close()
	mut rejected := false
	pattern.description() or { rejected = true }
	assert rejected
}

fn test_invalid_strings_and_unicode() {
	mut rejected := false
	parse('mono\x00space') or { rejected = true }
	assert rejected
	mut set := charset_for([]rune{})!
	defer { set.close() }
	mut bad_scalar := false
	set.add(rune(0xd800)) or { bad_scalar = true }
	assert bad_scalar
}
