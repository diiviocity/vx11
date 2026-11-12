// Optional XRender operations; linkage is not added to core vx11.
module render

import vx11

#flag -lXrender
#include <X11/extensions/Xrender.h>
#include "@VMODROOT/render/bridge.h"

pub type Picture = vx11.XID

@[typedef]
pub struct C.XRenderPictFormat {}

pub type Format = C.XRenderPictFormat

fn C.XRenderQueryExtension(&vx11.Display, &i32, &i32) i32
fn C.XRenderQueryVersion(&vx11.Display, &i32, &i32) i32
fn C.XRenderFindVisualFormat(&vx11.Display, &vx11.Visual) &Format
fn C.XRenderFindStandardFormat(&vx11.Display, i32) &Format
fn C.XRenderFreePicture(&vx11.Display, Picture)
fn C.XRenderComposite(&vx11.Display, i32, Picture, Picture, Picture, i32, i32, i32, i32, i32, i32, u32, u32)
fn C.vx11_render_backdrop(&vx11.Display, int, int, int, int) vx11.Pixmap

pub fn query_extension(d &vx11.Display, events &i32, errors &i32) i32 {
	return C.XRenderQueryExtension(d, events, errors)
}

pub fn query_version(d &vx11.Display, major &i32, minor &i32) i32 {
	return C.XRenderQueryVersion(d, major, minor)
}

pub fn available(c &vx11.Connection) !bool {
	mut events := i32(0)
	mut errors := i32(0)
	return query_extension(c.raw()!, &events, &errors) != 0
}

pub fn find_visual_format(d &vx11.Display, visual &vx11.Visual) &Format {
	return C.XRenderFindVisualFormat(d, visual)
}

pub fn find_standard_format(d &vx11.Display, format i32) &Format {
	return C.XRenderFindStandardFormat(d, format)
}

pub fn free_picture(d &vx11.Display, picture Picture) { C.XRenderFreePicture(d, picture) }

pub fn composite(d &vx11.Display, op i32, src Picture, mask Picture, dst Picture, sx i32, sy i32, mx i32, my i32, dx i32, dy i32, width u32, height u32) {
	C.XRenderComposite(d, op, src, mask, dst, sx, sy, mx, my, dx, dy, width, height)
}

// dimmed_snapshot copies a visible root region and applies a dark translucent
// tint. Capture before mapping an overlay. Caller owns the returned pixmap and
// must free it before closing c. Target uses the default screen visual/depth.
pub fn dimmed_snapshot(c &vx11.Connection, x int, y int, width int, height int) !vx11.Pixmap {
	if !available(c)! { return error('XRender extension is unavailable') }
	sw, sh := c.dimensions()!
	if x < 0 || y < 0 || width <= 0 || height <= 0 || width > sw || height > sh || x > sw - width || y > sh - height {
		return error('snapshot region is outside the root window')
	}
	return C.vx11_render_backdrop(c.raw()!, x, y, width, height)
}

// Selected raw XRender picture operations. All returned pictures are owned by
// the caller and must be freed before their display. Formats are borrowed.
pub const op_src = 1
pub const op_over = 3
pub const standard_argb32 = 0
pub const standard_rgb24 = 1
pub const standard_a8 = 2
pub const filter_nearest = 'nearest'
pub const filter_bilinear = 'bilinear'

@[typedef]
pub struct C.XTransform {
pub mut:
	matrix [3][3]i32
}

pub type Transform = C.XTransform

@[typedef]
pub struct C.XRenderPictureAttributes {
pub mut:
	repeat             i32
	alpha_map          Picture
	alpha_x_origin     i32
	alpha_y_origin     i32
	clip_x_origin      i32
	clip_y_origin      i32
	clip_mask          vx11.Pixmap
	graphics_exposures i32
	subwindow_mode     i32
	poly_edge          i32
	poly_mode          i32
	dither             vx11.Atom
	component_alpha    i32
}

pub type PictureAttributes = C.XRenderPictureAttributes

fn C.XRenderCreatePicture(&vx11.Display, vx11.Drawable, &Format, vx11.CULong, &PictureAttributes) Picture
fn C.XRenderChangePicture(&vx11.Display, Picture, vx11.CULong, &PictureAttributes)
fn C.XRenderSetPictureTransform(&vx11.Display, Picture, &Transform)
fn C.XRenderSetPictureFilter(&vx11.Display, Picture, &char, &i32, i32)
fn C.XRenderSetPictureClipRectangles(&vx11.Display, Picture, i32, i32, &vx11.XRectangle, i32)

pub fn create_picture(d &vx11.Display, drawable vx11.Drawable, format &Format, mask vx11.CULong, attributes &PictureAttributes) Picture {
	return C.XRenderCreatePicture(d, drawable, format, mask, attributes)
}

pub fn change_picture(d &vx11.Display, picture Picture, mask vx11.CULong, attributes &PictureAttributes) {
	C.XRenderChangePicture(d, picture, mask, attributes)
}

pub fn set_picture_transform(d &vx11.Display, picture Picture, transform &Transform) {
	C.XRenderSetPictureTransform(d, picture, transform)
}

pub fn set_picture_filter(d &vx11.Display, picture Picture, filter &char, params &i32, count i32) {
	C.XRenderSetPictureFilter(d, picture, filter, params, count)
}

pub fn set_picture_clip_rectangles(d &vx11.Display, picture Picture, x i32, y i32, rectangles &vx11.XRectangle, count i32) {
	C.XRenderSetPictureClipRectangles(d, picture, x, y, rectangles, count)
}

// fixed converts a floating point scale/coordinate to XRender 16.16 notation.
pub fn fixed(value f64) i32 { return i32(value * 65536.0) }
