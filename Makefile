OCAMLBUILD=ocamlbuild -use-ocamlfind

all: main.native _tags

main.native: src/*.ml
	${OCAMLBUILD} src/main.native

www.native: examples/www.ml
	${OCAMLBUILD} examples/www.native

clean:
	${OCAMLBUILD} -clean
