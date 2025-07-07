# Direct prior

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

# Mixing prior

sample_Ptheta_prior <- function(l, mu0 = 0, kappa0 = 1, nu0 = 3, sigma0 = 1) {
  sigma <- sqrt((nu0 * sigma0^2) / rchisq(l, nu0))
  mu <- rnorm(l, mu0, sigma / sqrt(kappa0))
  tibble(mu = mu, sigma = sigma)
}

sample_Ptheta_posterior <- function(l, x, mu0 = mean(x), kappa0 = 1, nu0 = 3, sigma0 = sd(x)) {
  n <- length(x)
  if (n == 0) {
    mu <- 0
    ss <- 0
  } else {
    mu <- mean(x)
    ss <- sum((x - mu)^2)
  }
  sample_Ptheta_prior(
    l = l,
    mu0 = kappa0 / (kappa0 + n) * mu0 + n / (kappa0 + n) * mu,
    kappa0 = kappa0 + n,
    nu0 = nu0 + n,
    sigma0 = sqrt((nu0 * sigma0^2 + ss + kappa0 * n / (kappa0 + n) * (mu - mu0)^2) / (nu0 + n))
  )
}

sample_Plambda_prior <- function(l, alpha0 = 2, beta0 = 0.1) {
  rgamma(l, alpha0, beta0)
}

sample_Plambda_posterior <- function(l, q, alpha0 = 2, beta0 = 0.1) {
  sample_Plambda_prior(
    l = l,
    alpha0 = alpha0 + length(q) - 1,
    beta0 = beta0 - sum(log(head(1 - q, -1)))
  )
}

evaluate_Px <- function(x, theta) {
  dnorm(x, theta$mu, sqrt(theta$sigma))
}

evaluate_Pm_ <- function(draw, grid, type = 'cdf') {
  if (type == 'cdf') {
    method <- pnorm
  } else if (type == 'pdf') {
    method <- dnorm
  }
  bind_cols(draw$theta, tibble(p = draw$stick$p)) %>%
    mutate(.component = row_number()) %>%
    select(.component, everything()) %>%
    mutate(data = map2(mu, sigma, function(mu, sigma) {
                                    tibble(x = grid,
                                           y = method(grid, mu, sigma))
                                  })) %>%
    unnest(data) %>%
    group_by(x) %>%
    summarize(y = sum(p * y), .groups = 'drop')
}

evaluate_Pm <- function(draws, grid, ...) {
  process <- function(i) {
    evaluate_Pm_(draws[[i]], grid, ...) %>%
      mutate(.draw = i) %>%
      select(.draw, everything())
  }
  sapply(1:length(draws), process, simplify = FALSE) %>%
    bind_rows()
}

evaluate_DPM <- function(draws, observed, size = 1000, ...) {
  grid <- seq(min(observed$x) - 5, to = max(observed$x) + 5, length.out = size)
  evaluate_Pm(draws, grid, ...)
}

sample_DPM <- function(x, m, l,
                       n0 = 3,
                       mu0 = mean(x),
                       kappa0 = n0,
                       nu0 = n0,
                       sigma0 = 1,
                       lambda0 = 1,
                       alpha0 = 2,
                       beta0 = 0.1,
                       prior_only = FALSE) {
  theta_prior <- list(
    mu0 = mu0,
    kappa0 = kappa0,
    nu0 = nu0,
    sigma0 = sigma0
  )
  lambda_prior <- list(
    alpha0 = alpha0,
    beta0 = beta0
  )
  state <- list(
    k = sample(1:m, length(x), replace = TRUE),
    stick = stick_break(m, 1, lambda0),
    theta = do.call(sample_Ptheta_prior, c(list(m), theta_prior)),
    lambda = lambda0
  )
  draws <- vector('list', l)
  for(i in 1:l) {
    arguments <- list(x, state, prior_only = prior_only)
    state$k <- do.call(update_k, arguments)
    arguments <- list(x, state, prior_only = prior_only)
    state$stick <- do.call(update_stick, arguments)
    arguments <- c(list(x, state, prior_only = prior_only), theta_prior)
    state$theta <- do.call(update_theta, arguments)
    arguments <- c(list(x, state, prior_only = prior_only), lambda_prior)
    state$lambda <- do.call(update_lambda, arguments)
    draws[[i]] <- state
  }
  draws
}

update_k <- function(x, state, prior_only = FALSE) {
  m <- length(state$stick$p)
  n <- length(x)
  if (prior_only) {
    p <- matrix(rep(1 / m, m * n), nrow = m, ncol = n)
  } else {
    x <- rep(x, each = m)
    theta <- state$theta %>% slice(rep(1:m, n))
    p <- matrix(evaluate_Px(x, theta), nrow = m, ncol = n)
    p <- sweep(p, 1, state$stick$p, `*`)
    p <- sweep(p, 2, colSums(p), `/`)
  }
  apply(p, 2, function(p) sample(1:m, 1, prob = p))
}

update_stick <- function(x, state, prior_only = FALSE) {
  m <- length(state$stick$p)
  if (prior_only) {
    alpha <- 1
    beta <- state$lambda
  } else {
    n <- count_subjects(m, state$k)
    alpha <- 1 + n
    beta <- state$lambda + sum(n) - cumsum(n)
  }
  stick_break(m, alpha, beta)
}

update_theta <- function(x, state, prior_only = FALSE, ...) {
  m <- length(state$stick$p)
  if (prior_only) {
    sapply(1:m, function(i) sample_Ptheta_prior(1, ...), simplify = FALSE) %>%
      bind_rows()
  } else {
    sapply(1:m, function(i) sample_Ptheta_posterior(1, x[state$k == i], ...),
           simplify = FALSE) %>%
      bind_rows()
  }
}

update_lambda <- function(x, state, prior_only = FALSE, ...) {
  if (prior_only) {
    sample_Plambda_prior(1, ...)
  } else {
    sample_Plambda_posterior(1, state$stick$q, ...)
  }
}

check_predictive <- function(draws, observed, type = 'pdf', ...) {
  ggplot() +
    geom_observation(observed, type = type, ...) +
    geom_line(data = evaluate_DPM(draws, observed, type = type),
              mapping = aes(x, y, color = 'Model', group = .draw),
              size = 1) +
    scale_color() +
    labs(x = TeX('Velocity ($10^6$ m/s)'),
         y = 'Probability density') +
    theme(legend.position = 'none')
}

summarize_inference <- function(draws, observed, type = 'pdf', probability = 0.95, ...) {
  evaluate_DPM(draws, observed, type = type) %>%
    group_by(x) %>%
    summarize(y_middle = median(y),
              y_lower = quantile(y, (1 - probability) / 2),
              y_upper = quantile(y, 1 - (1 - probability) / 2),
              .groups = 'drop')
}

# Auxiliary

stick_break <- function(l, alpha, beta) {
  q <- rbeta(l, shape1 = alpha, shape2 = beta)
  q <- c(head(q, -1), 1)
  list(p = q * c(1, cumprod(1 - head(q, -1))), q = q)
}

count_subjects <- function(m, k) {
  n <- rep(0, m)
  k <- as.data.frame(table(k))
  n[as.numeric(levels(k[ , 1]))[k[ , 1]]] <- k[ , 2]
  n
}

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

plot_distribution <- function(draws, observed) {
  draws <- draws %>%
    arrange(x) %>%
    mutate(p = cumsum(p))
  ggplot() +
    geom_observation(observed) +
    geom_line(data = draws,
              mapping = aes(x, p, color = 'Model'),
              size = 1) +
    scale_color() +
    labs(x = TeX('Velocity ($10^6$ m/s)'),
         y = 'Cumulative probability') +
    theme(legend.title = element_blank(),
          legend.position = 'top')
}

plot_inference <- function(draws_summarized, observed, type = 'pdf', probability = 0.95, ...) {
  ggplot() +
    geom_observation(observed, type = type, ...) +
    geom_line(data = draws_summarized,
              mapping = aes(x, y_lower, color = 'Model'),
              linetype = 'dashed',
              size = 0.5) +
    geom_line(data = draws_summarized,
              mapping = aes(x, y_upper, color = 'Model'),
              linetype = 'dashed',
              size = 0.5) +
    geom_line(data = draws_summarized,
              mapping = aes(x, y_middle, color = 'Model'),
              size = 1) +
    scale_color() +
    labs(x = TeX('Velocity ($10^6$ m/s)'),
         y = 'Probability density') +
    theme(legend.position = 'none')
}
