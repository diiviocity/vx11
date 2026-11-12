// Public API from X11/extensions/Xcomposite.h. Raw calls retain Xlib error semantics.
module composite

import vx11

#flag -lXcomposite
#include <X11/extensions/Xcomposite.h>

pub const redirect_automatic = 0
pub const redirect_manual = 1

fn C.XCompositeQueryExtension(&vx11.Display, &i32, &i32) i32
fn C.XCompositeQueryVersion(&vx11.Display, &i32, &i32) i32
fn C.XCompositeVersion() i32
fn C.XCompositeRedirectWindow(&vx11.Display, vx11.Window, i32)
fn C.XCompositeRedirectSubwindows(&vx11.Display, vx11.Window, i32)
fn C.XCompositeUnredirectWindow(&vx11.Display, vx11.Window, i32)
fn C.XCompositeUnredirectSubwindows(&vx11.Display, vx11.Window, i32)
fn C.XCompositeNameWindowPixmap(&vx11.Display, vx11.Window) vx11.Pixmap
fn C.XCompositeGetOverlayWindow(&vx11.Display, vx11.Window) vx11.Window
fn C.XCompositeReleaseOverlayWindow(&vx11.Display, vx11.Window)

pub fn query_extension(d &vx11.Display, events &i32, errors &i32) i32 {
	return C.XCompositeQueryExtension(d, events, errors)
}

pub fn query_version(d &vx11.Display, major &i32, minor &i32) i32 {
	return C.XCompositeQueryVersion(d, major, minor)
}

pub fn version() i32 { return C.XCompositeVersion() }

pub fn redirect_window(d &vx11.Display, w vx11.Window, mode i32) {
	C.XCompositeRedirectWindow(d, w, mode)
}

pub fn redirect_subwindows(d &vx11.Display, w vx11.Window, mode i32) {
	C.XCompositeRedirectSubwindows(d, w, mode)
}

pub fn unredirect_window(d &vx11.Display, w vx11.Window, mode i32) {
	C.XCompositeUnredirectWindow(d, w, mode)
}

pub fn unredirect_subwindows(d &vx11.Display, w vx11.Window, mode i32) {
	C.XCompositeUnredirectSubwindows(d, w, mode)
}

// Caller owns the named pixmap and must release it with vx11.free_pixmap.
pub fn name_window_pixmap(d &vx11.Display, w vx11.Window) vx11.Pixmap {
	return C.XCompositeNameWindowPixmap(d, w)
}

pub fn get_overlay_window(d &vx11.Display, w vx11.Window) vx11.Window {
	return C.XCompositeGetOverlayWindow(d, w)
}

pub fn release_overlay_window(d &vx11.Display, w vx11.Window) {
	C.XCompositeReleaseOverlayWindow(d, w)
}

fn C.XCompositeCreateRegionFromBorderClip(&vx11.Display, vx11.Window) vx11.XID

// Caller owns the returned XFixes region. Release through XFixesDestroyRegion.
pub fn create_region_from_border_clip(d &vx11.Display, w vx11.Window) vx11.XID {
	return C.XCompositeCreateRegionFromBorderClip(d, w)
}
