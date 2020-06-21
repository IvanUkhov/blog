data {
  int<lower = 1> d;
  int<lower = 1> m;
  vector[d] x[m];
  vector[m] y;
}

transformed data {
  vector[m] mu = rep_vector(0, m);
  matrix[m, d] X;
  for (i in 1:m) {
    X[i] = x[i]';
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
  vector[m] sigma_noise_squared = exp(alpha_noise + X * beta_noise);
  matrix[m, m] L = cholesky_decompose(add_diag(K, sigma_noise_squared));

  y ~ multi_normal_cholesky(mu, L);
  alpha_noise ~ normal(-1, 1);
  beta_noise ~ normal(0, 1);
  sigma_process ~ normal(0, 1);
  ell_process ~ inv_gamma(1, 1);
}
