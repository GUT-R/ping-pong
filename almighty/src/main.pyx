from libc.stdio cimport sprintf, printf # type: ignore
from libc.stdlib cimport malloc, free   # type: ignore
from libc.string cimport strlen, memcpy # type: ignore
from libc.stdint cimport (              # type: ignore
    uint8_t, uint16_t, uint32_t
)
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

cdef struct c_Color:
    uint8_t r
    uint8_t g
    uint8_t b

cdef size_t color_size = <size_t> len("\033[48;2;255;255;255m  ")
cdef size_t pixel_size = color_size + len("\033[65535;65535H")

cdef char* reset_and_break = <char*> b'\033[0m\n'
cdef size_t reset_and_break_size = strlen(reset_and_break)
cdef char end_string = <char> b'\0'

cdef c_Color* color_table2struct(pallete: list[tuple[uint8_t, uint8_t, uint8_t]]):
    """Converte uma lista de tuplas com três naturais em uma Array C de structs `c_ExtendedColor`"""
    cdef int n = len(pallete)
    cdef c_Color* buf = <c_Color*> malloc(<size_t> n * sizeof(c_Color))

    if not buf:
        raise MemoryError()

    cdef int i
    for i in range(n):
        buf[i].r = pallete[i][0] # type: ignore
        buf[i].g = pallete[i][1] # type: ignore
        buf[i].b = pallete[i][2] # type: ignore

    return buf

cdef char[21]* alloc_pallete(c_Color* pallete, int lenght) nogil:
    cdef char[21]* result = <char[21]*> malloc(<size_t> (21 * lenght + 1))
    cdef int i = 0
    cdef c_Color color
    cdef const char* template = b"\033[48;2;%03d;%03d;%03dm  " # type: ignore
    for i in range(lenght):
        color = pallete[i] # type: ignore
        sprintf(result[i], template, color.r, color.g, color.b) # type: ignore
    return result

cdef bint intersection(c_Rect r, int x, int y) nogil:
    return <bint> (r.y <= y < (r.y + r.h) and r.x <= x < (r.x + r.w))

cdef class Rect:
    cdef public uint8_t sx
    cdef public uint8_t sy
    cdef c_TemporalRect data
    def __init__(self, color: int, *args: int, **kwargs: int) -> None:
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
        self.sy = <uint8_t> kwargs.get('sy', sy)


    cpdef set_pos(self, int x=0, int y=0):
        self.data.old.x = self.data.new.x
        self.data.old.y = self.data.new.y
        self.data.new.y = <uint16_t> y
        self.data.new.x = <uint16_t> x
    
    cpdef sum_pos(self, int x=0, int y=0):
        self.set_pos(<int> self.data.new.x + x, <int> self.data.new.y + y)
    
    cpdef move(self, int x=0, int y=0):
        self.sum_pos(<int> self.sx * x, <int> self.sy * y)
    
    cpdef set_color(self, uint8_t new_color):
        self.data.old.color = self.data.new.color
        self.data.new.color = new_color

cdef class Display:
    cdef public uint16_t w
    cdef public uint16_t h
    cdef public uint8_t color
    cdef char[21]* _pallete # 21 == color_size
    cdef c_Pixel* _cleaned_pixels
    cdef c_Pixel* _drawed_pixels
    cdef uint32_t cih # current Cleaned positions Index (hidden)
    cdef uint32_t dih # current Drawed positions Index (hidden)
    
    def __init__(self, w: int, h: int, background_color: uint8_t, colors: list[tuple[uint8_t, uint8_t, uint8_t]]) -> None:
        self.w = <uint16_t> w
        self.h = <uint16_t> h
        self.color = background_color
        self._cleaned_pixels = <c_Pixel*> malloc(<size_t> sizeof(c_Pixel) * w * h)
        self._drawed_pixels = <c_Pixel*> malloc(<size_t> sizeof(c_Pixel) * w * h)
        self.reset_buffer()
        self.register_color_pallete(colors)
    
    cdef register_color_pallete(self, colors: list[tuple[uint8_t, uint8_t, uint8_t]]):
        cdef int lenght = len(colors)
        cdef c_Color* temp = color_table2struct(colors)
        self._pallete = alloc_pallete(temp, lenght)
        free(<void*> temp) 
    
    cdef void clear_on_buffer(self, c_TemporalRect rect) noexcept nogil:
        cdef int i, j
        for i in range(rect.old.y, rect.old.y + rect.old.h):
            for j in range(rect.old.x, rect.old.x + rect.old.w):
                if intersection(rect.new, j, i):
                    continue
                self._cleaned_pixels[self.cih].y = i + 1          # type: ignore
                self._cleaned_pixels[self.cih].x = (j * 2) + 1          # type: ignore
                self._cleaned_pixels[self.cih].color = self.color # type: ignore
                self.cih += 1
    
    cdef void draw_on_buffer(self, c_TemporalRect rect) noexcept nogil:
        cdef uint8_t old_color = rect.old.color
        cdef uint8_t new_color = rect.new.color
        cdef bint same_colors = old_color == new_color # type: ignore
        cdef int i, j
        for i in range(rect.new.y, rect.new.y + rect.new.h):
            for j in range(rect.new.x, rect.new.x + rect.new.w):
                if (same_colors and intersection(rect.old, j, i)) or self.out_vision(j, i):
                    continue
                self._drawed_pixels[self.dih].y = i + 1         # type: ignore
                self._drawed_pixels[self.dih].x = (j * 2) + 1   # type: ignore
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
        cdef Rect rect
        for rect in rects:
            self.update_on_buffer(rect.data)
    
    cdef void f_color(self, char* buf, color_index: uint8_t) noexcept nogil:
        memcpy(buf, self._pallete[color_index], color_size) # type: ignore
    
    cdef size_t f_pixel(self, char* buf, size_t offset, c_Pixel pixel) noexcept nogil:
        cdef size_t new_offset = sprintf(buf + offset, b"\033[%05d;%05dH", pixel.y, pixel.x) # type: ignore
        self.f_color(buf + offset + new_offset, pixel.color)
        return new_offset + color_size
        
    cdef char* f_pixels(self, const c_Pixel* pixels, size_t lenght) noexcept nogil:
        cdef size_t total_size = pixel_size * lenght
        cdef char* buf = <char*> malloc(sizeof(char) * total_size)
        cdef size_t offset = <size_t> 0
        cdef int i
        
        for i in range(<int> lenght):
            offset += self.f_pixel(buf, offset, 
                pixels[i] # type: ignore
            )
        buf[offset] = end_string # type: ignore
        return buf
        
    cpdef print_buffer(self):
        cdef char* clear_buffer = self.f_pixels(self._cleaned_pixels, <size_t> self.cih)
        cdef char* draw_buffer = self.f_pixels(self._drawed_pixels, <size_t> self.dih)
        
        # Nota: o break no final é extremamente importante porque ele faz um flush por padrão. 
        #  Sem ele, os pixels não são impressos imediatamente.
        printf(b"%s%s\n", clear_buffer, draw_buffer) # type: ignore 
        
        free(<void*> clear_buffer)
        free(<void*> draw_buffer)
    cdef char* f_screen(self):
        cdef char* ptr = <char*> malloc(color_size * self.w * self.h + (reset_and_break_size * self.h) + 1)
        cdef size_t i = <size_t> 0
        
        for _ in range(self.h):
            for _ in range(self.w):
                self.f_color(ptr + i, self.color)
                i += color_size
            memcpy(ptr + i, reset_and_break, reset_and_break_size) # type: ignore
            i += reset_and_break_size
        ptr[i] = end_string # type: ignore
        return ptr
    cdef close(self):
        free(<void*> self._cleaned_pixels)
        free(<void*> self._drawed_pixels)
        free(<void*> self._pallete)
cdef class Scene:
    cdef public Display display
    cdef public dict rects # type: ignore
    def __init__(self, display: Display, rects: dict[str, Rect]) -> None:
        self.display = display
        self.rects: dict[str, Rect] = rects

    def __getitem__(self, key: str) -> Rect:
        return self.rects[key]
    
    def __getattr__(self, __name: str) -> Rect:
        return self.rects[__name]
    
    cpdef print_scene(self):
        cdef char* screen = self.display.f_screen()
        cdef int i, j
        cdef Rect rect
        for rect in self.rects.values():
            for i in range(rect.data.new.y, rect.data.new.y + rect.data.new.h):
                for j in range(rect.data.new.x, rect.data.new.x + rect.data.new.w):
                    if not self.display.out_vision(j, i):
                        self.display.f_color(screen + i * (color_size * self.display.w + reset_and_break_size) + j * color_size, rect.data.new.color)
        printf(b"%s", screen) # type: ignore
        free(<void*> screen)
    
    cpdef print_buffer(self):
        self.display.reset_buffer()
        self.display.update_all(self.rects.values())
        self.display.print_buffer()