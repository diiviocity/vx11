module fontconfig

import math

fn valid_text(text string) ! {
	if text.contains('\x00') { return error('Fontconfig strings cannot contain NUL') }
}

pub fn initialize() ! { if fontconfig_init() == 0 { return error('cannot initialize Fontconfig') } }

// Pattern owns a Fontconfig reference. raw() is borrowed; close is idempotent.
@[heap; noinit]
pub struct Pattern {
mut:
	handle &FcPattern = unsafe { nil }
}

pub fn parse(name string) !&Pattern {
	valid_text(name)!
	initialize()!
	p := name_parse(name.str)
	if p == unsafe { nil } { return error('cannot parse font pattern') }
	return &Pattern{ handle: p }
}

pub fn new_pattern() !&Pattern {
	initialize()!
	p := pattern_create()
	if p == unsafe { nil } { return error('cannot allocate font pattern') }
	return &Pattern{ handle: p }
}

// copy_pattern retains no borrowed pointer from its caller.
pub fn copy_pattern(pattern &FcPattern) !&Pattern {
	p := pattern_duplicate(pattern)
	if p == unsafe { nil } { return error('cannot copy font pattern') }
	return &Pattern{ handle: p }
}

pub fn (p &Pattern) raw() !&FcPattern {
	if p.handle == unsafe { nil } { return error('font pattern is closed') }
	return p.handle
}

pub fn (mut p Pattern) close() {
	if p.handle != unsafe { nil } {
		pattern_destroy(p.handle)
		p.handle = unsafe { nil }
	}
}

pub fn (p &Pattern) copy() !&Pattern { return copy_pattern(p.raw()!) }

pub fn (p &Pattern) description() !string {
	text := name_unparse(p.raw()!)
	if text == unsafe { nil } { return error('cannot format font pattern') }
	defer { str_free(text) }
	return unsafe { text.vstring().clone() }
}

pub fn (p &Pattern) string_value(object string) !string {
	valid_text(object)!
	mut value := unsafe { &u8(nil) }
	if pattern_get_string(p.raw()!, &char(object.str), 0, &value) != result_match {
		return error('missing string property: ${object}')
	}
	return unsafe { value.vstring().clone() }
}

pub fn (p &Pattern) integer(object string) !int {
	valid_text(object)!
	mut value := i32(0)
	if pattern_get_integer(p.raw()!, &char(object.str), 0, &value) != result_match {
		return error('missing integer property: ${object}')
	}
	return int(value)
}

pub fn (p &Pattern) double_value(object string) !f64 {
	valid_text(object)!
	mut value := f64(0)
	if pattern_get_double(p.raw()!, &char(object.str), 0, &value) != result_match {
		return error('missing double property: ${object}')
	}
	return value
}

pub fn (p &Pattern) set_string(object string, value string) ! {
	valid_text(object)!
	valid_text(value)!
	raw := p.raw()!
	pattern_del(raw, &char(object.str))
	if pattern_add_string(raw, &char(object.str), value.str) == 0 {
		return error('cannot set font string')
	}
}

pub fn (p &Pattern) set_integer(object string, value int) ! {
	valid_text(object)!
	if value < -2147483648 || value > 2147483647 { return error('integer exceeds C int range') }
	raw := p.raw()!
	pattern_del(raw, &char(object.str))
	if pattern_add_integer(raw, &char(object.str), i32(value)) == 0 {
		return error('cannot set font integer')
	}
}

pub fn (p &Pattern) set_double(object string, value f64) ! {
	valid_text(object)!
	if math.is_nan(value) || math.is_inf(value, 0) { return error('font property must be finite') }
	raw := p.raw()!
	pattern_del(raw, &char(object.str))
	if pattern_add_double(raw, &char(object.str), value) == 0 {
		return error('cannot set font double')
	}
}

pub fn (p &Pattern) set_bool(object string, value bool) ! {
	valid_text(object)!
	raw := p.raw()!
	pattern_del(raw, &char(object.str))
	if pattern_add_bool(raw, &char(object.str), i32(value)) == 0 {
		return error('cannot set font boolean')
	}
}

// match_font works on a copy; substitutions do not mutate the request pattern.
pub fn (p &Pattern) match_font() !&Pattern {
	mut request := p.copy()!
	defer { request.close() }
	raw := request.raw()!
	if config_substitute(unsafe { nil }, raw, match_pattern) == 0 {
		return error('font substitution failed')
	}
	default_substitute(raw)
	mut result := FcResult(result_no_match)
	matched := font_match(unsafe { nil }, raw, &result)
	if matched == unsafe { nil } { return error('no matching font') }
	return &Pattern{ handle: matched }
}

@[heap; noinit]
pub struct Charset {
mut:
	handle &FcCharSet = unsafe { nil }
}

pub fn charset_for(runes []rune) !&Charset {
	p := char_set_create()
	if p == unsafe { nil } { return error('cannot allocate charset') }
	mut set := &Charset{ handle: p }
	for r in runes {
		set.add(r) or {
			set.close()
			return err
		}
	}
	return set
}

pub fn (set &Charset) raw() !&FcCharSet {
	if set.handle == unsafe { nil } { return error('charset is closed') }
	return set.handle
}

pub fn (mut set Charset) close() {
	if set.handle != unsafe { nil } {
		char_set_destroy(set.handle)
		set.handle = unsafe { nil }
	}
}

pub fn (set &Charset) add(r rune) ! {
	if r < 0 || r > 0x10ffff || (r >= 0xd800 && r <= 0xdfff) {
		return error('invalid Unicode scalar')
	}
	if char_set_add_char(set.raw()!, u32(r)) == 0 { return error('cannot add Unicode character') }
}

pub fn (set &Charset) contains(r rune) !bool { return char_set_has_char(set.raw()!, u32(r)) != 0 }

pub fn (p &Pattern) set_charset(set &Charset) ! {
	raw := p.raw()!
	chars := set.raw()!
	pattern_del(raw, c'charset')
	if pattern_add_char_set(raw, c'charset', chars) == 0 { return error('cannot set charset') }
}

@[heap; noinit]
pub struct FontSet {
mut:
	handle &FcFontSet = unsafe { nil }
}

pub fn (p &Pattern) sorted_fonts() !&FontSet {
	mut request := p.copy()!
	defer { request.close() }
	raw := request.raw()!
	if config_substitute(unsafe { nil }, raw, match_pattern) == 0 {
		return error('font substitution failed')
	}
	default_substitute(raw)
	mut result := FcResult(result_no_match)
	fonts := font_sort(unsafe { nil }, raw, 0, unsafe { nil }, &result)
	if fonts == unsafe { nil } { return error('font sorting failed') }
	return &FontSet{ handle: fonts }
}

pub fn (set &FontSet) len() !int {
	if set.handle == unsafe { nil } { return error('font set is closed') }
	return int(set.handle.nfont)
}

// Each returned pattern is an independent copy, owned by the caller.
pub fn (set &FontSet) pattern(index int) !&Pattern {
	count := set.len()!
	if index < 0 || index >= count { return error('font index is out of range') }
	return copy_pattern(unsafe { set.handle.fonts[index] })
}

pub fn (mut set FontSet) close() {
	if set.handle != unsafe { nil } {
		font_set_destroy(set.handle)
		set.handle = unsafe { nil }
	}
}

// release transfers this owned reference to a consuming C API, closing the wrapper.
pub fn (mut p Pattern) release() !&FcPattern {
	raw := p.raw()!
	p.handle = unsafe { nil }
	return raw
}
