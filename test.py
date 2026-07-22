from almighty.main import Rect, Display, Scene

def _(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip('#')
    if len(hex_color) != 6:
        raise ValueError('Formato inválido')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4)) # type: ignore

display = Display(50, 20, 0, [
    _("#3F625A"),
    _("#C5E4C0"),
])

w, h, y, x = [int(i) for i in input('[w, h, y, x]=').split()]

scene = Scene(display, [
    Rect('Bola', 1, w=w, h=h, y=y, x=x)
])

scene.print_scene()