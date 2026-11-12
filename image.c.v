module vx11

// Xutil exposes these as macros invoking XImage's function table.
fn C.XDestroyImage(&XImage) i32
fn C.XGetPixel(&XImage, i32, i32) CULong
fn C.XPutPixel(&XImage, i32, i32, CULong) i32
fn C.XSubImage(&XImage, i32, i32, u32, u32) &XImage
fn C.XAddPixel(&XImage, CLong) i32

pub fn destroy_image(image &XImage) i32 { return C.XDestroyImage(image) }

pub fn get_pixel(image &XImage, x i32, y i32) CULong { return C.XGetPixel(image, x, y) }

pub fn put_pixel(image &XImage, x i32, y i32, pixel CULong) i32 {
	return C.XPutPixel(image, x, y, pixel)
}

pub fn sub_image(image &XImage, x i32, y i32, width u32, height u32) &XImage {
	return C.XSubImage(image, x, y, width, height)
}

pub fn add_pixel(image &XImage, value CLong) i32 { return C.XAddPixel(image, value) }

// XUniqueContext is an Xutil macro backed by the resource quark allocator.
pub fn unique_context() XContext { return XContext(xrm_unique_quark()) }
