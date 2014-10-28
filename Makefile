OCAMLBUILD=ocamlbuild -use-ocamlfind

all: main.native _tags

main.native: src/*.ml
	${OCAMLBUILD} src/main.native

clean:
	${OCAMLBUILD} -clean
