covariance <- function(x, x_prime, sigma_process, ell_process) {
  sigma_process^2 * exp(-distance(x, x_prime)^2 / ell_process^2 / 2)
}

distance <- function(x, x_prime) {
  m <- nrow(x);
  n <- nrow(x_prime);
  x_x_prime <- x %*% t(x_prime);
  x_2 <- matrix(rep(apply(x * x, 1, sum), n), m, n, byrow = FALSE);
  x_prime_2 <- matrix(rep(apply(x_prime * x_prime, 1, sum), m), m, n, byrow = TRUE);
  sqrt(pmax(x_2 + x_prime_2 - 2 * x_x_prime, 0))
}

process_prior <- function(x, jitter = 1e-6, ...) {
  m <- nrow(x);
  U <- chol(covariance(x, x, ...) + diag(jitter, m));
  as.vector(rnorm(m) %*% U)
}

process_prior_map <- function(x, ...) {
  tibble(x = x, y = process_prior(as.matrix(x), ...))
}

process_prior_plot <- function(n = 10, x = seq(0, 1, by = 0.01),
                       sigma_process = 1, ell_process = 1) {
  tibble(.draw = factor(seq(1, n)),
         x = list(x),
         sigma_process = sigma_process,
         ell_process = ell_process) %>%
    transmute(.draw = .draw,
              curve = pmap(list(x = x,
                                sigma_process = sigma_process,
                                ell_process = ell_process),
                           process_prior_map)) %>%
    unnest(curve) %>%
    ggplot(aes(x, y, group = .draw)) +
    geom_line(size = 0.75) +
    labs(x = 'Distance', y = 'Response') +
    theme(legend.position = 'none')
}

noise_prior <- function(x, alpha_noise, beta_noise) {
  m <- nrow(x);
  sigma_noise <- as.vector(exp(alpha_noise + x %*% beta_noise));
  sigma_noise * rnorm(m)
}

noise_prior_map <- function(x, ...) {
  tibble(x = x, y = noise_prior(as.matrix(x), ...))
}

noise_prior_plot <- function(n = 10, x = seq(0, 1, by = 0.01), sigma = 1) {
  tibble(.draw = factor(seq(1, n)),
         x = list(x),
         alpha_noise = rnorm(n, sd = sigma),
         beta_noise = rnorm(n, sd = sigma)) %>%
    transmute(.draw = .draw,
              curve = pmap(list(x = x,
                                alpha_noise = alpha_noise,
                                beta_noise = beta_noise),
                           noise_prior_map)) %>%
    unnest(curve) %>%
    ggplot(aes(x, y, group = .draw)) +
    geom_line(size = 0.75, alpha = 0.2) +
    labs(x = 'Distance', y = 'Noise') +
    theme(legend.position = 'none')
}
