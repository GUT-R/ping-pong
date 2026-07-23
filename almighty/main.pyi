from typing import Iterable, overload

class Rect:
    """Representa um retângulo 2D com posição, tamanho, cor e velocidade.

    Limitações:
    - `sx` e `sy` ficam entre 0 e 255
    - as coordenadas permanecem entre 0 e 65535
    """
    id: str
    sx: int
    sy: int
    
    @overload
    def __init__(
        self, ID: str, color: int,
        _scale: int=1,
        _speed: int=1,
    ) -> None: ...
    @overload
    def __init__(
        self, ID: str, color: int,
        w: int=1, h: int=1,
        _speed: int=1,
    ) -> None: ...
    @overload
    def __init__(
        self, ID: str, color: int,
        w: int=1, h: int=1,
        sx: int=1, sy: int=1,
    ) -> None: ...
    @overload
    def __init__(
        self, ID: str, color: int,
        x: int=0, y: int=0,
        w: int=1, h: int=1,
        _speed: int=1
    ) -> None: ...
    @overload
    def __init__(
        self, ID: str, color: int,
        x: int=0, y: int=0, 
        w: int=1, h: int=1, 
        sx:int=1, sy:int=1
    ) -> None: ...
    def __init__(
        self,
        ID: str,
        color: int,
        *args: int,
        **kwargs: int
    ) -> None: ...
    
    
    def set_pos(
        self,
        x: int = 1,
        y: int = 1
    ) -> None:
        """Move o retângulo para a posição absoluta especificada e salva a posição anterior."""

    def sum_pos(
        self,
        x: int = 0,
        y: int = 0
    ) -> None:
        """Ajusta a posição do retângulo somando os valores `x` e `y`, preservando a posição anterior."""

    def move(
        self,
        x: int = 1,
        y: int = 1
    ) -> None:
        """Desloca o retângulo pelos valores `x` e `y` multiplicados pela velocidade atual."""

    def set_color(
        self,
        new_color: int
    ) -> None:
        """Atualiza o código de cor do retângulo para um valor entre 0 e 255 e guarda a cor anterior."""


class Display:
    """Representa a tela de renderização, incluindo dimensões e paleta de cores.

    Limitações:
    - `w` e `h` devem estar entre 0 e 65535
    - `background_color` deve estar entre 0 e 255
    """
    w: int
    h: int
    color: int

    def __init__(
        self,
        w: int,
        h: int,
        background_color: int,
        colors: list[tuple[int, int, int]]
    ) -> None: ...

    def reset_buffer(self) -> None:
        """Limpa o buffer interno para preparar a próxima renderização."""

    def update_all(self, rects: Iterable[Rect]) -> None:
        """Atualiza o buffer apenas com os pixels alterados pelos retângulos fornecidos."""

    def print_buffer(self) -> None:
        """Imprime o buffer atual de pixels na saída de renderização."""

class Scene:
    """Representa uma cena 2D composta por uma tela e um conjunto de retângulos."""
    display: Display
    rects: list[Rect]
    def __init__(self, display: Display, rects: list[Rect]) -> None: ...
    def print_scene(self) -> None:
        """Renderiza a cena completa, incluindo todos os retângulos e o fundo."""
    def print_buffer(self) -> None:
        """Renderiza apenas os pixels modificados desde a última atualização."""