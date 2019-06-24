all: serve

build:
	JEKYLL_ENV=production bundle exec jekyll build
	cp CNAME _site

serve:
	bundle exec jekyll serve --drafts

.PHONY: all build serve
