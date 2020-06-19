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

prior <- function(x, jitter = 1e-6, ...) {
  m <- nrow(x);
  U <- chol(covariance(x, x, ...) + diag(jitter, m));
  as.vector(rnorm(m) %*% U)
}

prior_map <- function(x, ...) {
  tibble(x = x, y = prior(as.matrix(x), ...))
}

prior_plot <- function(n = 10, x = seq(0, 1, by = 0.01),
                       sigma_process = 1, ell_process = 1) {
  tibble(.draw = factor(seq(1, n)),
         x = list(x),
         sigma_process = sigma_process,
         ell_process = ell_process) %>%
    transmute(.draw = .draw,
              curve = pmap(list(x = x,
                                sigma_process = sigma_process,
                                ell_process = ell_process),
                           prior_map)) %>%
    unnest(curve) %>%
    ggplot(aes(x, y, color = .draw)) +
    geom_line(size = 1) +
    labs(x = 'Distance', y = 'Response') +
    theme(legend.position = 'none')
}
