from typing import Iterable
def set_cursor_position(x: int, y: int):
    print(f'\033[{y};{x}H')
def replace_positions(XYs: Iterable[tuple[int, int]], ch: str):
    return ''.join(map(
        lambda xy: f'\033[{xy[1]};{xy[0]}H{ch}',
        XYs
    ))
def reset_cursor_position():
    print(f'\033[0;0H')