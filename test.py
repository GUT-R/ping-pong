from almighty.main import Display, GraphicRect, Scene

def test():
    # Informação importante: FUNCIONA :D
    display = Display(10, 10, '.')
    ball = GraphicRect('Ball','#')
    scene = Scene(display, [ball])
    scene.frame()

if __name__ == '__main__':
    test()