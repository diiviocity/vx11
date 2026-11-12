/* Generated enum-output adapters. */
#include <X11/Xft/Xft.h>
static inline FcPattern * vx11_XftFontMatch(Display * arg0, int arg1, const FcPattern * arg2, int *arg3) {
 FcResult value3=FcResultNoMatch;
 FcPattern * result=XftFontMatch(arg0, arg1, arg2, &value3);
 if(arg3) *arg3=(int)value3;
 return result;
}
