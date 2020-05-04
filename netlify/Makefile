.PHONY: build clean build-elm build-tracing

node_bin = node_modules/.bin

build : $(node_bin)/elm build-elm build-tracing

build-elm :
	$(node_bin)/elm make Main.elm --output=site/elm.js

clean :
	rm -rf site/elm.js node_modules elm-stuff

$(node_bin)/elm :
	npm install

build-tracing:
	$(node_bin)/webpack --config webpack.config.js
