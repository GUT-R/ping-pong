from almighty.main import Display, Rect, Scene
from time import sleep
from utils import clear, hexstring_to_tuple as _

display = Display(40, 20, background_color=0, colors=[
    _("#99D6A3"), # Cor de fundo
    _("#8ECC4C"), # preenchimento 1 (para o rect1)
    _("#54B249"), # preenchimento 2 (para o rect2)
])

# Rect(id, cor, x, y, largura, altura, velocidade)
rect1 = Rect(1, 0, 0, 3, 2, 1)
rect2 = Rect(2, 2, 2, 4, 1, 1)

scene = Scene(display, {
    'A': rect1,
    'B': rect2,
})

def main():
    clear()
    scene.print_scene()
    sleep(1)
    scene.A.move(1, 0)
    clear()
    scene.print_scene()
    sleep(2)

if __name__ == '__main__':
    main()