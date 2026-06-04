from term_cursor import reset_cursor_position
from time import sleep
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
    
    def render(self) -> str:
        return '\n'.join(map(''.join, self.matrix))
    
    def __setitem__(self, key: tuple[int, int], value: str):
        self.matrix[key[0]][key[1]] = value
    
class GraphicRect(Rect):
    def __init__(self, x: int, y: int, w: int, h: int, speed_x: int, speed_y: int, repr_char: str):
        self.old_x = x
        self.old_y = y
        super().__init__(y, x, w, h)
        self.chr = repr_char
        self.needs_update = False
        self.speed_x, self.speed_y = speed_x, speed_y
    
    def set_pos(self, x: int=0, y: int=0):
        self.old_y = self.y
        self.old_x = self.x
        self.y = y
        self.x = x
        self.needs_update = True
    
    def sum_pos(self, x: int=0, y: int=0):
        self.set_pos(self.x + x, self.y + y)
    
    def move(self, x: int=1, y: int=1):
        self.sum_pos(self.speed_x * x, self.speed_y * y)
    
    def draw(self, display: Display):
        display.clear(Rect(
            self.old_x, self.old_y,
            self.w, self.h
        ))
        for i in range(self.y, self.y + self.h):
            for j in range(self.x, self.x + self.w):
                display[i, j] = self.chr
        self.needs_update = False

def main():
    display = Display(50, 20, '.')
    ball = GraphicRect(0,0, 2, 2, 1, 1, '#')
    ball.set_pos(
        display.w // 2 - ball.w // 2,
        display.h // 2 - ball.h // 2,
    )
    collisions = 0
    running = True
    os.system('clear')
    while running:
        reset_cursor_position()
        if ball.x <= 0 or ball.x + ball.w >= display.w:
            collisions += 1
            ball.speed_x *= -1
        if ball.y <= 0 or ball.y + ball.h >= display.h:
            ball.speed_y *= -1
            collisions += 1
        if collisions > 20:
            running = False
        ball.move()
        ball.draw(display)
        print(display.render())
        sleep(0.1)

if __name__ == '__main__':
    main()