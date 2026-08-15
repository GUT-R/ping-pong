import sys
import termios
import tty
import asyncio
from os import name as os_name
from subprocess import run
from typing import Any
import re

def hexstring_to_tuple(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip('#')
    if len(hex_color) != 6:
        raise ValueError('Formato inválido')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4)) # type: ignore

def colorize_background(string: Any, color: tuple[int, int, int]):
    r, g, b = color
    return f'\033[48;2;{r};{g};{b}m{string}'

def colorize_fore(string: Any, color: tuple[int, int, int]):
    r, g, b = color
    return f'\033[38;2;{r};{g};{b}m{string}'

def clear():
    run('cls' if os_name == 'nt' else 'clear')

def getch():
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)  # modo raw: lê tecla direto
        ch = sys.stdin.read(1)  # lê 1 caractere
        if ch == '\x1b':  # possível tecla especial
            ch += sys.stdin.read(2)  # tenta ler resto
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    return ch

async def async_getch():
    return await asyncio.to_thread(getch)

def move_cursor(x: int, y: int):
    print(f'\033[{y};{x}H', end='', flush=False)


# ========== MADE WITH ChatGPT ==========
_ANSI_SGR = re.compile(r"\x1B\[[0-9;]*m")
def strip_ansi(o: str) -> str:
    """
    Removes ANSI SGR escape sequences from `o`.

    Supports standard colors, 256 colors and true-color RGB
    foreground/background sequences.

    Examples
    --------
    >>> strip_ansi("\\033[31mLorem ipsum\\033[0m")
    'Lorem ipsum'

    >>> strip_ansi("\\033[38;5;32mLorem ipsum\\033[0m")
    'Lorem ipsum'

    >>> strip_ansi("\\033[38;2;255;100;50mLorem ipsum\\033[0m")
    'Lorem ipsum'

    >>> strip_ansi("\\033[48;2;20;40;80mLorem ipsum\\033[0m")
    'Lorem ipsum'

    >>> strip_ansi("\\033[38;2;255;100;50;48;2;20;40;80mLorem ipsum\\033[0m")
    'Lorem ipsum'

    >>> strip_ansi("Lorem")
    'Lorem'

    >>> strip_ansi("")
    ''
    """

    return _ANSI_SGR.sub("", o)