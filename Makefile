default: build

BINDIR = bin
SRCDIR = src
LIBDIR = lib
TESTDIR = test

SRC = $(shell find "$(SRCDIR)" -name "*.coffee" -type f | sort)
LIB = $(SRC:$(SRCDIR)/%.coffee=$(LIBDIR)/%.js)

COFFEE=node_modules/.bin/coffee --js
MOCHA=node_modules/.bin/mocha --compilers coffee:coffee-script-redux -r coffee-script-redux -r test-setup.coffee -u tdd -R dot

all: build test
build: $(LIB)

lib/%.js: src/%.coffee
	@mkdir -p "$(@D)"
	$(COFFEE) <"$<" >"$@"

.PHONY: phony-dep release test loc clean
phony-dep:

VERSION = $(shell node -pe 'require("./package.json").version')
release-patch: NEXT_VERSION = $(shell node -pe 'require("semver").inc("$(VERSION)", "patch")')
release-minor: NEXT_VERSION = $(shell node -pe 'require("semver").inc("$(VERSION)", "minor")')
release-major: NEXT_VERSION = $(shell node -pe 'require("semver").inc("$(VERSION)", "major")')
release-patch: release
release-minor: release
release-major: release

release: build test
	@printf "Current version is $(VERSION). This will publish version $(NEXT_VERSION). Press [enter] to continue." >&2
	@read
	node -e '\
		var j = require("./package.json");\
		j.version = "$(NEXT_VERSION)";\
		var s = JSON.stringify(j, null, 2);\
		require("fs").writeFileSync("./package.json", s);'
	git commit package.json -m 'Version $(NEXT_VERSION)'
	git tag -a "v$(NEXT_VERSION)" -m "Version $(NEXT_VERSION)"
	git push --tags origin HEAD:master
	npm publish

test:
	$(MOCHA) "$(TESTDIR)"/*.coffee
$(TESTDIR)/%.coffee: phony-dep
	$(MOCHA) "$@"

loc:
	@wc -l src/*

clean:
	@rm -rf lib
