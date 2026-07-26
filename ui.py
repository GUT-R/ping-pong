from almighty.main import Display, Rect, Scene 
from utils import hexstring_to_tuple as _, colorize_fore as cf, colorize_background as cb
from typing import Any

PLAYER_1_SCORE_COLOR = _("#DA1414")
PLAYER_2_SCORE_COLOR = _("#472DDD")
DIVISION_BAR_COLOR   = _("#8C8C8C")
BOTTOM_MESSAGE_COLOR = _("#FFFFFF")
BACKGROUND_COLOR     = _("#AFECFF")

def c(string: Any, color: tuple[int, int, int]):
    return cb(cf(string, color), BACKGROUND_COLOR)

class PingPongUI(Scene):
    def __init__(self, display: Display, rects: dict[str, Rect]) -> None:
        super().__init__(display, rects)
        self.score_player_1 = 0
        self.score_player_2 = 0
    def print_ui(self):
        sp1        = c(f'{self.score_player_1:0>2}', PLAYER_1_SCORE_COLOR)
        sp2        = c(f'{self.score_player_2:0>2}', PLAYER_2_SCORE_COLOR)
        dv         = c('|', DIVISION_BAR_COLOR) # divisão
        dbd        = c(':', DIVISION_BAR_COLOR) # double dot
        left_bmsg  = c('[w/s] PLAYER 1', BOTTOM_MESSAGE_COLOR) # left bottom message
        right_bmsg = c('[↑/↓] PLAYER 2', BOTTOM_MESSAGE_COLOR) # right bottom message
        
        centro = (self.display.w * 2 + 1) // 2
        esquerda = 0
        direita = self.display.w * 2 + 1 - len('[ / ] PLAYER *') # Basicamente o formtato das duas mensagens
        
        print(f'\033[1;{centro - 3}H', end='' + f'{sp1}{dbd}{sp2}')
        for i in range(self.display.h - 1):
            print(f'\033[{i + 2};{centro - 1}H' + dv)
        
        print(f'\033[{self.display.h + 1};{esquerda}H' + left_bmsg)
        print(f'\033[{self.display.h + 1};{direita}H' + right_bmsg)
        
    def print_scene(self) -> None:
        super().print_scene()
        self.print_ui()
    
    def print_buffer(self) -> None:
        super().print_buffer()
        self.print_ui()