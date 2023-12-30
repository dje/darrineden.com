.PHONY : apply
apply :
	terraform apply -auto-approve

.PHONY : deploy
deploy : apply build
	@echo ${CF_DIST_ID}
	aws s3 sync build s3://darrineden.com/ --delete --acl public-read
	AWS_PAGER="" aws cloudfront create-invalidation --distribution-id ${CF_DIST_ID} --paths "/*"

.PHONY : clean
clean :
	rm -rf .terraform

.terraform :
	terraform init
