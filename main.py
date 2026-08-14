from almighty.main import Display, Rect
from ui import PingPongUI
from utils import clear, hexstring_to_tuple as _, getch
from random import choice
import asyncio

display = Display(40, 20, 0, colors=[
    _("#B0D6CD"),
    _("#59B2F6"),
    _("#E65757"),
])
CENTER_X = display.w//2
CENTER_Y = display.h//2

scene = PingPongUI(display, {
    'Ball': Rect(color=1, x=CENTER_X, y=CENTER_Y),
    'Player1': Rect(color=2, h=3, x=2, y=CENTER_Y-2),
    'Player2': Rect(color=2, h=3, x=display.w - 3, y=CENTER_Y-2),
})

running = True

def bounce_ball_for_player(playerID: str):
    sx, sy = scene.Ball.sx, scene.Ball.sy # Ball speed
    top, bottom, left, right = scene.Ball.border_collision(scene[playerID])
    if top and sy > 0:
        scene.Ball.sy = -1
    if bottom and sy < 0:
        scene.Ball.sy = 1
    if left and sx > 0:
        scene.Ball.sx = -1
    if right and sx < 0:
        scene.Ball.sx = 1

def bounce_ball():
    bounce_ball_for_player('Player1')
    bounce_ball_for_player('Player2')

def reset_ball():
    scene.Ball.set_pos(
        CENTER_X,
        CENTER_Y
    )
    scene.Ball.sx = choice((-1, 1))
    scene.Ball.sy = choice((-1, 1))
 
async def ball_func():
    reset_ball()
    await asyncio.sleep(3)
    while running:
        bounce_ball()
        # Rebate a bola no teto e no chão
        x, y = scene.Ball.x, scene.Ball.y
        if y <= 0 or y >= display.h - scene.Ball.h:
            scene.Ball.sy *= -1
        
        if x <= 0: # Se a bola encostou na parede da esquerda
            scene.score_player_2 += 1
            reset_ball()
            await asyncio.sleep(3)
        if x >= display.w - scene.Ball.w: # Se a bola encostou na parede da direita
            scene.score_player_1 += 1
            reset_ball()
            await asyncio.sleep(3)
        
        scene.Ball.move(1, 1)
        await asyncio.sleep(0.1)

async def game_controller():
    global running
    while running:
        match await getch():
            case 'w':
                if scene.Player1.y > 0:
                    scene.Player1.move(y = -1)
            case 's':
                if scene.Player1.y < display.h - scene.Player1.h:
                    scene.Player1.move(y = 1)
            case '\x1b[A':
                if scene.Player2.y > 0:
                    scene.Player2.move(y = -1)
            case '\x1b[B':
                if scene.Player2.y < display.h - scene.Player2.h:
                    scene.Player2.move(y = 1)
            case 'x':
                running = False
            case _: pass
        

async def render():
    clear()
    scene.print_scene()
    while running:
        scene.print_buffer()
        await asyncio.sleep(0.01)

async def main():
    await asyncio.gather(
        render(),
        ball_func(),
        game_controller(),
    )
    scene.exit()

if __name__ == '__main__':
    asyncio.run(main())