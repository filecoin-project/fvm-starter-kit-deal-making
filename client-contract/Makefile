check-deps:
	@cargo -V > /dev/null
	@forge -V > /dev/null

build: check-deps
	forge build
.PHONY: build

test: check-deps
	forge test
.PHONY: test

clean: check-deps
	forge clean
.PHONY: clean

