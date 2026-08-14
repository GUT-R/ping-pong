from almighty.main import Display, Rect, Scene
from time import sleep
from utils import clear, hexstring_to_tuple as _

display = Display(40, 20, background_color=0, colors=[
    _("#FFFFFF"), # Cor de fundo
    _("#A3A3A3"), # cor de objeto
    _("#FF0000"), # 2 Colisao superior
    _("#0000FF"), # 3 Colisao inferior
    _("#AA0000"), # 4 Colisao esquerda
    _("#0000AA"), # 5 Colisao direita
    _("#FF00FF"), # 6 Colisao de canto
    _("#000000"), # 7 Colisao impossivel
])
def main():
    # Rect(id, cor, x, y, largura, altura, velocidade)
    rect1 = Rect(1, 0, 0, 3, 2, 1)
    rect2 = Rect(2, 2, 2, 4, 1, 1)

    scene = Scene(display, {
        'A': rect1,
        'B': rect2,
    })
    clear()
    scene.print_scene()
    sleep(1)
    for _ in range(5):
        scene.A.move(x=1)
        scene.print_buffer()
        sleep(0.33)
    scene.exit()

def force_back(scene: Scene, rect_name: str):
    r = scene[rect_name]
    scene[rect_name].set_pos(
        x=max(0, min(r.x, scene.display.w - r.w)),
        y=max(0, min(r.y, scene.display.h - r.h))
    )

def test():
    clear()
    print('******\n*****2*\n******\n')
    sleep(1)
    print('\033[00002;00003H##')
    sleep(5)
    print('\033[00004;00000H') # pula pra linha final
    
def test_collision():
    scene = Scene(display, {
        'Box': Rect(color=1, w=1, h=1, y=display.h//2 - 1, x=display.w//2 - 1)
    })
    for i in range(display.h):
        for j in range(display.w):
            rect = Rect(color=0, y=i, x=j)
            t, d, l, r = scene.Box.border_collision(rect)
            if not (t or d or l or r):
                continue
            color = 7
            if ((t and l) or (t and r) or (d and l) or (d and r)):
                color = 6
            if t and not any((d, l, r)):
                color = 2
            elif d and not any((t, l, r)):
                color = 3
            elif l and not any((t, d, r)):
                color = 4
            elif r and not any((t, d, l)):
                color = 5
            rect.set_color(color)
            scene.rects[f'{i}X{j}'] = rect
    clear()
    scene.print_scene()
def test_one_collision():
    scene = Scene(display, {
        'Box': Rect(color=1, w=1, h=1, y=display.h//2 - 1, x=display.w//2 - 1)
    })
    for i in range(display.h):
        for j in range(display.w):
            color = 7
            rect = Rect(color, y=i, x=j)
            t, b, l, r = scene.Box.border_collision(rect)
            if not (t or b or l or r):
                continue
            if r:
                color = 2
            rect.set_color(color)
            scene.rects[f'{i}X{j}'] = rect
    clear()
    scene.print_scene()
if __name__ == '__main__':
    test_one_collision()
