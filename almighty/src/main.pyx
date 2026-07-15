from libc.stdint cimport uint8_t, uint16_t # type: ignore
from libc.stdio cimport sprintf, printf    # type: ignore
from libc.stdlib cimport malloc, free      # type: ignore
from typing import Iterable

cdef struct c_Rect:
    uint16_t y
    uint16_t x
    uint8_t w
    uint8_t h
    uint8_t color

cdef struct c_TemporalRect:
    c_Rect old
    c_Rect new
cdef struct c_Pixel:
    uint16_t y
    uint16_t x
    uint8_t color

cdef size_t color_size = sizeof(b"\033[48;2;2;8;8m  ") - 1 # type: ignore
cdef size_t pixel_size = color_size + sizeof(b"\033[65535;65535H") - 1 # type: ignore

cdef size_t f_color(char* buf, uint8_t color) nogil:
    return sprintf(buf, b"\033[48;2;%d;%d;%dm  ",
        ((color >> 0) & 0x03) * 80, # type: ignore
        ((color >> 2) & 0x07) * 36, # type: ignore
        ((color >> 5) & 0x07) * 36  # type: ignore
    )

cdef size_t f_pixel(char* buf, size_t offset, c_Pixel pixel) nogil:
    cdef size_t new_offset = sprintf(buf + offset, b"\033[%d;%dH", pixel.y, pixel.x) # type: ignore
    new_offset += f_color(buf + offset + new_offset, pixel.color)
    return new_offset

# p_iter_size: position iterable size
cdef char* f_pixels(const c_Pixel* pixels, size_t lenght) noexcept nogil:
    cdef size_t total_size = pixel_size * lenght
    cdef char* buf = <char*> malloc(sizeof(char) * total_size)
    cdef size_t offset = <size_t> 0
    cdef int i

    for i in range(<int> lenght):
        offset += f_pixel(buf, offset, 
            pixels[i] # type: ignore
        )

    return buf

cdef bint intersection(c_Rect r, int x, int y) nogil:
    return <bint> (r.y <= y <= (r.y + r.h) and r.x <= x <= (r.y + r.w))

cdef class Rect:
    cdef public str id
    cdef public uint8_t sx
    cdef public uint8_t sy
    cdef c_TemporalRect data
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
        
        self.data.old.x = self.data.new.x = <uint16_t> kwargs.get('x', x)
        self.data.old.y = self.data.new.y = <uint16_t> kwargs.get('y', y)
        self.data.old.w = self.data.new.w = <uint8_t> kwargs.get('w', w)
        self.data.old.h = self.data.new.h = <uint8_t> kwargs.get('h', h)
        self.data.old.color = self.data.new.color = <uint8_t> color
        self.sx = <uint8_t> kwargs.get('sx', sx)
        self.sx = <uint8_t> kwargs.get('sy', sy)


    cpdef set_pos(self, int x=0, int y=0):
        self.data.old.x = self.data.new.x
        self.data.old.y = self.data.new.y
        self.data.new.y = <uint16_t> y
        self.data.new.x = <uint16_t> x
    
    cpdef sum_pos(self, int x=0, int y=0):
        self.set_pos(<int> self.data.new.x + x, <int> self.data.new.y + y)
    
    cpdef move(self, int x = 1, int y = 1):
        self.sum_pos(<int> self.sx * x, <int> self.sy * y)
    cpdef set_color(self, uint8_t new_color):
        self.data.old.color = self.data.new.color
        self.data.new.color = new_color

cdef class Display:
    cdef public int w
    cdef public int h
    cdef public uint8_t color
    cdef c_Pixel* _cleaned_pixels
    cdef c_Pixel* _drawed_pixels
    cdef int cih # current Cleaned positions Index (hidden)
    cdef int dih # current Drawed positions Index (hidden)
    
    def __init__(self, w: int, h: int, background_color: uint8_t) -> None:
        self.w = w
        self.h = h
        self.color = background_color
        self._cleaned_pixels = <c_Pixel*> malloc(<size_t> sizeof(c_Pixel) * w * h)
        self._drawed_pixels = <c_Pixel*> malloc(<size_t> sizeof(c_Pixel) * w * h)
        self.reset_buffer()
    
    cdef void clear_on_buffer(self, c_TemporalRect rect) noexcept nogil:
        cdef int i, j
        for i in range(rect.old.y, rect.old.y + rect.old.h):
            for j in range(rect.old.x, rect.old.x + rect.old.w):
                if intersection(rect.new, j, i):
                    continue
                self._cleaned_pixels[self.cih].y = i              # type: ignore
                self._cleaned_pixels[self.cih].x = j              # type: ignore
                self._cleaned_pixels[self.cih].color = self.color # type: ignore
                self.cih += 1
    cdef void draw_on_buffer(self, c_TemporalRect rect) noexcept nogil:
        cdef uint8_t old_color = rect.old.color
        cdef uint8_t new_color = rect.new.color
        cdef bint same_colors = old_color == new_color # type: ignore
        cdef int i, j
        for i in range(rect.new.y, rect.new.y + rect.new.h):
            for j in range(rect.new.x, rect.new.x + rect.new.w):
                if intersection(rect.old, j, i) or self.out_vision(j, i) or same_colors:
                    continue
                self._drawed_pixels[self.dih].y = i             # type: ignore
                self._drawed_pixels[self.dih].x = j             # type: ignore
                self._drawed_pixels[self.dih].color = new_color # type: ignore
                self.dih += 1
    cdef bint out_vision(self, int x, int y) noexcept nogil:
        return <bint> (
            x < 0 or y < 0 or
            x >= self.w or y >= self.h
        )
    cdef void update_on_buffer(self, c_TemporalRect rect) nogil:
        self.clear_on_buffer(rect)
        self.draw_on_buffer(rect)
    cpdef reset_buffer(self):
        self.cih = 0
        self.dih = 0
    cpdef update_all(self, rects: Iterable[Rect]):
        for rect in rects:
            self.update_on_buffer(rect.data)
    cpdef print_buffer(self):
        cdef char* clear_buffer = f_pixels(self._cleaned_pixels, <size_t> self.cih)
        cdef char* draw_buffer = f_pixels(self._drawed_pixels, <size_t> self.dih)
        printf(b"%s%s", clear_buffer, draw_buffer) # type: ignore
        free(<void*> clear_buffer)
        free(<void*> draw_buffer)
    cdef char* f_screen(self):
        cdef char* ptr = <char*> malloc(color_size * self.w * self.h + self.h)
        cdef size_t i = <size_t> 0
        for _ in range(self.w * self.h):
            i += f_color(ptr + i, self.color)
        return ptr
cdef class Scene:
    cdef public Display display
    cdef public list rects # type: ignore
    cdef public float fps
    def __init__(self, display: Display, rects: list[Rect], fps: float=24.0) -> None:
        self.display = display
        self.rects: list[Rect] = rects
        self.fps = fps
    cpdef print_scene(self):
        cdef char* screen = self.display.f_screen()
        for rect in self.rects:
            for i in range(rect.data.new.y, rect.data.new.y + rect.data.new.h):
                for j in range(rect.data.new.x, rect.data.new.x + rect.data.new.w):
                    f_color(screen + (i * (self.display.h + 1) + j), self.display.color)
        printf(b"%s", screen) # type: ignore
        free(<void*> screen)
    cpdef print_buffer(self):
        self.display.reset_buffer()
        self.display.update_all(self.rects)
        self.display.print_buffer()