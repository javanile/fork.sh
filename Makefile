
BIN ?= lcov.sh
PREFIX ?= /usr/local

install:
	install ./fork.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

release:
	git add .
	git commit -am "Release"
	git push
