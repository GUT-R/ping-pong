from os import name as os_name
from subprocess import run

def hexstring_to_tuple(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip('#')
    if len(hex_color) != 6:
        raise ValueError('Formato inválido')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4)) # type: ignore

def clear():
    run('cls' if os_name == 'nt' else 'clear')