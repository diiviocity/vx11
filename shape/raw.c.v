// Public API from X11/extensions/shape.h and shapeconst.h.
module shape

import vx11

#flag -lXext
#include <X11/extensions/shape.h>

pub const name = 'SHAPE'
pub const major_version = 1
pub const minor_version = 1
pub const shape_set = 0
pub const shape_union = 1
pub const shape_intersect = 2
pub const shape_subtract = 3
pub const shape_invert = 4
pub const shape_bounding = 0
pub const shape_clip = 1
pub const shape_input = 2
pub const notify_mask = 1
pub const notify = 0
pub const number_events = 1

@[typedef]
pub struct C.XShapeEvent {
pub mut:
	@type      i32
	serial     vx11.CULong
	send_event i32
	display    &vx11.Display
	window     vx11.Window
	kind       i32
	x          i32
	y          i32
	width      u32
	height     u32
	time       vx11.Time
	shaped     i32
}

pub type XShapeEvent = C.XShapeEvent

fn C.XShapeQueryExtension(&vx11.Display, &i32, &i32) i32
fn C.XShapeQueryVersion(&vx11.Display, &i32, &i32) i32
fn C.XShapeCombineRegion(&vx11.Display, vx11.Window, i32, i32, i32, vx11.Region, i32)
fn C.XShapeCombineRectangles(&vx11.Display, vx11.Window, i32, i32, i32, &vx11.XRectangle, i32, i32, i32)
fn C.XShapeCombineMask(&vx11.Display, vx11.Window, i32, i32, i32, vx11.Pixmap, i32)
fn C.XShapeCombineShape(&vx11.Display, vx11.Window, i32, i32, i32, vx11.Window, i32, i32)
fn C.XShapeOffsetShape(&vx11.Display, vx11.Window, i32, i32, i32)
fn C.XShapeQueryExtents(&vx11.Display, vx11.Window, &i32, &i32, &i32, &u32, &u32, &i32, &i32, &i32, &u32, &u32) i32
fn C.XShapeSelectInput(&vx11.Display, vx11.Window, vx11.CULong)
fn C.XShapeInputSelected(&vx11.Display, vx11.Window) vx11.CULong
fn C.XShapeGetRectangles(&vx11.Display, vx11.Window, i32, &i32, &i32) &vx11.XRectangle

pub fn query_extension(d &vx11.Display, event_base &i32, error_base &i32) i32 {
	return C.XShapeQueryExtension(d, event_base, error_base)
}

pub fn query_version(d &vx11.Display, major &i32, minor &i32) i32 {
	return C.XShapeQueryVersion(d, major, minor)
}

pub fn combine_region(d &vx11.Display, w vx11.Window, kind i32, x i32, y i32, region vx11.Region, op i32) {
	C.XShapeCombineRegion(d, w, kind, x, y, region, op)
}

pub fn combine_rectangles(d &vx11.Display, w vx11.Window, kind i32, x i32, y i32, rectangles &vx11.XRectangle, count i32, op i32, ordering i32) {
	C.XShapeCombineRectangles(d, w, kind, x, y, rectangles, count, op, ordering)
}

pub fn combine_mask(d &vx11.Display, w vx11.Window, kind i32, x i32, y i32, pixmap vx11.Pixmap, op i32) {
	C.XShapeCombineMask(d, w, kind, x, y, pixmap, op)
}

pub fn combine_shape(d &vx11.Display, w vx11.Window, kind i32, x i32, y i32, source vx11.Window, source_kind i32, op i32) {
	C.XShapeCombineShape(d, w, kind, x, y, source, source_kind, op)
}

pub fn offset_shape(d &vx11.Display, w vx11.Window, kind i32, x i32, y i32) {
	C.XShapeOffsetShape(d, w, kind, x, y)
}

pub fn query_extents(d &vx11.Display, w vx11.Window, bounding_shaped &i32, bx &i32, by &i32, bw &u32, bh &u32, clip_shaped &i32, cx &i32, cy &i32, cw &u32, ch &u32) i32 {
	return C.XShapeQueryExtents(d, w, bounding_shaped, bx, by, bw, bh, clip_shaped, cx, cy, cw, ch)
}

pub fn select_input(d &vx11.Display, w vx11.Window, mask vx11.CULong) {
	C.XShapeSelectInput(d, w, mask)
}

pub fn input_selected(d &vx11.Display, w vx11.Window) vx11.CULong {
	return C.XShapeInputSelected(d, w)
}

// The returned rectangle array must be released with vx11.free.
pub fn get_rectangles(d &vx11.Display, w vx11.Window, kind i32, count &i32, ordering &i32) &vx11.XRectangle {
	return C.XShapeGetRectangles(d, w, kind, count, ordering)
}
