#!/usr/bin/env python3
import numpy as np
from matplotlib import pyplot as pp
pdm_data =  np.random.rand(16000)
pdm_data = pdm_data
for _ in range(99):
    pdm_data += (np.sin(np.pi * np.linspace(0, np.random.rand() * 16000, 16000) + np.random.rand() * np.pi * 2)+1.0) / 2
pdm_data = np.round(pdm_data/100)

in_data = [] # np.random.rand(1000)
accum = 0.0
for idx, i in enumerate((pdm_data - 0.5) * 2):
    accum = (i + accum * 15) / 16
    if idx % 16 == 0:
        in_data.append(accum)

fft = np.fft.rfft(in_data)

pdm_fft = []
for i in range(500):
    wd =  int(8 * (500-i))
    k = int(np.floor(len(pdm_data) / wd))

    r = np.reshape(pdm_data[:k*wd], (k, wd))
    loop = np.round(np.mean(r,0))
    delta = np.sum(loop[:int(wd/2)]) - np.sum(loop[int(wd/2):])
    pdm_fft.append(delta)
n_plot = 4
pp.subplot(n_plot,1,3)
pp.plot(pdm_data, linewidth=0.05)
pp.title("pdm")
pp.subplot(n_plot,1,1)
pp.plot(np.absolute(fft))
pp.title("fft")
pp.subplot(n_plot,1,2)
pp.plot(in_data)
pp.title("data")
pp.subplot(n_plot,1,4)
pp.plot(pdm_fft)
pp.title("pdm_fft")
pp.show()
