data {
  int tmax;
  int y;
}
parameters {
  real<lower=0> sigma;
  vector[tmax] noise;
}
transformed parameters {
  vector[tmax] log_m;
  for (n in 2:tmax) {
    log_m[n] = log_m[n-1] + noise[n];
  }
}
model {
  sigma ~ normal(1, 1);
  noise ~ normal(0, sigma);
  y ~ poisson(exp(log_m));
}
