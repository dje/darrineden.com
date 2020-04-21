.PHONY: build clean build-elm

build : node_modules/.bin/elm build-elm

build-elm :
	./node_modules/.bin/elm make Main.elm --output=site/elm.js

clean :
	rm -rf site/elm.js node_modules elm-stuff

node_modules/.bin/elm :
	npm install
