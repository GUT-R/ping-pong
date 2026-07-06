from typing import Iterable, overload

class GraphicRect:
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
    def set_color(
        self,
        new_color: int
    ) -> None: ...


class Display:
    w: int
    h: int
    bkg: str
    bkg_size: int

    def __init__(
        self,
        w: int,
        h: int,
        background_char: str
    ) -> None: ...

    def reset_buffer(self) -> None: ...
    def update_all(self, rects: Iterable[GraphicRect]) -> None: ...
    def print_buffer(self) -> None: ...

class Scene:
    display: Display
    rects: Iterable[GraphicRect]
    fps: float
    def __init__(self, display: Display, rects: Iterable[GraphicRect], fps: float=24.0) -> None: ...
    def print_scene(self) -> None:
        """Imprime a cena inteira"""
    def print_buffer(self) -> None:
        """Imprime somente os pixels modificados"""