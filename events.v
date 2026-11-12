module vx11

// Event is a value snapshot. Accessors check the active union member for you.
// raw remains available for uncommon event types and extension cookies.
pub struct Event {
pub:
	kind int
	raw  XEvent
}

pub struct KeyEvent {
pub:
	window Window
	code   u32
	state  u32
	x      int
	y      int
	root_x int
	root_y int
	time   Time
}

pub struct ButtonEvent {
pub:
	window Window
	button u32
	state  u32
	x      int
	y      int
}

pub struct MotionEvent {
pub:
	window Window
	state  u32
	x      int
	y      int
}

pub struct ConfigureEvent {
pub:
	window Window
	x      int
	y      int
	width  int
	height int
}

pub struct ExposeEvent {
pub:
	window    Window
	x         int
	y         int
	width     int
	height    int
	remaining int
}

pub struct ClientMessage {
pub:
	window       Window
	message_type Atom
	format       int
	data         [5]CLong
}

pub fn (e Event) key() ?KeyEvent {
	if e.kind != key_press && e.kind != key_release { return none }
	k := unsafe { e.raw.xkey }
	return KeyEvent{k.window, k.keycode, k.state, int(k.x), int(k.y), int(k.x_root), int(k.y_root), k.time}
}

pub fn (e Event) button() ?ButtonEvent {
	if e.kind != button_press && e.kind != button_release { return none }
	b := unsafe { e.raw.xbutton }
	return ButtonEvent{b.window, b.button, b.state, int(b.x), int(b.y)}
}

pub fn (e Event) motion() ?MotionEvent {
	if e.kind != motion_notify { return none }
	m := unsafe { e.raw.xmotion }
	return MotionEvent{m.window, m.state, int(m.x), int(m.y)}
}

pub fn (e Event) configure() ?ConfigureEvent {
	if e.kind != configure_notify { return none }
	r := unsafe { e.raw.xconfigure }
	return ConfigureEvent{r.window, int(r.x), int(r.y), int(r.width), int(r.height)}
}

pub fn (e Event) expose() ?ExposeEvent {
	if e.kind != expose { return none }
	r := unsafe { e.raw.xexpose }
	return ExposeEvent{r.window, int(r.x), int(r.y), int(r.width), int(r.height), int(r.count)}
}

pub fn (e Event) client_message() ?ClientMessage {
	if e.kind != client_message { return none }
	m := unsafe { e.raw.xclient }
	if m.format != 32 { return none }
	return ClientMessage{m.window, m.message_type, int(m.format), unsafe { m.data.l }}
}
