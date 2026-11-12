module screensaver

import vx11

// Info is a V-owned snapshot. All times are milliseconds, not seconds.
pub struct Info {
pub:
	window          vx11.Window
	state           int
	kind            int
	til_or_since_ms u64
	idle_ms         u64
	event_mask      vx11.CULong
}

pub struct Registration {
pub:
	xid vx11.XID
	typ vx11.Atom
}

@[heap; noinit]
pub struct Extension {
	connection &vx11.Connection
pub:
	event_base int
	error_base int
	major      int
	minor      int
}

pub fn available(connection &vx11.Connection) !bool {
	mut events := i32(0)
	mut errors := i32(0)
	return query_extension(connection.raw()!, &events, &errors) != 0
}

pub fn bind(connection &vx11.Connection) !&Extension {
	d := connection.raw()!
	mut events := i32(0)
	mut errors := i32(0)
	if query_extension(d, &events, &errors) == 0 {
		return error('MIT-SCREEN-SAVER extension is unavailable')
	}
	mut major := i32(0)
	mut minor := i32(0)
	if query_version(d, &major, &minor) == 0 { return error('cannot query screen saver version') }
	return &Extension{ connection: connection, event_base: int(events), error_base: int(errors), major: int(major), minor: int(minor) }
}

pub fn (e &Extension) info(drawable vx11.Drawable) !Info {
	d := e.connection.raw()!
	p := alloc_info()
	if p == unsafe { nil } { return error('cannot allocate screen saver info') }
	defer { vx11.free(p) }
	if query_info(d, drawable, p) == 0 { return error('cannot query screen saver info') }
	return Info{ window: p.window, state: int(p.state), kind: int(p.kind), til_or_since_ms: u64(p.til_or_since), idle_ms: u64(p.idle), event_mask: p.eventMask }
}

pub fn (e &Extension) idle_ms() !u64 {
	root := e.connection.root()!
	return e.info(vx11.Drawable(root))!.idle_ms
}

pub fn (e &Extension) watch(drawable vx11.Drawable, enabled bool) ! {
	select_input(e.connection.raw()!, drawable, if enabled {
		vx11.CULong(notify_mask | cycle_mask)
	} else {
		vx11.CULong(0)
	})
}

// set_suspended affects server-wide screen saving while this client is connected.
// Pair true with false when an activity that inhibits screen saving ends.
pub fn (e &Extension) set_suspended(enabled bool) ! {
	if e.major < 1 || (e.major == 1 && e.minor < 1) {
		return error('screen saver suspension requires version 1.1')
	}
	suspend(e.connection.raw()!, i32(enabled))
}

pub fn (e &Extension) register(screen int, xid vx11.XID, typ vx11.Atom) ! {
	if screen < 0 || screen >= e.connection.screen_count()! {
		return error('invalid screen number')
	}
	if register(e.connection.raw()!, i32(screen), xid, typ) == 0 {
		return error('cannot register screen saver')
	}
}

pub fn (e &Extension) unregister(screen int) ! {
	if screen < 0 || screen >= e.connection.screen_count()! {
		return error('invalid screen number')
	}
	if unregister(e.connection.raw()!, i32(screen)) == 0 {
		return error('cannot unregister screen saver')
	}
}

pub fn (e &Extension) registration(screen int) !Registration {
	if screen < 0 || screen >= e.connection.screen_count()! {
		return error('invalid screen number')
	}
	mut xid := vx11.XID(0)
	mut typ := vx11.Atom(0)
	if get_registered(e.connection.raw()!, i32(screen), &xid, &typ) == 0 {
		return error('no screen saver is registered')
	}
	return Registration{xid, typ}
}

pub fn (e &Extension) event(event vx11.Event) ?XScreenSaverNotifyEvent {
	if event.kind != e.event_base + notify { return none }
	return unsafe { *(&XScreenSaverNotifyEvent(&event.raw)) }
}
