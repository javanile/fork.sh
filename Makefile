
BIN ?= fork.sh
PREFIX ?= /usr/local

install:
	install ./fork.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

release:
	git add .
	git commit -am "Release"
	git push
	docker build -t javanile/fork.sh .
	docker push javanile/fork.sh:latest

tdd:
	bash test/inheritance-test.sh
