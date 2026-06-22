from libc.stdint cimport int_fast8_t # type: ignore
from libc.stdio cimport sprintf      # type: ignore
from libc.stdlib cimport malloc      # type: ignore
from libc.string cimport strlen      # type: ignore
from typing import Iterable
cdef struct Rect:
    int_fast8_t y
    int_fast8_t w
    int_fast8_t h
    int_fast8_t x
    
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
    cdef public int x
    cdef public int y
    cdef public int w
    cdef public int h
    cdef public int sx
    cdef public int sy
    cdef Rect old_self
    def __init__(self, ID: str, representating_char: str, *args: int, **kwargs: int) -> None:
        self.id = ID
        
        defaults = (0, 0, 1, 1, 1, 1)
        values = (*args, *defaults[len(args):])

        self.x, self.y, self.w, self.h, self.sx, self.sy = values[:6]
        
        self.x = kwargs.get('x', self.x)
        self.y = kwargs.get('y', self.y)
        self.w = kwargs.get('w', self.w)
        self.h = kwargs.get('h', self.h)
        self.sx = kwargs.get('sx', self.sx)
        self.sy = kwargs.get('sy', self.sy)
        self.old_self.x = <int_fast8_t> self.x
        self.old_self.y = <int_fast8_t> self.y
        self.repr = representating_char
    cdef void c_set_pos(self, int x = 0, int y = 0):
        self.old_self.x = <int_fast8_t> self.x
        self.old_self.y = <int_fast8_t> self.y
        self.y = y
        self.x = x
    cdef void c_sum_pos(self, int x = 0, int y = 0):
        self.c_set_pos(self.x + x, self.y + y)
    
    cpdef set_pos(self, x: int=0, y: int=0):
        self.c_set_pos(x, y)
    
    cpdef sum_pos(self, x: int=0, y: int=0):
        self.c_sum_pos(x, y)
    
    cpdef move(self, int x = 1, int y = 1):
        self.c_sum_pos(self.sx * x, self.sy * y)

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
        for i in range(rect.y, rect.y + rect.h):
            for j in range(rect.x, rect.x + rect.w):
                if self.matrix[i][j] == rect.repr:
                    self.matrix[i][j] = self.bkg                     # type: ignore
                    self._cleaned_positions[self.cih][0] = j         # type: ignore
                    self._cleaned_positions[self.cih][1] = i         # type: ignore
                    self._cleaned_positions[self.cih][2] = self.bkg  # type: ignore
                    self.cih += 1
    
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