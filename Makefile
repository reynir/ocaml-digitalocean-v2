OCAMLBUILD=ocamlbuild -use-ocamlfind

all: main.native _tags

main.native: src/*.ml
	${OCAMLBUILD} src/main.native

add_www.native: examples/add_www.ml
	${OCAMLBUILD} examples/add_www.native

clean:
	${OCAMLBUILD} -clean
