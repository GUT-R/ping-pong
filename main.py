from typing import Iterable
from time import sleep
from term_cursor import reset_cursor_position
import os
class Rect:
    def __init__(self, x: int, y: int, w: int, h: int):
        self.x = x
        self.y = y
        self.w = w
        self.h = h

def collision(r1: Rect, r2: Rect):
    return (
        r1.x < r2.x - r2.w and
        r1.x + r1.w > r2.x and
        r1.y < r2.y + r2.h and
        r1.y + r1.h > r2.y
    )
    
class GraphicRect(Rect):
    def __init__(self, ID: str, x: int, y: int, w: int, h: int, speed_x: int, speed_y: int, character_level: int):
        self.old_self = Rect(x, y, w, h)
        super().__init__(x, y, w, h)
        self.char_lvl = character_level
        self.needs_update = False
        self.speed_x, self.speed_y = speed_x, speed_y
        self.id = ID
    
    def set_pos(self, x: int=0, y: int=0):
        self.old_self.y = self.y
        self.old_self.x = self.x
        self.y = y
        self.x = x
        self.needs_update = True
    
    def sum_pos(self, x: int=0, y: int=0):
        self.set_pos(self.x + x, self.y + y)
    
    def move(self, x: int=1, y: int=1):
        self.sum_pos(self.speed_x * x, self.speed_y * y)

class Display:
    def __init__(self, w: int, h: int, background_char_levels: list[str]):
        self.w = w
        self.h = h
        self.bkg_lvls = background_char_levels
        self.bkg = background_char_levels[0]
        self.matrix: list[list[int]] = [[0 for _ in range(w)] for _ in range(h)]
    
    def clear(self, rect: Rect):
        for i in range(rect.y, rect.y + rect.h):
            for j in range(rect.x, rect.x + rect.w):
                self.matrix[i][j] = 0
    
    def draw(self, rect: GraphicRect):
        for i in range(rect.y, rect.y + rect.h):
            for j in range(rect.x, rect.x + rect.w):
                self.matrix[i][j] = rect.char_lvl
        rect.needs_update = False
    
    def render(self) -> str:
        output: list[str] | tuple[str, ...] = []
        for line in self.matrix:
            output.append(''.join(map(str, line))) # type: ignore
        
        for i, ch in enumerate(self.bkg_lvls):
            output = tuple(map(lambda l: l.replace(str(i), ch), output)) # ['010'] -> ['.#.', '..#']
        return '\n'.join(output) # ['.#.', '..#'] -> '.#.\n..#'

    def __setitem__(self, key: tuple[int, int], value: int):
        self.matrix[key[0]][key[1]] = value

class Scene:
    def __init__(self, display: Display, rects: Iterable[GraphicRect], fps: float = 60):
        self.display = display
        self.rects = {rect.id: rect for rect in rects}
        self.fps = fps
    def frame(self):
        for rect in self.rects.values():
            if rect.needs_update:
                self.display.clear(rect.old_self)
        for rect in self.rects.values():
            if rect.needs_update:
                self.display.draw(rect)
        reset_cursor_position()
        print(self.display.render())
        sleep(0.1)
    def wall_collision(self, rect_id: str) -> tuple[bool, bool, bool, bool]:
        """Check whether a rectangle is colliding with any display wall.

        Args:
            rect_id (str): Identifier of the rectangle to test.

        Returns:
            tuple[bool, bool, bool, bool]: Collision flags in the order
                (left, right, top, bottom).
        """
        rect = self[rect_id]
        return (
            rect.x <= 0,
            rect.x + rect.w >= self.display.w,
            rect.y <= 0,
            rect.y + rect.h >= self.display.h,
        )
    def __getitem__(self, key: str) -> GraphicRect:
        return self.rects[key]
def main():
    display = Display(100, 20, ['.', '#'])
    scene = Scene(display, [
        GraphicRect('Ball', 0, 0, 2, 2, 1, 1, 1)
    ], 24)
    scene['Ball'].set_pos(
        display.w // 2 - scene['Ball'].w // 2,
        display.h // 2 - scene['Ball'].h // 2
    )
    collisions = 0
    os.system('clear')
    while collisions < 10:
        wall_coll = scene.wall_collision('Ball')
        if bool(sum(wall_coll)):
            collisions += 1
        if wall_coll[0] or wall_coll[1]:
            scene['Ball'].speed_x *= -1
        if wall_coll[2] or wall_coll[3]:
            scene['Ball'].speed_y *= -1
        scene['Ball'].move()
        scene.frame()
if __name__ == '__main__':
    main()