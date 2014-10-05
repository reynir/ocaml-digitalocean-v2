OCAMLBUILD=ocamlbuild -use-ocamlfind

all: main.native

main.native: src/main.ml
	${OCAMLBUILD} src/main.native

clean:
	${OCAMLBUILD} -clean
