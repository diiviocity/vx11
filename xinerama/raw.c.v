// Public API from X11/extensions/Xinerama.h. The C headers own the ABI.
module xinerama

import vx11

#flag -lXinerama
#include <X11/extensions/Xinerama.h>

@[typedef]
pub struct C.XineramaScreenInfo {
pub mut:
	screen_number i32
	x_org         i16
	y_org         i16
	width         i16
	height        i16
}

pub type XineramaScreenInfo = C.XineramaScreenInfo

fn C.XineramaQueryExtension(&vx11.Display, &i32, &i32) i32
fn C.XineramaQueryVersion(&vx11.Display, &i32, &i32) i32
fn C.XineramaIsActive(&vx11.Display) i32
fn C.XineramaQueryScreens(&vx11.Display, &i32) &XineramaScreenInfo

pub fn query_extension(display &vx11.Display, event_base &i32, error_base &i32) i32 {
	return C.XineramaQueryExtension(display, event_base, error_base)
}

pub fn query_version(display &vx11.Display, major &i32, minor &i32) i32 {
	return C.XineramaQueryVersion(display, major, minor)
}

pub fn is_active(display &vx11.Display) i32 { return C.XineramaIsActive(display) }

// The returned array belongs to the caller; release it with vx11.free.
pub fn query_screens(display &vx11.Display, count &i32) &XineramaScreenInfo {
	return C.XineramaQueryScreens(display, count)
}
