BIN = node_modules/.bin
SRCDIR = .
LIBDIR = .
SRC = $(shell find $(SRCDIR) -name '*.coffee' -type f)
LIB = $(SRC:$(SRCDIR)/%.coffee=$(LIBDIR)/%.js)

all: build

build: $(LIB)

test:
	@$(BIN)/mocha --compilers coffee:coffee-script -C spec/

deps:
	@npm install

clean:
	rm -f $(LIB)

$(LIBDIR)/%.js: $(SRCDIR)/%.coffee
	mkdir -p $(@D)
	$(BIN)/coffee -cp $< > $@

release-patch: build test
	@$(call release,patch)

release-minor: build test
	@$(call release,minor)

release-major: build test
	@$(call release,major)

define release
	VERSION=`node -pe "require('./package.json').version"` && \
	NEXT_VERSION=`node -pe "require('semver').inc(\"$$VERSION\", '$(1)')"` && \
  node -e "\
  	var j = require('./package.json');\
  	j.version = \"$$NEXT_VERSION\";\
  	var s = JSON.stringify(j, null, 2);\
  	require('fs').writeFileSync('./package.json', s);" && \
  git commit -m "release $$NEXT_VERSION" -- package.json && \
  git tag "$$NEXT_VERSION" -m "release $$NEXT_VERSION" && \
  git push --tags origin HEAD:master && \
  npm publish
endef
