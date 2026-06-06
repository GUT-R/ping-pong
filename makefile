.PHONY: all venv cython

all: venv cython

venv:
	python3 -m venv .venv && .venv/bin/pip install -r dependencies.txt

cython:
	cd cython && ../.venv/bin/python setup.py build_ext --inplace
