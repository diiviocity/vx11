/* Generated enum-output adapters. */
#include <fontconfig/fontconfig.h>
static inline FcPattern * vx11_FcFontSetMatch(FcConfig * arg0, FcFontSet ** arg1, int arg2, FcPattern * arg3, int *arg4) {
 FcResult value4=FcResultNoMatch;
 FcPattern * result=FcFontSetMatch(arg0, arg1, arg2, arg3, &value4);
 if(arg4) *arg4=(int)value4;
 return result;
}
static inline FcPattern * vx11_FcFontMatch(FcConfig * arg0, FcPattern * arg1, int *arg2) {
 FcResult value2=FcResultNoMatch;
 FcPattern * result=FcFontMatch(arg0, arg1, &value2);
 if(arg2) *arg2=(int)value2;
 return result;
}
static inline FcFontSet * vx11_FcFontSetSort(FcConfig * arg0, FcFontSet ** arg1, int arg2, FcPattern * arg3, FcBool arg4, FcCharSet ** arg5, int *arg6) {
 FcResult value6=FcResultNoMatch;
 FcFontSet * result=FcFontSetSort(arg0, arg1, arg2, arg3, arg4, arg5, &value6);
 if(arg6) *arg6=(int)value6;
 return result;
}
static inline FcFontSet * vx11_FcFontSort(FcConfig * arg0, FcPattern * arg1, FcBool arg2, FcCharSet ** arg3, int *arg4) {
 FcResult value4=FcResultNoMatch;
 FcFontSet * result=FcFontSort(arg0, arg1, arg2, arg3, &value4);
 if(arg4) *arg4=(int)value4;
 return result;
}
