import numpy as np

def sample_correlation(x1, x2):
  nens = x1.size
  x1_mean = np.mean(x1)
  x2_mean = np.mean(x2)
  x1p = x1 - x1_mean
  x2p = x2 - x2_mean
  cov = np.sum(x1p * x2p)
  x1_norm = np.sum(x1p ** 2)
  x2_norm = np.sum(x2p ** 2)
  if(x1_norm == 0. or x2_norm == 0):
    corr = 0.
  else:
    corr = cov/np.sqrt(x1_norm * x2_norm)
  return corr
