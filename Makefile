#!make

BIN ?= fork.sh
PREFIX ?= /usr/local

install:
	install ./fork.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

release: push

push:
	git config credential.helper 'cache --timeout=3600'
	git pull
	git add .
	git commit -am "Release" || true
	git push
	docker build -t javanile/fork.sh .
	docker push javanile/fork.sh:latest

fork:
	curl -sL git.io/fork.sh | bash -

lint:
	shellcheck *.sh

## -------
## Testing
## -------
test: test-hard test-inheritance test-prototype
	@echo "FORK.SH Test Done."

test-hard:
	@bash test/hard-test.sh

test-inheritance:
	@bash test/hard-test.sh

test-prototype:
	@bash test/prototype-test.sh
