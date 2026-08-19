.PHONY: all venv dependencies cython

ifeq ($(OS),Windows_NT)
    VENV_PYTHON := .venv/Scripts/python.exe
    
    PYTHONVENV_PIP := .venv/Scripts/pip.exe := python
    SHELL := cmd.exe
    .SHELLFLAGS := /C
else
    VENV_PYTHON := .venv/bin/python
    VENV_PIP := .venv/bin/pip
    PYTHON := python3
endif

all: venv dependencies cython

venv:
	$(PYTHON) -m venv .venv

dependencies:
	$(VENV_PIP) install -r requirements.txt

cython:
	cd almighty && ../$(VENV_PYTHON) setup.py build_ext --inplace