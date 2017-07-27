SHELL := /bin/bash



.PHONY: all   \
        clean

all: clean

clean:
    @log -itn "Cleaning build directory."
    @rm -rf ${build_dir}