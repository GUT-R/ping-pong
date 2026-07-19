from almighty.main import Rect, Display, Scene

display = Display(4, 3, 0b10_101_000)

scene = Scene(display, [
    Rect('Bola', 0b00_111_000, w=1, h=1, y=0, x=0)
])

scene.print_scene()