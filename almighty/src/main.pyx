from libc.stdint cimport int_fast8_t # type: ignore
from typing import Iterable

cdef struct Rect:
    int_fast8_t y
    int_fast8_t w
    int_fast8_t h
    int_fast8_t x

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
    w: int
    h: int
    bkg: str
    matrix: list[list[str]]
    _cleaned_positions: list[tuple[int, int]]
    _drawed_positions: list[tuple[int, int]]
    def __init__(self, w: int, h: int, background_char: str) -> None:
        self.w = w
        self.h = h
        self.bkg = background_char
        self.matrix = [[background_char] * w] * h # Acabei aprendendo isso na prova de Minora (https://github.com/leonardo-minora)
        self._cleaned_positions = []
        self._drawed_positions = []
    cdef clear(self, Rect rect):
        self._cleaned_positions.clear()
        for i in range(rect.y, rect.y + rect.h):
            for j in range(rect.x, rect.x + rect.w):
                if self.matrix[i][j] != self.bkg:
                    self.matrix[i][j] = self.bkg
                    self._cleaned_positions.append((i, j))
    cdef draw(self, GraphicRect rect):
        self._drawed_positions.clear()
        for i in range(rect.y, rect.y + rect.h):
            for j in range(rect.x, rect.x + rect.w):
                if self.matrix[i][j] != rect.repr:
                    self.matrix[i][j] = rect.repr # type: ignore
                    self._drawed_positions.append((i, j))
    cpdef str render(self):
        return '\n'.join(map(''.join, self.matrix))
cdef class Scene:
    display: Display
    rects: dict[str, GraphicRect]
    fps: float
    def __init__(self, display: Display, rects: Iterable[GraphicRect], fps: float=24.0) -> None:
        self.display = display
        self.rects = {rect.id: rect for rect in rects}
        self.fps = fps
    cpdef frame(self):
        for rect in self.rects.values():
            self.display.clear(<Rect> rect)
        for rect in self.rects.values():
            self.display.draw(rect)