.PHONY: build clean build-elm build-functions

build : node_modules/.bin/elm build-elm build-functions

build-elm :
	./node_modules/.bin/elm make Main.elm --output=site/elm.js

build-functions :
	mkdir -p functions
	go build -o functions/delete-tweets ./...

clean :
	rm -rf site/elm.js functions node_modules elm-stuff

node_modules/.bin/elm :
	npm install
