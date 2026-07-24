from almighty.main import Display, Rect, Scene
from time import sleep
from utils import clear, hexstring_to_tuple as _

display = Display(40, 20, background_color=0, colors=[
    _("#99D6A3"), # Cor de fundo
    _("#8ECC4C"), # preenchimento 1 (para o rect1)
    _("#54B249"), # preenchimento 2 (para o rect2)
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

def bouncy_ball():
    scene = Scene(display, {
        'Ball': Rect(color=1, w=4, h=4, y=display.h//2 - 2, x=display.w//2 - 2)
    })
    clear()
    try:
        scene.print_scene()
        while True:
            b = scene.Ball
            
            if b.x < 0 or b.x + b.w >= display.w: # verifica se a bola bateu na borda esquerda ou direita
                scene.Ball.sx *= -1
            if b.y < 0 or b.y + b.h >= display.h: # verifica se a bola bateu na borda superior ou inferior
                scene.Ball.sy *= -1
            
            scene.Ball.move(1, 1)
            scene.print_buffer()
            sleep(0.3)
    except Exception:
        scene.exit()

def test():
    clear()
    print('******\n******\n******\n')
    sleep(1)
    print('\033[00002;00003H##')
    sleep(5)
    print('\033[00004;00000H') # pula pra linha final
    

if __name__ == '__main__':
    bouncy_ball()