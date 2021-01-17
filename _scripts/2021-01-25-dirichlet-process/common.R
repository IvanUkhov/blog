geom_observation <- function(data, type = 'cdf', binwidth = 1) {
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

stick_break <- function(l, alpha, beta) {
  q <- rbeta(l, shape1 = alpha, shape2 = beta)
  q <- c(head(q, -1), 1)
  list(p = q * c(1, cumprod(1 - head(q, -1))), q = q)
}

nu_prior <- function(lambda = 1, mu0 = 0, sigma0 = 1) {
  sample_P0 <- function(l) rnorm(l, mean = mu0, sd = sigma0)
  list(sample_P0 = sample_P0, lambda = lambda)
}

nu_posterior <- function(x, lambda = 1, mu0 = 0, sigma0 = 1) {
  prior <- nu_prior(lambda = lambda, mu0 = mu0, sigma0 = sigma0)
  sample_P0 <- function(l) {
    i <- rbernoulli(l, p = lambda / (lambda + length(x)))
    i * prior$sample_P0(l) + (1 - i) * sample(x, l, replace = TRUE)
  }
  list(sample_P0 = sample_P0, lambda = lambda + length(x))
}

sample_DP <- function(l, nu) {
  x <- nu$sample_P0(l)
  p <- stick_break(l, 1, nu$lambda)$p
  tibble(x = x, p = p)
}

plot_distribution <- function(sampled, observed) {
  sampled <- sampled %>%
    arrange(x) %>%
    mutate(p = cumsum(p))
  ggplot() +
    geom_observation(observed) +
    geom_line(data = sampled,
              mapping = aes(x, p, color = 'Model'),
              size = 1) +
    scale_color() +
    labs(x = 'Velocity (1000 km/s)',
         y = 'Probability') +
    theme(legend.title = element_blank(),
          legend.position = 'top')
}
