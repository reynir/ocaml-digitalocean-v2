OCAMLBUILD=ocamlbuild -use-ocamlfind

all: main.native

main.native: src/*.ml
	${OCAMLBUILD} src/main.native

clean:
	${OCAMLBUILD} -clean
