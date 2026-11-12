module vx11

// Unix C long follows pointer width. Use explicit widths: a V `int` in a C
// function declaration can trigger 32-bit C-int adaptation, even through an alias.
// V's x64 condition tests target bitness (including ARM64), not just x86-64.
$if x64 {
	pub type CLong = i64
	pub type CULong = u64
} $else {
	pub type CLong = i32
	pub type CULong = u32
}
