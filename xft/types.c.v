module xft

import vx11
import vx11.fontconfig

#pkgconfig xft
#include <X11/Xft/Xft.h>
#include "@VMODROOT/xft/bridge.h"

@[typedef]
pub struct C.XftDraw {}

pub type XftDraw = C.XftDraw

@[typedef]
pub struct C.XftFontInfo {}

pub type XftFontInfo = C.XftFontInfo

@[typedef]
pub struct C.XftFont {
pub mut:
	ascent            i32
	descent           i32
	height            i32
	max_advance_width i32
	charset           &fontconfig.FcCharSet
	pattern           &fontconfig.FcPattern
}

pub type XftFont = C.XftFont

@[typedef]
pub struct C.XRenderColor {
pub mut:
	red   u16
	green u16
	blue  u16
	alpha u16
}

pub type XRenderColor = C.XRenderColor

@[typedef]
pub struct C.XftColor {
pub mut:
	pixel vx11.CULong
	color XRenderColor
}

pub type XftColor = C.XftColor

@[typedef]
pub struct C.XGlyphInfo {
pub mut:
	width  u16
	height u16
	x      i16
	y      i16
	xOff   i16
	yOff   i16
}

pub type XGlyphInfo = C.XGlyphInfo
pub type Picture = vx11.XID
pub type FT_UInt = u32
// Borrowed FreeType face: access through the raw lock_face/unlock_face pair.
pub type FT_Face = voidptr

@[typedef]
pub struct C.XftCharSpec {
pub mut:
	ucs4 u32
	x    i16
	y    i16
}

pub type XftCharSpec = C.XftCharSpec

@[typedef]
pub struct C.XftCharFontSpec {
pub mut:
	font &XftFont
	ucs4 u32
	x    i16
	y    i16
}

pub type XftCharFontSpec = C.XftCharFontSpec

@[typedef]
pub struct C.XftGlyphSpec {
pub mut:
	glyph u32
	x     i16
	y     i16
}

pub type XftGlyphSpec = C.XftGlyphSpec

@[typedef]
pub struct C.XftGlyphFontSpec {
pub mut:
	font  &XftFont
	glyph u32
	x     i16
	y     i16
}

pub type XftGlyphFontSpec = C.XftGlyphFontSpec
