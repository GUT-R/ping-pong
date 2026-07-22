from typing import Iterable, overload

class Rect:
    """Representa um retângulo com posição, tamanho e um código cor entre 0 e 255.
    
    Limitações:
    - `sx` e `sy` possuem um limite de 0 à 255
    - O objeto não pode estar numa posição menor que 0 e maior que 65535
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
        """Define uma nova posição e armazena a anterior"""
    
    def sum_pos(
        self,
        x: int = 0,
        y: int = 0
    ) -> None:
        """Soma `x` e `y` às posições e armazena a anteior"""
    
    def move(
        self,
        x: int = 1,
        y: int = 1
    ) -> None:
        """Adiciona `x` e `y` multiplicados pela velocidade nas posições e armazena a anterior"""
    def set_color(
        self,
        new_color: int
    ) -> None:
        """Define um código de cor entre 0 e 255 ao rect. (e também armazena o anterior)"""


class Display:
    """Representa a tela.
    
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
        """Limpa o buffer. (display esquece onde colocar pixels)"""
    def update_all(self, rects: Iterable[Rect]) -> None:
        """Armazena somente os pixels atualizados em cada `Rect`"""
    def print_buffer(self) -> None:
        """Imprime os pixels armazenados"""

class Scene:
    """Representa uma cena com objetos 2D"""
    display: Display
    rects: list[Rect]
    def __init__(self, display: Display, rects: list[Rect]) -> None: ...
    def print_scene(self) -> None:
        """Imprime a cena inteira"""
    def print_buffer(self) -> None:
        """Imprime somente os pixels atualizados"""