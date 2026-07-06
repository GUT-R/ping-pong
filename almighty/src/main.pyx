from libc.stdint cimport uint8_t, uint16_t # type: ignore
from libc.stdio cimport sprintf, printf    # type: ignore
from libc.stdlib cimport malloc, free      # type: ignore
from typing import Iterable

cdef struct Rect:
    uint16_t y
    uint16_t x
    uint8_t w
    uint8_t h

cdef struct Pixel:
    uint16_t x
    uint16_t y
    uint8_t color

cdef const size_t pixel_size = <size_t> sizeof(char) * 24 # \033[48;2;2;8:8m  \033[0m
cdef const size_t positioned_pixel_size = <size_t> 38 # \033[65535;65535H\033[48;2;2;8:8m  \033[0m

cdef char* f_color(uint8_t color):
    cdef char* s = <char*> malloc(pixel_size)
    sprintf(s, b"\033[48;2;%d;%d:%dm  \033[0m",
        (color >> 0) & 0x03, # type: ignore
        (color >> 2) & 0x07, # type: ignore
        (color >> 5) & 0x07  # type: ignore
    )
    return s

cdef int f_pixel(char* buf, size_t offset, Pixel pixel) nogil:
    cdef char* pixel_ptr = f_color(pixel.color)
    cdef int new_offset = sprintf(buf + offset, b"\033[%d;%dH%s", pixel.y, pixel.x, p) # type: ignore
    free(<void*> pixel_ptr)

# p_iter_size: position iterable size
cdef char* f_pixels(Pixel* pixels, size_t lenght) nogil:
    cdef const size_t total_size = positioned_pixel_size * lenght
    cdef char* buf = <char*> malloc(sizeof(char) * total_size)
    cdef int offset
    cdef int i

    for i in range(total_size):
        offset += f_pixel(buf, offset, pixels[i]) # type: ignore

    return buf

cdef bool collision(Rect r1, Rect r2):
    return (
        r1.x < r2.x + r2.w and
        r1.x + r1.w > r2.x and
        r1.y < r2.y + r2.h and
        r1.y + r1.h > r2.y
    )
cdef bool intersection(Rect r, int x, int y) nogil:
    return r.y <= y <= r.y + r.h and r.x <= x <= r.y + r.w

cdef class GraphicRect:
    cdef public str id
    cdef public uint8_t sx
    cdef public uint8_t sy
    cdef Rect ne
    cdef Rect old
    def __init__(self, ID: str, color: int, *args: int, **kwargs: int) -> None:
        self.id = ID
        
        x, y, w, h, sx, sy = 0, 0, 1, 1, 1, 1
        n = len(args)
        
        if n >= 1:
            w = h = args[0]
        if n >= 2:
            sx = sy = args[-1]
        if n >= 3:
            h = args[1]
        if n >= 4:
            x, y, w, h = args[:4]
        if n >= 6:
            sx, sy = args[-2:][:2]
        
        self.old.x = self.ne.x = <uint16_t> kwargs.get('x', x)
        self.old.y = self.ne.y = <uint16_t> kwargs.get('y', y)
        self.old.w = self.ne.w = <uint8_t> kwargs.get('w', w)
        self.old.h = self.ne.h = <uint8_t> kwargs.get('h', h)
        self.old.color = self.ne.color = <uint8_t> color
        self.sx = <uint8_t> kwargs.get('sx', sx)
        self.sx = <uint8_t> kwargs.get('sy', sy)


    cpdef set_pos(self, int x=0, int y=0):
        self.old.x = self.ne.x
        self.old.y = self.ne.y
        self.ne.y = <uint16_t> y
        self.ne.x = <uint16_t> x
    
    cpdef sum_pos(self, int x=0, int y=0):
        self.set_pos(<int> self.ne.x + x, <int> self.ne.y + y)
    
    cpdef move(self, int x = 1, int y = 1):
        self.sum_pos(<int> self.sx * x, <int> self.sy * y)
    cpdef set_color(self, uint8_t new_color):
        self.old.color = self.ne.color
        self.ne.color = new_color

cdef class Display:
    cdef public int w
    cdef public int h
    cdef public str bkg
    cdef public uint8_t color
    cdef Pixel* _cleaned_pixels
    cdef Pixel* _drawed_pixels
    cdef int cih = 0 # current Cleaned positions Index (hidden)
    cdef int dih = 0 # current Drawed positions Index (hidden)
    
    def __init__(self, w: int, h: int, background_color: uint8_t) -> None:
        self.w = w
        self.h = h
        self.color = background_color
        self._cleaned_pixels = <Pixel*> malloc(<size_t> sizeof(Pixel) * w * h)
        self._drawed_pixels = <Pixel*> malloc(<size_t> sizeof(Pixel) * w * h)
    cdef clear_on_buffer(self, GraphicRect rect) nogil:
        cdef int i, j
        for i in range(rect.old.y, rect.old.y + rect.old.h):
            for j in range(rect.old.x, rect.old.x + rect.old.w):
                if intersection(rect.ne, j, i):
                    continue
                self._cleaned_pixels[self.cih].x = <uint16_t> i   # type: ignore
                self._cleaned_pixels[self.cih].y = <uint16_t> j   # type: ignore
                self._cleaned_pixels[self.cih].color = self.color # type: ignore
                self.cih += 1
    cdef draw_on_buffer(self, GraphicRect rect) nogil:
        cdef uint8_t old_color = rect.old.color
        cdef uint8_t new_color = rect.ne.color
        cdef bool different_colors = old_color != new_color
        cdef int i, j
        for i in range(rect.ne.y, rect.ne.y + rect.ne.h):
            for j in range(rect.ne.x, rect.ne.x + rect.ne.w):
                if intersection(rect.old, j, i) or self.out_vision(i, j) or not different_colors:
                    continue
                self._drawed_pixels[self.dih].x = <uint16_t> i  # type: ignore
                self._drawed_pixels[self.dih].y = <uint16_t> j  # type: ignore
                self._drawed_pixels[self.dih].color = new_color # type: ignore
                self.dih += 1
    cdef bool out_vision(self, int x, int y) nogil:
        return (
            x < 0 or y < 0 or
            x >= self.w or y >= self.h
        )
    cdef update_on_buffer(self, GraphicRect rect) nogil:
        self.clear_on_buffer(rect)
        self.draw_on_buffer(rect)
    cpdef reset_buffer(self):
        self.cih = 0
        self.dih = 0
    cpdef update_all(self, rects: Iterable[GraphicRect]):
        for rect in rects:
            self.update_on_buffer(rect)
    cpdef print_buffer(self):
        cdef char* clear_buffer = f_pixels(self._cleaned_pixels, <size_t> self.cih)
        cdef char* draw_buffer = f_pixels(self._drawed_pixels, <size_t> self.dih)
        printf(b"%s%s", clear_buffer, draw_buffer) # type: ignore
        free(<void*> clear_buffer)
        free(<void*> draw_buffer)

cdef class Scene:
    cdef public Display display
    cdef public Iterable[GraphicRect] rects # type: ignore
    cdef public float fps
    def __init__(self, display: Display, rects: Iterable[GraphicRect], fps: float=24.0) -> None:
        self.display = display
        self.rects = rects
        self.fps = fps
    cpdef print_scene(self):
        otp = [
            [(<bytes> f_color(self.display.color)).decode('utf-8') for _ in range(self.display.w)]
                for _ in range(self.display.h)
        ]
        for rect in self.rects:
            for i in range(rect.ne.y, rect.ne.y + rect.ne.h):
                for j in range(rect.ne.x, rect.ne.x + rect.ne.w):
                    otp[i][j] = (<bytes> f_color(rect.ne.color)).decode('utf-8')
        print('\n'.join(map(''.join, otp)))
    cpdef print_buffer(self):
        self.display.reset_buffer()
        self.display.update_all(self.rects)
        self.display.print_buffer()