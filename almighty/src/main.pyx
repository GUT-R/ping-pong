from libc.stdint cimport uint8_t, uint16_t # type: ignore
from libc.stdio cimport sprintf            # type: ignore
from libc.stdlib cimport malloc            # type: ignore
from libc.string cimport strlen            # type: ignore
from typing import Iterable
cdef struct Rect:
    uint16_t y
    uint16_t x
    uint8_t w
    uint8_t h
    
cdef void f_cursor_pos(char* buf, size_t offset, int x, int y, const char* s) nogil:
    sprintf(buf + offset, "\033[%d;%dH%s",
                                 y, x, s # type: ignore
            ) 

# p_iter_size: position iterable size
cdef char* f_cursor_positions(int[2]* positions, size_t p_iter_size, const char* fill) nogil:
    # Considerando que cada ANSI pode ter no mínimo 12 caracteres de tamanho
    # Por quê 12?
    #   2      4     1  4     1*n  1
    # [ \033[, 0000, ;, 0000, Sxx, H  ]
    cdef const size_t fill_size = 12 * strlen(fill)
    cdef char* buf = <char*> malloc(fill_size * p_iter_size)
    cdef int i

    for i in range(p_iter_size):
        f_cursor_pos(buf, fill_size * i,
            positions[i][0], positions[i][1], # type: ignore
            fill
        )

    return buf

# cdef bool collision(Rect r1, Rect r2):
#     return (
#         r1.x < r2.x + r2.w and
#         r1.x + r1.w > r2.x and
#         r1.y < r2.y + r2.h and
#         r1.y + r1.h > r2.y
#     )

cdef class GraphicRect:
    cdef public str id
    cdef public str repr
    cdef public uint16_t x
    cdef public uint16_t y
    cdef public uint8_t w
    cdef public uint8_t h
    cdef public uint8_t sx
    cdef public uint8_t sy
    cdef Rect old
    def __init__(self, ID: str, representating_char: str, *args: int, **kwargs: int) -> None:
        self.id = ID
        self.repr = representating_char
        
        x, y, w, h, sx, sy = 0, 0, 1, 1, 1, 1
        n = len(args)
        
        if n == 5 and not kwargs.get('y'):
            raise TypeError("GraphicRect() missing 1 required positional argument: 'y'")
        
        if n >= 1:
            w = h = args[0]
        if n >= 2:
            sx = sy = args[-1]
        if n >= 3:
            h = args[1]
        if n >= 4:
            sx, sy = args[-2:][:2]
        if n >= 6:
            x, y, w, h, sx, sy = args[:6]
        
        self.x = <uint16_t> kwargs.get('x', x)
        self.y = <uint16_t> kwargs.get('y', y)
        self.w = <uint8_t> kwargs.get('w', w)
        self.h = <uint8_t> kwargs.get('h', h)
        self.sx = <uint8_t> kwargs.get('sx', sx)
        self.sx = <uint8_t> kwargs.get('sy', sy)
        self.old.x = self.x
        self.old.y = self.y
        self.old.w = self.w
        self.old.h = self.h
        
    cdef void c_set_pos(self, int x = 0, int y = 0): # type: ignore
        self.old.x = self.x
        self.old.y = self.y
        self.y = <uint16_t> y
        self.x = <uint16_t> x
    cdef void c_sum_pos(self, int x = 0, int y = 0):
        self.c_set_pos(<int> self.x + x, <int> self.y + y)
    
    cpdef set_pos(self, x: int=0, y: int=0):
        self.c_set_pos(x, y)
    
    cpdef sum_pos(self, x: int=0, y: int=0):
        self.c_sum_pos(x, y)
    
    cpdef move(self, int x = 1, int y = 1):
        self.c_sum_pos(<int> self.sx * x, <int> self.sy * y)

cdef class Display:
    cdef public int w
    cdef public int h
    cdef public str bkg
    cdef public int ch_size
    cdef public list matrix # type: ignore
    cdef (int[2], char*)* _cleaned_positions
    cdef (int[2], char*)* _drawed_positions
    cdef int cih = 0 # current Cleaned positions Index (hidden)
    cdef int dih = 0 # current Drawed positions Index (hidden)
    cdef char* buffer
    def __init__(self, w: int, h: int, background_char: str) -> None:
        self.w = w
        self.h = h
        self.bkg = background_char
        self.ch_size = len(self.bkg)
        self.matrix: list[list[str]] = [[background_char] * w] * h # Acabei aprendendo isso na prova de Minora (https://github.com/leonardo-minora)
        self._cleaned_positions = <(int[2]*, char*)*> malloc(<size_t> w * h * (sizeof(int) * 2 + sizeof(char) * self.ch_size))
        self._drawed_positions = <(int[2]*, char*)*> malloc(<size_t> w * h * (sizeof(int) * 2 + sizeof(char) * self.ch_size))

    cdef reset_buffer(self):
        self.cih = 0
        self.dih = 0
    cdef clear(self, rect: GraphicRect):
        for i in range(rect.old.y, rect.old.y + rect.old.h):
            for j in range(rect.old.x, rect.old.x + rect.old.w):
                if self.matrix[i][j] == rect.repr:
                    self.matrix[i][j] = self.bkg                     # type: ignore
                    self._cleaned_positions[self.cih][0] = j         # type: ignore
                    self._cleaned_positions[self.cih][1] = i         # type: ignore
                    self._cleaned_positions[self.cih][2] = self.bkg  # type: ignore
                    self.cih += 1
    cdef clear_all(self, rects: Iterable[GraphicRect]):
        for rect in rects:
            self.clear(rect)
        
    cdef draw(self, GraphicRect rect):
        for i in range(rect.y, rect.y + rect.h):
            for j in range(rect.x, rect.x + rect.w):
                if self.matrix[i][j] != rect.repr:
                    self.matrix[i][j] = self.bkg                    # type: ignore
                    self._drawed_positions[self.dih][0] = j         # type: ignore
                    self._drawed_positions[self.dih][1] = i         # type: ignore
                    self._drawed_positions[self.dih][2] = rect.bkg  # type: ignore
                    self.dih += 1
    cpdef str render(self):
        return '\n'.join(map(''.join, self.matrix))

cdef class Scene:
    cdef public Display display
    cdef public dict rects # type: ignore
    cdef public float fps
    def __init__(self, display: Display, rects: Iterable[GraphicRect], fps: float=24.0) -> None:
        self.display = display
        self.rects: dict[str, GraphicRect] = {}
        for rect in rects:
            self.rects[rect.id] = rect
        self.fps = fps
    cpdef frame(self):
        for rect in self.rects.values():
            self.display.clear(rect)
        for rect in self.rects.values():
            self.display.draw(rect)