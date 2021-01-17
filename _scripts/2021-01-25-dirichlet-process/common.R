geom_reference <- function(data, type = 'cdf', binwidth = 1) {
  if (type == 'cdf') {
    stat_ecdf(data = data,
              mapping = aes(x, color = 'Observation'),
              size = 1)
  } else if (type == 'pdf') {
    geom_histogram(data = data,
                   mapping = aes(x,
                                 y = ..count.. / sum(..count..),
                                 color = 'Observation'),
                   binwidth = binwidth,
                   fill = 'gray70')
  } else if (type == 'histogram') {
    geom_histogram(data = data,
                   mapping = aes(x, color = 'Observation'),
                   binwidth = binwidth,
                   fill = 'gray70')
  }
}

scale_color <- function() {
  scale_color_manual(breaks = c('Observation', 'Model'),
                     values = c('Observation' = 'gray70',
                                'Model' = 'gray30'))
}
