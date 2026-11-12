module fontconfig

#pkgconfig fontconfig
#include <fontconfig/fontconfig.h>
#include "@VMODROOT/fontconfig/bridge.h"

@[typedef]
pub struct C.FcPattern {}

pub type FcPattern = C.FcPattern

@[typedef]
pub struct C.FcCharSet {}

pub type FcCharSet = C.FcCharSet

@[typedef]
pub struct C.FcConfig {}

pub type FcConfig = C.FcConfig

@[typedef]
pub struct C.FcObjectSet {}

pub type FcObjectSet = C.FcObjectSet

@[typedef]
pub struct C.FcFontSet {
pub mut:
	nfont i32
	sfont i32
	fonts &&FcPattern
}

pub type FcFontSet = C.FcFontSet
pub type FcResult = i32
pub type FcMatchKind = i32
pub type FcEndian = i32
pub type FcChar8 = u8
pub type FcChar16 = u16
pub type FcChar32 = u32
pub type FcBool = i32

pub const result_match = 0
pub const result_no_match = 1
pub const result_type_mismatch = 2
pub const result_no_id = 3
pub const result_out_of_memory = 4
pub const match_pattern = 0
pub const match_font = 1
pub const match_scan = 2
pub const family = 'family'
pub const style = 'style'
pub const file = 'file'
pub const size = 'size'
pub const pixel_size = 'pixelsize'
pub const weight = 'weight'
pub const slant = 'slant'
pub const spacing = 'spacing'
pub const charset = 'charset'
pub const scalable = 'scalable'
pub const antialias = 'antialias'
pub const color = 'color'
pub const weight_regular = 80
pub const weight_bold = 200
pub const slant_roman = 0
pub const slant_italic = 100
pub const mono = 100
