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

prior_noise <- function(x, alpha_noise, beta_noise) {
  m <- nrow(x);
  sigma_noise <- sqrt(exp(alpha_noise + x %*% beta_noise));
  rnorm(m, sd = sigma_noise)
}

prior_noise_plot <- function(n = 5, x = seq(0, 1, by = 0.01),
                             alpha = list(mean = -1), beta = list()) {
  map <- function(...) {
    tibble(x = x, y = prior_noise(as.matrix(x), ...))
  }
  tibble(.draw = factor(seq(1, n)),
         alpha_noise = do.call(rnorm, c(list(n = n), alpha)),
         beta_noise = do.call(rnorm, c(list(n = n), beta))) %>%
    transmute(.draw = .draw,
              curve = pmap(list(alpha_noise = alpha_noise,
                                beta_noise = beta_noise),
                           map)) %>%
    unnest(curve) %>%
    ggplot(aes(x, y, color = .draw)) +
    geom_line(size = 0.75, alpha = 0.5) +
    labs(x = 'Distance', y = 'Noise') +
    theme(legend.position = 'none')
}

prior_noise_sigma_plot <- function(n = 100000, alpha = list(mean = -1)) {
  tibble(alpha_noise = do.call(rnorm, c(list(n = n), alpha))) %>%
    mutate(sigma_noise = sqrt(exp(alpha_noise))) %>%
    ggplot(aes(sigma_noise)) +
    geom_density() +
    scale_x_log10() +
    labs(x = 'Noise standard deviation', y = 'Prior density')
}

prior_process <- function(x, jitter = 1e-6, ...) {
  m <- nrow(x);
  U <- chol(covariance(x, x, ...) + diag(jitter, m));
  as.vector(rnorm(m) %*% U)
}

prior_process_plot <- function(n = 10, x = seq(0, 1, by = 0.01),
                       sigma_process = 1, ell_process = 1) {
  map <- function(...) {
    tibble(x = x, y = prior_process(as.matrix(x), ...))
  }
  tibble(.draw = factor(seq(1, n)),
         sigma_process = sigma_process,
         ell_process = ell_process) %>%
    transmute(.draw = .draw,
              curve = pmap(list(sigma_process = sigma_process,
                                ell_process = ell_process),
                           map)) %>%
    unnest(curve) %>%
    ggplot(aes(x, y, group = .draw)) +
    geom_line(size = 0.75) +
    labs(x = 'Distance', y = 'Response') +
    theme(legend.position = 'none')
}

prior_process_length_scale_plot <- function(x = seq(0.01, 5, by = 0.01),
                                            alpha = 1, beta = 1) {
  tibble(x = x) %>%
    mutate(y = dinvgamma(x, alpha, beta)) %>%
    ggplot(aes(x, y)) +
    geom_line() +
    labs(x = 'Length scale', y = 'Prior density')
}

posterior_parameter_plot <- function(model) {
  model %>%
    spread_draws(sigma_process,
                 ell_process,
                 alpha_noise,
                 beta_noise[dimension]) %>%
    ungroup() %>%
    select(-dimension) %>%
    pivot_longer(sigma_process:beta_noise) %>%
    mutate(name = factor(name, levels = c('beta_noise',
                                          'alpha_noise',
                                          'ell_process',
                                          'sigma_process')),
           name = fct_rev(name)) %>%
    ggplot(aes(value)) +
    stat_halfeye(normalize = 'panels', fill = 'grey90') +
    facet_wrap(~ name, scales = 'free') +
    theme(axis.title.x = element_blank(),
          axis.text.y = element_blank(),
          axis.title.y = element_blank(),
          legend.position = 'none')
}

posterior_predictive_noise <- function(x_new, alpha_noise, beta_noise) {
  n <- nrow(x_new);
  sigma_noise <- sqrt(exp(alpha_noise + x_new %*% beta_noise));
  rnorm(n, sd = sigma_noise)
}

posterior_predictive_noise_plot <- function(model, x_new) {
  map <- function(...) {
    tibble(x = x_new, y = posterior_predictive_noise(as.matrix(x_new), ...))
  }
  model %>%
    spread_draws(alpha_noise, beta_noise[.]) %>%
    transmute(curve = pmap(list(alpha_noise = alpha_noise,
                                beta_noise = beta_noise),
                           map)) %>%
    unnest(curve) %>%
    group_by(x) %>%
    mean_qi() %>%
    ggplot(aes(x, y)) +
    geom_ribbon(aes(ymin = .lower, ymax = .upper), fill = 'grey90') +
    geom_line() +
    labs(x = 'Distance', y = 'Noise')
}

posterior_predictive <- function(x_new, x, y, alpha_noise, beta_noise, ...) {
  m <- nrow(x);
  n <- nrow(x_new);
  K_11 <- covariance(x, x, ...);
  K_21 <- covariance(x_new, x, ...);
  K_22 <- covariance(x_new, x_new, ...);
  L <- t(chol(K_11 + diag(as.vector(exp(alpha_noise + x %*% beta_noise)))));
  L_inv <- forwardsolve(L, diag(m));
  K_inv <- t(L_inv) %*% L_inv;
  mu_new <- K_21 %*% K_inv %*% y;
  L_new <- t(chol(K_22 - K_21 %*% K_inv %*% t(K_21) +
                  diag(as.vector(exp(alpha_noise + x_new %*% beta_noise)))));
  as.vector(mu_new + L_new %*% rnorm(n))
}

posterior_predictive_plot <- function(model, x_new, x, y, ...) {
  map <- function(...) {
    tibble(x = x_new,
           y = posterior_predictive(as.matrix(x_new), as.matrix(x), y, ...))
  }
  model %>%
    spread_draws(alpha_noise, beta_noise[.], sigma_process, ell_process) %>%
    transmute(curve = pmap(list(alpha_noise = alpha_noise,
                                beta_noise = beta_noise,
                                sigma_process = sigma_process,
                                ell_process = ell_process),
                           map)) %>%
    unnest(curve) %>%
    group_by(x) %>%
    mean_qi() %>%
    ggplot(aes(x, y)) +
    geom_line() +
    geom_point(data = data, size = 1) +
    geom_ribbon(aes(ymin = .lower, ymax = .upper), alpha = 0.1)
}
