def set_cursor_position(x: int, y: int):
    print(f'\033[{x};{y}H')
def reset_cursor_position():
    print(f'\033[0;0H')