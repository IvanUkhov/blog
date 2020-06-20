data {
  int<lower = 1> d;
  int<lower = 1> m;

  vector[d] x[m];
  vector[m] y;
}

transformed data {
  vector[m] mu = rep_vector(0, m);
  matrix[m, d] x_;
  for (i in 1:m) {
    x_[i] = x[i]';
  }
}

parameters {
  real alpha_noise;
  vector[d] beta_noise;
  real<lower = 0> sigma_process;
  real<lower = 0> ell_process;
}

model {
  matrix[m, m] K = cov_exp_quad(x, sigma_process, ell_process);
  matrix[m, m] L = cholesky_decompose(add_diag(K, exp(alpha_noise + x_ * beta_noise)));

  y ~ multi_normal_cholesky(mu, L);
  alpha_noise ~ normal(0, 1);
  beta_noise ~ normal(0, 1);
  sigma_process ~ normal(0, 1);
  ell_process ~ inv_gamma(5, 5);
}
