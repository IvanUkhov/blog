.PHONY: all
all: serve

.PHONY: build
build:
	JEKYLL_ENV=production bundle exec jekyll build
	cp CNAME _site

.PHONY: compile
compile:
	inotifywait -e close_write,moved_to,create -m _drafts | \
	while read -r directory events filename; do \
		./_scripts/compile.R; \
	done

.PHONY: serve
serve:
	bundle exec jekyll serve --drafts
