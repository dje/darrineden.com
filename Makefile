build : build-elm build-functions

build-elm :
	elm make Main.elm --output=site/elm.js

build-functions :
	mkdir -p functions
	go build -o functions/delete-tweets ./...

clean :
	rm -r site/elm.js functions