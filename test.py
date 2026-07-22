from almighty.main import Rect, Display, Scene
def _(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip('#')
    if len(hex_color) != 6:
        raise ValueError('Formato inválido')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4)) # type: ignore

display = Display(4, 3, 0, [
    _("#00FFC3"),
    _("#FF0000"),
])

scene = Scene(display, [
    Rect('Bola', color=1, w=1, h=1, y=1, x=0)
])

scene.print_scene()