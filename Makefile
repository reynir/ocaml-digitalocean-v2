OCAMLBUILD=ocamlbuild -use-ocamlfind

.PHONY: all examples clean

all: main.native examples _tags

main.native: src/*.ml
	${OCAMLBUILD} src/main.native

examples: www.native updateA.native images.native domain.native mailstache.native

www.native: examples/www.ml
	${OCAMLBUILD} examples/www.native

updateA.native: examples/updateA.ml
	${OCAMLBUILD} examples/updateA.native

images.native: examples/images.ml
	${OCAMLBUILD} examples/images.native

domain.native: examples/domain.ml
	${OCAMLBUILD} examples/domain.native

mailstache.native: examples/mailstache.ml
	${OCAMLBUILD} examples/mailstache.native

clean:
	${OCAMLBUILD} -clean
