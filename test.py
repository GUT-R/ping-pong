from almighty.main import Rect, Display, Scene

display = Display(6, 6, 0b00_000_00)

scene = Scene(display, [
    Rect('Bola', 0b00_111_000, w=1, h=1, y=1, x=1)
])

scene.print_scene()