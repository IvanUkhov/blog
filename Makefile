all: serve

build:
	JEKYLL_ENV=production bundle exec jekyll build
	cp CNAME _site

compile:
	inotifywait -e close_write,moved_to,create -m _drafts | \
	while read -r directory events filename; do \
		./_scripts/compile.R; \
	done

serve:
	bundle exec jekyll serve --drafts

.PHONY: all build compile serve
