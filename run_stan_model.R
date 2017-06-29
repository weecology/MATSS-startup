library(rstan)

tmax <- 30
y <- rpois(tmax,20)

stan_model(file='model.stan')
