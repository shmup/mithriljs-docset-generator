.PHONY: all clean test

all:
	./build-mithril-docset.sh
	@printf "\nNow symlink ${PWD}/build/Mithril.docset to wherever your docsets are stored\n"

clean: ; rm -rf build

test: ; @echo TODO
