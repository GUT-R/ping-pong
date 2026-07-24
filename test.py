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

def force_back(scene: Scene, rect_name: str):
    r = scene[rect_name]
    scene[rect_name].set_pos(
        x=max(0, min(r.x, scene.display.w - r.w)),
        y=max(0, min(r.y, scene.display.h - r.h))
    )

def bouncy_ball():
    scene = Scene(display, {
        'Ball': Rect(color=1, w=4, h=4, y=display.h//2 - 2, x=display.w//2 - 2)
    })
    scene.Ball.sx = 4
    scene.Ball.sy = 2
    x = 1
    y = 1
    try:
        clear()
        scene.print_scene()
        while True:
            b = scene.Ball # Só uma abreviação para não ficar escrevendo `scene.Ball` toda hora
            
            if b.x <= 0 or b.x + b.w >= display.w: # verifica se a bola bateu na borda esquerda ou direita
                x *= -1
                force_back(scene, 'Ball') # A bola pode pular para fora da janela se a velocidade for muito alta. Essa função força ela a ficar dentro da cena
            if b.y <= 0 or b.y + b.h >= display.h: # verifica se a bola bateu na borda superior ou inferior
                y *= -1
                force_back(scene, 'Ball')
            
            scene.Ball.move(x, y)
            scene.print_buffer()
            sleep(0.2)
    except KeyboardInterrupt: # Para o programa com Ctrl+C (não me culpe se na sua máquina for diferente)
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