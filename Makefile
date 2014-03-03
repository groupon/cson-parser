
SRC = $(shell find src -name "*.coffee" -type f | sort)
LIB = $(SRC:src/%.coffee=lib/%.js)

COFFEE=node_modules/.bin/coffee --js

all: clean setup test check-checkout-clean

build: $(LIB)
	@./node_modules/.bin/npub prep lib

prepublish:
	./node_modules/.bin/npub prep

lib/%.js: src/%.coffee
	dirname "$@" | xargs mkdir -p
	$(COFFEE) <"$<" >"$@"

clean:
	rm -rf lib node_modules

test: build
	npm test

release: all
	git push --tags origin HEAD:master
	npm publish

setup:
	npm install

# This will fail if there are unstaged changes in the checkout
check-checkout-clean:
	git diff --exit-code
