all: clean setup test check-checkout-clean

build:
	@./node_modules/.bin/npub prep
	@./node_modules/.bin/coffee -cbo lib src

prepublish:
	./node_modules/.bin/npub prep

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
