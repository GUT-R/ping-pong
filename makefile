.PHONY: all venv dependencies cython

OS := $(shell uname 2>dev/null || echo Windows)

ifeq ($(OS), Windows)
    VENV_PYTHON := .venv\Scripts\python.exe
	VENV_PIP := .venv\Scripts\pip.exe
	CD = cd /d
else
	VENV_PYTHON := .venv/bin/python
	VENV_PIP := .venv/bin/pip
	CD = cd
endif

all: venv dependencies cython

venv:
	python3 -m venv .venv

dependencies:
	$(VENV_PIP) install -r requirements.txt

cython:
	$(CD) almighty && $(VENV_PYTHON) setup.py build_ext --inplace