from almighty.main import Rect, Display, Scene

display = Display(6, 6, 100)

scene = Scene(display, [
    Rect('Bola', 10, w=1, h=1, y=1, x=1)
])

scene.print_scene()