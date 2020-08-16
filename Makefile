.PHONY : apply
apply :
	terraform apply -auto-approve

distId := $(shell terraform output cfdist)

.PHONY : deploy
deploy : apply build
	@echo ${distId}
	aws s3 sync build s3://darrineden.com/ --delete --acl public-read
	AWS_PAGER="" aws cloudfront create-invalidation --distribution-id ${distId} --paths "/*"

.PHONY : test
test : dev
	npm test

.PHONY : build
build : dev
	npm run build

.PHONY : clean
clean :
	rm -rf build node_modules .terraform

node_bin = node_modules/.bin

$(node_bin)/react-scripts :
	npm install

.terraform :
	terraform init

.PHONY : dev
dev : $(node_bin)/react-scripts .terraform
