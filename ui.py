from almighty.main import Display, Rect, Scene 
from utils import hexstring_to_tuple as _, colorize_fore as cf, colorize_background as cb, move_cursor as mv, strip_ansi
from typing import Any

PLAYER_1_SCORE_COLOR = _("#DA1414")
PLAYER_2_SCORE_COLOR = _("#472DDD")
BOTTOM_MESSAGE_COLOR = _("#4B4B4B")
DIVISION_BAR_COLOR   = _("#8C8C8C")
BACKGROUND_COLOR     = _("#AFECFF")


def c(string: Any, color: tuple[int, int, int]):
    return cb(cf(string, color), BACKGROUND_COLOR)


class PingPongUI(Scene):
    def __init__(self, display: Display, rects: dict[str, Rect]) -> None:
        super().__init__(display, rects)
        self.score_player_1 = 0
        self.score_player_2 = 0


    def print_ui(self) -> None: 
        """Imprime algo depois do frame ser exibido"""
    
    def print_scene(self) -> None:
        super().print_scene()
        self.print_ui()


    def exit(self) -> None:
        super().exit()
        mv(1, self.display.h + 1)

class PrettyUI(PingPongUI):
    def __init__(self, display: Display, rects: dict[str, Rect]) -> None:
        super().__init__(display, rects)

        # dv: division
        self.dv  = c('|', DIVISION_BAR_COLOR)

        # dbd: double dot
        self.dbd = c(':', DIVISION_BAR_COLOR)

        # bmsg: Bottom Message
        self.left_bmsg  = c('[w/s] PLAYER 1', BOTTOM_MESSAGE_COLOR)
        self.right_bmsg = c('[↑/↓] PLAYER 2', BOTTOM_MESSAGE_COLOR)

    @property
    def score(self):
        sp1 = c(f'{self.score_player_1:0>2}', PLAYER_1_SCORE_COLOR)
        sp2 = c(f'{self.score_player_2:0>2}', PLAYER_2_SCORE_COLOR)
        return f'{sp1}{self.dbd}{sp2}'
    
    def _show_score(self):
        score = self.score

        centro = self.display.w - (len(strip_ansi(score)) // 2)
        mv(centro, 1)

        print(score)


    def _show_table_net(self):
        centro = self.display.w

        for i in range(1, self.display.h):
            mv(centro, i + 1)
            print(self.dv, end='')


    def _show_bottom_info(self):
        mv(1, self.display.h + 1)
        print(self.left_bmsg)

        mv((self.display.w*2) + 1 - len(strip_ansi(self.right_bmsg)), self.display.h + 1)
        print(self.right_bmsg)

    def print_ui(self):
        self._show_score()
        self._show_table_net()

    def print_buffer(self) -> None:
        super().print_buffer()
        self.print_ui()

    def print_scene(self) -> None:
        super().print_scene()
        self._show_bottom_info()


class BasicUI(PrettyUI):
    def print_ui(self) -> None:
        self._show_bottom_info()

        score = self.score
        centro = self.display.w - len(strip_ansi(score)) // 2

        mv(centro + 1, self.display.h + 1)
        print(score)