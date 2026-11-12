module xft

import vx11.fontconfig

// XftCompat aliases used by st; their implementation lives in Fontconfig.
pub const result_match = fontconfig.result_match

pub fn pattern_get_integer(pattern &fontconfig.FcPattern, object &char, index i32, value &i32) fontconfig.FcResult {
	return fontconfig.pattern_get_integer(pattern, object, index, value)
}
