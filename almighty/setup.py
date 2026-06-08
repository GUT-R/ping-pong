from setuptools import setup
from Cython.Build import cythonize

setup(
    name="The Almighty",
    ext_modules=cythonize("src/main.pyx"),
    author="GUTR3213X",
    author_email="augusto.borges@academico.ifrn.edu.br",
)