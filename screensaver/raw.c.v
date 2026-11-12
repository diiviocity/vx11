// Public API from X11/extensions/scrnsaver.h and saver.h.
module screensaver

import vx11

#flag -lXss
#include <X11/extensions/scrnsaver.h>

pub const name = 'MIT-SCREEN-SAVER'
pub const property_name = '_MIT_SCREEN_SAVER_ID'
pub const notify_mask = 1
pub const cycle_mask = 2
pub const major_version = 1
pub const minor_version = 1
pub const off = 0
pub const on = 1
pub const cycle = 2
pub const disabled = 3
pub const blanked = 0
pub const internal = 1
pub const external = 2
pub const notify = 0
pub const number_events = 1

@[typedef]
pub struct C.XScreenSaverNotifyEvent {
pub mut:
	@type      i32
	serial     vx11.CULong
	send_event i32
	display    &vx11.Display
	window     vx11.Window
	root       vx11.Window
	state      i32
	kind       i32
	forced     i32
	time       vx11.Time
}

pub type XScreenSaverNotifyEvent = C.XScreenSaverNotifyEvent

@[typedef]
pub struct C.XScreenSaverInfo {
pub mut:
	window       vx11.Window
	state        i32
	kind         i32
	til_or_since vx11.CULong
	idle         vx11.CULong
	eventMask    vx11.CULong
}

pub type XScreenSaverInfo = C.XScreenSaverInfo

fn C.XScreenSaverQueryExtension(&vx11.Display, &i32, &i32) i32
fn C.XScreenSaverQueryVersion(&vx11.Display, &i32, &i32) i32
fn C.XScreenSaverAllocInfo() &XScreenSaverInfo
fn C.XScreenSaverQueryInfo(&vx11.Display, vx11.Drawable, &XScreenSaverInfo) i32
fn C.XScreenSaverSelectInput(&vx11.Display, vx11.Drawable, vx11.CULong)
fn C.XScreenSaverSetAttributes(&vx11.Display, vx11.Drawable, i32, i32, u32, u32, u32, i32, u32, &vx11.Visual, vx11.CULong, &vx11.XSetWindowAttributes)
fn C.XScreenSaverUnsetAttributes(&vx11.Display, vx11.Drawable)
fn C.XScreenSaverRegister(&vx11.Display, i32, vx11.XID, vx11.Atom) i32
fn C.XScreenSaverUnregister(&vx11.Display, i32) i32
fn C.XScreenSaverGetRegistered(&vx11.Display, i32, &vx11.XID, &vx11.Atom) i32
fn C.XScreenSaverSuspend(&vx11.Display, i32)

pub fn query_extension(d &vx11.Display, events &i32, errors &i32) i32 {
	return C.XScreenSaverQueryExtension(d, events, errors)
}

pub fn query_version(d &vx11.Display, major &i32, minor &i32) i32 {
	return C.XScreenSaverQueryVersion(d, major, minor)
}

// Caller owns the result; free it with vx11.free.
pub fn alloc_info() &XScreenSaverInfo { return C.XScreenSaverAllocInfo() }

pub fn query_info(d &vx11.Display, drawable vx11.Drawable, info &XScreenSaverInfo) i32 {
	return C.XScreenSaverQueryInfo(d, drawable, info)
}

pub fn select_input(d &vx11.Display, drawable vx11.Drawable, mask vx11.CULong) {
	C.XScreenSaverSelectInput(d, drawable, mask)
}

pub fn set_attributes(d &vx11.Display, drawable vx11.Drawable, x i32, y i32, width u32, height u32, border_width u32, depth i32, class u32, visual &vx11.Visual, mask vx11.CULong, attributes &vx11.XSetWindowAttributes) {
	C.XScreenSaverSetAttributes(d, drawable, x, y, width, height, border_width, depth, class, visual, mask, attributes)
}

pub fn unset_attributes(d &vx11.Display, drawable vx11.Drawable) {
	C.XScreenSaverUnsetAttributes(d, drawable)
}

pub fn register(d &vx11.Display, screen i32, xid vx11.XID, typ vx11.Atom) i32 {
	return C.XScreenSaverRegister(d, screen, xid, typ)
}

pub fn unregister(d &vx11.Display, screen i32) i32 { return C.XScreenSaverUnregister(d, screen) }

pub fn get_registered(d &vx11.Display, screen i32, xid &vx11.XID, typ &vx11.Atom) i32 {
	return C.XScreenSaverGetRegistered(d, screen, xid, typ)
}

pub fn suspend(d &vx11.Display, enabled i32) { C.XScreenSaverSuspend(d, enabled) }
