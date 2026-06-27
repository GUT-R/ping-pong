from typing import Iterable, overload

class GraphicRect:
    id: str
    repr: str
    x: int
    y: int
    w: int
    h: int
    sx: int
    sy: int
    
    @overload
    def __init__(
        self, ID: str, representating_char: str,
        _scale: int=1,
        _speed: int=1,
    ) -> None: ...
    @overload
    def __init__(
        self, ID: str, representating_char: str,
        w: int=1, h: int=1,
        _speed: int=1,
    ) -> None: ...
    @overload
    def __init__(
        self, ID: str, representating_char: str,
        w: int=1, h: int=1,
        sx: int=1, sy: int=1,
    ) -> None: ...
    @overload
    def __init__(
        self, ID: str, representating_char: str,
        x: int=0, y: int=0, 
        w: int=1, h: int=1, 
        sx:int=1, sy:int=1
    ) -> None: ...
    def __init__(
        self,
        ID: str,
        representating_char: str,
        *args: int,
        **kwargs: int
    ) -> None: ...
    
    
    def set_pos(
        self,
        x: int = 1,
        y: int = 1
    ) -> None: ...
    
    def sum_pos(
        self,
        x: int = 1,
        y: int = 1
    ) -> None: ...
    
    def move(
        self,
        x: int = 1,
        y: int = 1
    ) -> None: ...


class Display:
    w: int
    h: int
    bkg: str
    bkg_size: int
    matrix: list[list[str]]

    def __init__(
        self,
        w: int,
        h: int,
        background_char: str
    ) -> None: ...

    def render(self) -> str: ...

class Scene:
    def __init__(self, display: Display, rects: Iterable[GraphicRect], fps: float=24.0) -> None: ...
    def frame(self) -> None:
        """Apenas atualiza o buffer. Ainda não emprime nada."""