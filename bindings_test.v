module vx11

fn test_native_long_and_event_layout() {
	assert sizeof(XID) == sizeof(CULong)
	assert sizeof(Atom) == sizeof(CULong)
	assert sizeof(XEvent) == 24 * sizeof(CLong)
	mut event := XEvent{}
	unsafe {
		event.xclient.@type = client_message
		event.xclient.format = 32
		event.xclient.data.l[4] = 0x12345678
	}
	snapshot := Event{ kind: client_message, raw: event }
	message := snapshot.client_message() or { panic('missing client message') }
	assert message.data[4] == 0x12345678
	assert snapshot.key() == none
}

fn test_missing_display_is_an_error() {
	connect('invalid-display-name') or { return }
	assert false
}

fn test_variadic_validation() {
	create_ic(XIM(unsafe { nil }), [voidptr(1)]) or {
		assert err.msg().contains('name/value')
		return
	}
	assert false
}

fn test_keysym_case_and_conversion() {
	assert all_planes() == x_all_planes
	assert key_capital_a != key_a
	assert string_to_keysym(c'A') == KeySym(key_capital_a)
	assert string_to_keysym(c'a') == KeySym(key_a)
}

#include "@VMODROOT/tests/abi.h"

fn C.vx11_test_long_size() u32
fn C.vx11_test_int_size() u32
fn C.vx11_test_store_long(&CLong)
fn C.vx11_test_store_ulong(&CULong)

fn test_c_integer_abi() {
	assert sizeof(CLong) == C.vx11_test_long_size()
	assert sizeof(CULong) == C.vx11_test_long_size()
	assert sizeof(i32) == C.vx11_test_int_size()
	mut signed := CLong(0)
	mut unsigned := CULong(0)
	C.vx11_test_store_long(&signed)
	C.vx11_test_store_ulong(&unsigned)
	assert signed == -(CLong(1) << (sizeof(CLong) * 8 - 2))
	assert unsigned == ~CULong(0)
}
