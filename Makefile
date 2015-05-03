OCAMLBUILD=ocamlbuild -use-ocamlfind

.PHONY: all examples clean

all: main.native _tags

examples: www.native update-A.native

main.native: src/*.ml
	${OCAMLBUILD} src/main.native

www.native: examples/www.ml
	${OCAMLBUILD} examples/www.native

update-A.native: examples/update-A.ml
	${OCAMLBUILD} examples/update-A.native

clean:
	${OCAMLBUILD} -clean
