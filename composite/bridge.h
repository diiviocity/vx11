#ifndef VX11_COMPOSITE_BRIDGE_H
#define VX11_COMPOSITE_BRIDGE_H
#include <X11/Xlib.h>
#include <X11/extensions/Xcomposite.h>
#include <X11/extensions/Xrender.h>
#include <stdlib.h>

/* Traps are scoped to this single-threaded client's own requests. */
static int vx11_comp_error;
static int vx11_comp_trap(Display *d, XErrorEvent *e) { (void)d; (void)e; vx11_comp_error = 1; return 0; }
typedef struct Vx11CompositePreview {
 Window window;
 Pixmap thumbnail;
 int width, height, valid, redirected;
} Vx11CompositePreview;

static int vx11_comp_extensions(Display *d) {
 int a, b, major = 0, minor = 2;
 return XCompositeQueryExtension(d, &a, &b) &&
 XCompositeQueryVersion(d, &major, &minor) && (major > 0 || minor >= 2) &&
 XRenderQueryExtension(d, &a, &b);
}

static Vx11CompositePreview *vx11_comp_preview_new(Display *d, Window window) {
 Vx11CompositePreview *p = calloc(1, sizeof(*p));
 if (!p) return NULL;
 p->window = window;
 XSync(d, False);
 XErrorHandler old = XSetErrorHandler(vx11_comp_trap); vx11_comp_error = 0;
 XCompositeRedirectWindow(d, window, CompositeRedirectAutomatic);
 XSync(d, False); p->redirected = !vx11_comp_error; XSetErrorHandler(old);
 return p;
}

static void vx11_comp_preview_free(Display *d, Vx11CompositePreview *p) {
 if (!p) return;
 XSync(d, False);
 XErrorHandler old = XSetErrorHandler(vx11_comp_trap); vx11_comp_error = 0;
 if (p->thumbnail) XFreePixmap(d, p->thumbnail);
 if (p->redirected) XCompositeUnredirectWindow(d, p->window, CompositeRedirectAutomatic);
 XSync(d, False); XSetErrorHandler(old); free(p);
}

/* Preserve the last good image when the source is unmapped or vanishes. */
static int vx11_comp_preview_update(Display *d, Vx11CompositePreview *p, int w, int h) {
 if (!p || w < 1 || h < 1) return 0;
 XSync(d, False);
 XErrorHandler old = XSetErrorHandler(vx11_comp_trap); vx11_comp_error = 0;
 XWindowAttributes a;
 Pixmap source = 0, target = 0;
 Picture src = 0, dst = 0;
 if (!XGetWindowAttributes(d, p->window, &a) || a.map_state != IsViewable || a.width < 1 || a.height < 1) goto done;
 source = XCompositeNameWindowPixmap(d, p->window);
 XSync(d, False);
 if (vx11_comp_error || !source) { source = 0; goto done; }
 XRenderPictFormat *sf = XRenderFindVisualFormat(d, a.visual);
 XRenderPictFormat *df = XRenderFindVisualFormat(d, DefaultVisual(d, DefaultScreen(d)));
 if (!sf || !df) goto done;
 target = XCreatePixmap(d, DefaultRootWindow(d), w, h, DefaultDepth(d, DefaultScreen(d)));
 src = XRenderCreatePicture(d, source, sf, 0, NULL);
 dst = XRenderCreatePicture(d, target, df, 0, NULL);
 XTransform transform = {{{XDoubleToFixed((double)a.width/w), 0, 0},
                         {0, XDoubleToFixed((double)a.height/h), 0}, {0, 0, XDoubleToFixed(1)}}};
 XRenderSetPictureTransform(d, src, &transform);
 XRenderSetPictureFilter(d, src, FilterBilinear, NULL, 0);
 XRenderComposite(d, PictOpSrc, src, None, dst, 0, 0, 0, 0, 0, 0, w, h);
 XSync(d, False);
 if (!vx11_comp_error) {
  if (p->thumbnail) XFreePixmap(d, p->thumbnail);
  p->thumbnail = target; target = 0;
  p->width = w; p->height = h; p->valid = 1;
 }
done:
 if (src) XRenderFreePicture(d, src);
 if (dst) XRenderFreePicture(d, dst);
 if (source) XFreePixmap(d, source);
 if (target) XFreePixmap(d, target);
 XSync(d, False); XSetErrorHandler(old);
 return p->valid;
}

static int vx11_comp_preview_draw(Display *d, Vx11CompositePreview *p, Drawable target, int x, int y, int w, int h) {
 if (!p || !p->valid) return 0;
 XRenderPictFormat *f = XRenderFindVisualFormat(d, DefaultVisual(d, DefaultScreen(d)));
 Picture src = XRenderCreatePicture(d, p->thumbnail, f, 0, NULL);
 Picture dst = XRenderCreatePicture(d, target, f, 0, NULL);
 XTransform t = {{{XDoubleToFixed((double)p->width/w), 0, 0},
                 {0, XDoubleToFixed((double)p->height/h), 0}, {0, 0, XDoubleToFixed(1)}}};
 XRenderSetPictureTransform(d, src, &t);
 XRenderSetPictureFilter(d, src, FilterBilinear, NULL, 0);
 XRenderComposite(d, PictOpSrc, src, None, dst, 0, 0, 0, 0, x, y, w, h);
 XRenderFreePicture(d, src); XRenderFreePicture(d, dst);
 return 1;
}

#endif
