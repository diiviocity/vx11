#ifndef VX11_TEST_ABI_H
#define VX11_TEST_ABI_H
#include <limits.h>
static inline unsigned int vx11_test_long_size(void) { return sizeof(long); }
static inline unsigned int vx11_test_int_size(void) { return sizeof(int); }
static inline void vx11_test_store_long(long *p) {
    *p = -(1L << (sizeof(long) * CHAR_BIT - 2));
}
static inline void vx11_test_store_ulong(unsigned long *p) { *p = ULONG_MAX; }
#endif
