default: build

CHANGELOG=CHANGELOG

SRC = $(shell find src -name "*.coffee" -type f | sort)
LIB = $(SRC:src/%.coffee=lib/%.js)

COFFEE=node_modules/.bin/coffee --js
MOCHA=node_modules/.bin/mocha --compilers coffee:coffee-script-redux/register -r coffee-script-redux/register -r test-setup.coffee -u tdd

all: build test
build: $(LIB)

lib/%.js: src/%.coffee
	@dirname "$@" | xargs mkdir -p
	$(COFFEE) <"$<" >"$@"

.PHONY: all build release release-patch release-minor release-major test loc clean

VERSION = $(shell node -p 'require("./package.json").version')
release-patch: NEXT_VERSION = $(shell node -p 'require("semver").inc("$(VERSION)", "patch")')
release-minor: NEXT_VERSION = $(shell node -p 'require("semver").inc("$(VERSION)", "minor")')
release-major: NEXT_VERSION = $(shell node -p 'require("semver").inc("$(VERSION)", "major")')
release-patch: release
release-minor: release
release-major: release

release: build test
	@printf "Current version is $(VERSION). This will publish version $(NEXT_VERSION). Press [enter] to continue." >&2
	@read
	./changelog.sh "v$(NEXT_VERSION)" >"$(CHANGELOG)"
	node -e '\
		var j = require("./package.json");\
		j.version = "$(NEXT_VERSION)";\
		var s = JSON.stringify(j, null, 2) + "\n";\
		require("fs").writeFileSync("./package.json", s);'
	git commit package.json "$(CHANGELOG)" -m 'Version $(NEXT_VERSION)'
	git tag -a "v$(NEXT_VERSION)" -m "Version $(NEXT_VERSION)"
	git push --tags origin HEAD:master
	npm publish

test:
	$(MOCHA) -R dot test/*.coffee

loc:
	@wc -l src/*
clean:
	@rm -rf lib
