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
	docker build -t javanile/fork.sh:macos .
	docker push javanile/fork.sh:macos

fork:
	curl -sL git.io/fork.sh | bash -

lint:
	shellcheck *.sh

## -------
## Testing
## -------
test: test-hard test-inheritance test-prototype test-source test-update
	@echo "FORK.SH Test Done."

test-hard:
	@bash test/hard-test.sh

test-inheritance:
	@bash test/inheritance-test.sh

test-missing-forkfile:
	@bash test/missing-forkfile-test.sh

test-move:
	@bash test/move-test.sh

test-prototype:
	@bash test/prototype-test.sh

test-source:
	@bash test/source-test.sh

test-touch:
	@bash test/touch-test.sh

test-update:
	@bash test/update-test.sh

test-dircopy:
	@bash test/dircopy-test.sh
