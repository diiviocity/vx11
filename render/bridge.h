#ifndef VX11_RENDER_BRIDGE_H
#define VX11_RENDER_BRIDGE_H
#include <X11/Xlib.h>
#include <X11/extensions/Xrender.h>
/* Snapshot before mapping; dim without requiring a compositor. */
static Pixmap vx11_render_backdrop(Display *d, int x, int y, int w, int h) {
 Pixmap p = XCreatePixmap(d, DefaultRootWindow(d), w, h, DefaultDepth(d, DefaultScreen(d)));
 GC gc = XCreateGC(d, p, 0, NULL);
 XCopyArea(d, DefaultRootWindow(d), p, gc, x, y, w, h, 0, 0);
 XFreeGC(d, gc);
 XRenderPictFormat *f = XRenderFindVisualFormat(d, DefaultVisual(d, DefaultScreen(d)));
 Picture dst = XRenderCreatePicture(d, p, f, 0, NULL);
 XRenderColor shade = {0x1000, 0x1500, 0x2100, 0xd800};
 XRenderFillRectangle(d, PictOpOver, dst, &shade, 0, 0, w, h);
 XRenderFreePicture(d, dst);
 return p;
}
#endif
