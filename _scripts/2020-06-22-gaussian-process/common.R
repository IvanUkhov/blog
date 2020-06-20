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

prior_length_scale_plot <- function(x = seq(0.01, 5, by = 0.01),
                                    alpha = 1, beta = 1) {
  tibble(x = x) %>%
    mutate(y = dinvgamma(x, alpha, beta)) %>%
    ggplot(aes(x, y)) +
    geom_line() +
    labs(x = 'Length scale', y = 'Prior density')
}

prior_noise <- function(x, alpha_noise, beta_noise) {
  m <- nrow(x);
  sigma_noise <- sqrt(exp(alpha_noise + x %*% beta_noise));
  rnorm(m, sd = sigma_noise)
}

prior_noise_map <- function(x, ...) {
  tibble(x = x, y = prior_noise(as.matrix(x), ...))
}

prior_noise_plot <- function(n = 5, x = seq(0, 1, by = 0.01),
                             alpha = list(mu = 0, sigma = 1, nu = 3),
                             beta = list(mean = 0, sd = 1)) {
  tibble(.draw = factor(seq(1, n)),
         x = list(x),
         alpha_noise = do.call(rst, c(list(n = n), alpha)),
         beta_noise = do.call(rnorm, c(list(n = n), beta))) %>%
    transmute(.draw = .draw,
              curve = pmap(list(x = x,
                                alpha_noise = alpha_noise,
                                beta_noise = beta_noise),
                           prior_noise_map)) %>%
    unnest(curve) %>%
    ggplot(aes(x, y, color = .draw)) +
    geom_line(size = 0.75, alpha = 0.5) +
    labs(x = 'Distance', y = 'Noise') +
    theme(legend.position = 'none')
}

prior_process <- function(x, jitter = 1e-6, ...) {
  m <- nrow(x);
  U <- chol(covariance(x, x, ...) + diag(jitter, m));
  as.vector(rnorm(m) %*% U)
}

prior_process_map <- function(x, ...) {
  tibble(x = x, y = prior_process(as.matrix(x), ...))
}

prior_process_plot <- function(n = 10, x = seq(0, 1, by = 0.01),
                       sigma_process = 1, ell_process = 1) {
  tibble(.draw = factor(seq(1, n)),
         x = list(x),
         sigma_process = sigma_process,
         ell_process = ell_process) %>%
    transmute(.draw = .draw,
              curve = pmap(list(x = x,
                                sigma_process = sigma_process,
                                ell_process = ell_process),
                           prior_process_map)) %>%
    unnest(curve) %>%
    ggplot(aes(x, y, group = .draw)) +
    geom_line(size = 0.75) +
    labs(x = 'Distance', y = 'Response') +
    theme(legend.position = 'none')
}
