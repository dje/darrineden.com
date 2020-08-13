.PHONY : test
test : dev
	npm test

.PHONY : build
build : dev
	npm run build

.PHONY : clean
clean :
	rm -rf build node_modules

node_bin = node_modules/.bin

$(node_bin)/react-scripts :
	npm install

.PHONY : dev
dev : $(node_bin)/react-scripts
