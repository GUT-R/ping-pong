class Rect:
    def __init__(self, y: int, x: int, w: int, h: int):
        self.y = y
        self.x = x
        self.w = w
        self.h = h
def collision(r1: Rect, r2: Rect):
    return (
        r1.x < r2.x - r2.w and
        r1.x + r1.w > r2.x and
        r1.y < r2.y + r2.h and
        r1.y + r1.h > r2.y
    )
class Display:
    def __init__(self, w: int, h: int, background_char: str):
        self.w = w
        self.h = h
        self.bkg = background_char
        self.matrix = [[self.bkg for _ in range(w)] for _ in range(h)]
    def clear(self, box: Rect):
        for i in range(box.y, box.y + box.h):
            for j in range(box.x, box.x + box.w):
                self.matrix[i][j] = self.bkg
    def __setitem__(self, key: tuple[int, int], value: str):
        self.matrix[key[0]][key[1]] = value
class GraphicRect(Rect):
    def __init__(self, y: int, x: int, w: int, h: int, repr_char: str):
        self.old_y = y
        self.old_x = x
        super().__init__(y, x, w, h)
        self.chr = repr_char
        self.needs_update = False
    def move(self, y: int=0, x: int=0):
        self.old_y = self.y
        self.old_x = self.x
        self.y += y
        self.x += x
        self.needs_update = True
    def draw(self, display: Display):
        display.remove(Rect(
            self.old_y, self.old_x,
            self.w, self.h
        ))
        for i in range(self.h):
            for j in range(self.w):
                display[i,j] = self.chr