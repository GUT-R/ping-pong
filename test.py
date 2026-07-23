from almighty.main import Display, Rect, Scene
from time import sleep
from utils import clear, hexstring_to_tuple as _

display = Display(20, 20, background_color=0, colors=[
    _("#99D6A3"), # display background
    _("#8ECC4C"), # rect1
    _("#54B249"), # rect2
])

# Rect(id, cor, x, y, largura, altura, velocidade)
rect1 = Rect('A', 1, 0, 0, 3, 2, 1)
rect2 = Rect('B', 2, 2, 2, 4, 1, 1)
scene = Scene(display, [rect1, rect2])

def main():
    clear()
    scene.print_scene()
    sleep(3)

if __name__ == '__main__':
    main()