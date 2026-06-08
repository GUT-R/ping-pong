from almighty.main import Display, GraphicRect, Scene

def test():
    # Informação importante: FUNCIONA :D
    display = Display(10, 10, '.')
    ball = GraphicRect('Ball','#')
    Scene(display, [ball])
if __name__ == '__main__':
    test()