#!/usr/bin/env Rscript

# The code is based on the following script:
# https://github.com/dgrtwo/dgrtwo.github.com/blob/master/_scripts/knitpages.R

require(knitr)

process_file <- function(input, output, image_path, cache_path) {
  opts_knit$set(
    base.url = '/'
  )
  opts_chunk$set(
    dev = 'svg',
    echo = FALSE,
    message = FALSE,
    fig.align = 'center',
    fig.asp = 0.618,
    fig.cap = '',
    fig.width = 8,
    fig.path = paste0(image_path, '/', sub('.Rmd$', '', basename(input)), '/'),
    cache.path = file.path(cache_path, '/', sub('.Rmd$', '', basename(input)), '/')
  )
  render_jekyll()
  knit(input, output, envir = parent.frame())
}

process_folder <- function(input_path, output_path, image_path, cache_path) {
  for (input in list.files(input_path, pattern = '*.Rmd', full.names = TRUE)) {
    output = paste0(output_path, '/', sub('.Rmd$', '.md', basename(input)))
    if (!file.exists(output) | file.info(input)$mtime > file.info(output)$mtime) {
      process_file(input, output, image_path, cache_path)
    }
  }
}

process_folder(input_path = '_drafts',
               output_path = '_drafts',
               image_path = 'assets/images',
               cache_path = '_caches')

process_folder(input_path = '_posts',
               output_path = '_posts',
               image_path = 'assets/images',
               cache_path = '_caches')
