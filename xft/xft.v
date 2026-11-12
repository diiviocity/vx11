module xft

import vx11
import vx11.fontconfig

fn valid_string(text string) ! {
	if text.contains('\x00') { return error('font name cannot contain NUL') }
}

fn valid_position(x int, y int) ! {
	if x < -2147483648 || x > 2147483647 || y < -2147483648 || y > 2147483647 {
		return error('position exceeds C int range')
	}
}

fn text_length(text string) !i32 {
	if text.len > 0x7fffffff { return error('text exceeds C length range') }
	return i32(text.len)
}

@[heap; noinit]
pub struct Font {
	connection &vx11.Connection
mut:
	handle &XftFont = unsafe { nil }
}

pub fn open_font(connection &vx11.Connection, name string) !&Font {
	valid_string(name)!
	d := connection.raw()!
	font := font_open_name(d, vx11.default_screen(d), &char(name.str))
	if font == unsafe { nil } { return error('cannot open Xft font: ${name}') }
	return &Font{ connection: connection, handle: font }
}

// The request remains owned by the caller. Xft consumes only our matched copy.
pub fn open_pattern(connection &vx11.Connection, request &fontconfig.Pattern) !&Font {
	d := connection.raw()!
	mut request_copy := request.copy()!
	defer { request_copy.close() }
	raw := request_copy.raw()!
	if fontconfig.config_substitute(unsafe { nil }, raw, fontconfig.match_pattern) == 0 {
		return error('font substitution failed')
	}
	default_substitute(d, vx11.default_screen(d), raw)
	mut result := fontconfig.FcResult(fontconfig.result_no_match)
	matched := font_match(d, vx11.default_screen(d), raw, &result)
	if matched == unsafe { nil } { return error('cannot match Xft font') }
	font := font_open_pattern(d, matched)
	if font == unsafe { nil } {
		fontconfig.pattern_destroy(matched)
		return error('cannot open matched Xft font')
	}
	return &Font{ connection: connection, handle: font }
}

pub fn (f &Font) raw() !&XftFont {
	f.connection.raw()!
	if f.handle == unsafe { nil } { return error('Xft font is closed') }
	return f.handle
}

pub fn (mut f Font) close() {
	if f.handle != unsafe { nil } {
		if d := f.connection.raw() { font_close(d, f.handle) }
		f.handle = unsafe { nil }
	}
}

pub struct Metrics {
pub:
	ascent  int
	descent int
	height  int
	advance int
}

pub fn (f &Font) metrics() !Metrics {
	raw := f.raw()!
	return Metrics{int(raw.ascent), int(raw.descent), int(raw.height), int(raw.max_advance_width)}
}

pub struct Extents {
pub:
	width     int
	height    int
	x         int
	y         int
	x_advance int
	y_advance int
}

pub fn (f &Font) extents(text string) !Extents {
	raw := f.raw()!
	length := text_length(text)!
	mut info := XGlyphInfo{}
	text_extents_utf8(f.connection.raw()!, raw, text.str, length, &info)
	return Extents{int(info.width), int(info.height), int(info.x), int(info.y), int(info.xOff), int(info.yOff)}
}

pub fn (f &Font) contains(r rune) !bool {
	return char_exists(f.connection.raw()!, f.raw()!, u32(r)) != 0
}

pub fn (f &Font) glyph(r rune) !u32 { return char_index(f.connection.raw()!, f.raw()!, u32(r)) }

pub fn (f &Font) pattern() !&fontconfig.Pattern { return fontconfig.copy_pattern(f.raw()!.pattern) }

// Match a fallback constrained to a Unicode scalar. The caller owns the new font.
// Fontconfig cannot guarantee that an installed font covers every possible rune.
pub fn (f &Font) fallback(r rune) !&Font {
	mut request := f.pattern()!
	defer { request.close() }
	raw := request.raw()!
	fontconfig.pattern_del(raw, c'file')
	fontconfig.pattern_del(raw, c'index')
	mut chars := fontconfig.charset_for([r])!
	defer { chars.close() }
	request.set_charset(chars)!
	mut font := open_pattern(f.connection, request)!
	if !font.contains(r)! {
		font.close()
		return error('no installed font covers this character')
	}
	return font
}

// Draw borrows the drawable and connection; close it before freeing either.
// Visual and colormap must match the target drawable, including ARGB pixmaps.
@[heap; noinit]
pub struct Draw {
	connection &vx11.Connection
	visual     &vx11.Visual
	colormap   vx11.Colormap
mut:
	handle &XftDraw = unsafe { nil }
	colors []CachedColor
}

struct CachedColor {
	name string
mut:
	value XftColor
}

pub fn new_draw(connection &vx11.Connection, drawable vx11.Drawable, visual &vx11.Visual, colormap vx11.Colormap) !&Draw {
	handle := draw_create(connection.raw()!, drawable, visual, colormap)
	if handle == unsafe { nil } { return error('cannot create Xft drawing context') }
	return &Draw{ connection: connection, visual: visual, colormap: colormap, handle: handle }
}

pub fn for_window(connection &vx11.Connection, window &vx11.WindowHandle) !&Draw {
	mut a := vx11.XWindowAttributes{}
	if vx11.get_window_attributes(connection.raw()!, window.id, &a) == 0 {
		return error('cannot query Xft target window')
	}
	return new_draw(connection, vx11.Drawable(window.id), a.visual, a.colormap)
}

pub fn (draw &Draw) raw() !&XftDraw {
	draw.connection.raw()!
	if draw.handle == unsafe { nil } { return error('Xft draw context is closed') }
	return draw.handle
}

pub fn (mut draw Draw) close() {
	if draw.handle == unsafe { nil } { return }
	if d := draw.connection.raw() {
		for mut color in draw.colors { color_free(d, draw.visual, draw.colormap, &color.value) }
		draw_destroy(draw.handle)
	}
	draw.colors.clear()
	draw.handle = unsafe { nil }
}

fn (mut draw Draw) color(name string) !XftColor {
	valid_string(name)!
	draw.raw()!
	for color in draw.colors { if color.name == name { return color.value } }
	mut color := XftColor{}
	if color_alloc_name(draw.connection.raw()!, draw.visual, draw.colormap, &char(name.str), &color) == 0 {
		return error('cannot allocate Xft color: ${name}')
	}
	draw.colors << CachedColor{ name: name, value: color }
	return color
}

fn (draw &Draw) check_font(font &Font) !&XftFont {
	draw.raw()!
	if draw.connection != font.connection {
		return error('font and draw context belong to different connections')
	}
	return font.raw()
}

pub fn (mut draw Draw) text(font &Font, x int, y int, text string, color string) ! {
	valid_position(x, y)!
	raw := draw.check_font(font)!
	length := text_length(text)!
	ink := draw.color(color)!
	draw_string_utf8(draw.raw()!, &ink, raw, i32(x), i32(y), text.str, length)
}

pub fn (mut draw Draw) rectangle(x int, y int, width int, height int, color string) ! {
	valid_position(x, y)!
	if width < 0 || height < 0 || u64(width) > 0xffffffff || u64(height) > 0xffffffff {
		return error('invalid rectangle size')
	}
	ink := draw.color(color)!
	draw_rect(draw.raw()!, &ink, i32(x), i32(y), u32(width), u32(height))
}

pub fn (draw &Draw) clip(rectangles []vx11.XRectangle) ! {
	if rectangles.len > 0x7fffffff { return error('too many clip rectangles') }
	if draw_set_clip_rectangles(draw.raw()!, 0, 0, rectangles.data, i32(rectangles.len)) == 0 {
		return error('cannot set Xft clip')
	}
}

pub fn (draw &Draw) clear_clip() ! {
	if draw_set_clip(draw.raw()!, unsafe { nil }) == 0 { return error('cannot clear Xft clip') }
}

// The replacement drawable must have the same visual, depth, and colormap.
pub fn (draw &Draw) change(drawable vx11.Drawable) ! { draw_change(draw.raw()!, drawable) }

pub struct Glyph {
pub:
	font  &Font
	index u32
	x     int
	y     int
}

// Batched positioned glyphs support terminal cells and explicit fallback fonts.
pub fn (mut draw Draw) glyphs(glyphs []Glyph, color string) ! {
	if glyphs.len > 0x7fffffff { return error('too many glyphs') }
	mut specs := []XftGlyphFontSpec{cap: glyphs.len}
	for g in glyphs {
		if g.x < -32768 || g.x > 32767 || g.y < -32768 || g.y > 32767 {
			return error('glyph coordinates exceed Xft short range')
		}
		specs << XftGlyphFontSpec{ font: draw.check_font(g.font)!, glyph: g.index, x: i16(g.x), y: i16(g.y) }
	}
	ink := draw.color(color)!
	draw_glyph_font_spec(draw.raw()!, &ink, specs.data, i32(specs.len))
}
