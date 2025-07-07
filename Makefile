.PHONY: all
all: serve

.PHONY: build
build:
	JEKYLL_ENV=production bundle exec jekyll build
	cp CNAME _site

.PHONY: compile
compile:
	fswatch -o _drafts | xargs -n1 -I{} ./_scripts/compile.R

.PHONY: serve
serve:
	bundle exec jekyll serve --drafts
