OCAMLBUILD=ocamlbuild -use-ocamlfind

.PHONY: all examples clean

all: main.native _tags

examples: www.native updateA.native

main.native: src/*.ml
	${OCAMLBUILD} src/main.native

www.native: examples/www.ml
	${OCAMLBUILD} examples/www.native

updateA.native: examples/updateA.ml
	${OCAMLBUILD} examples/updateA.native

clean:
	${OCAMLBUILD} -clean
