#!/usr/bin/env python3
import numpy as np
from matplotlib import pyplot as pp

def rawToPdm(raw_data):
    pdm_data = []
    err = 0.0
    for i in raw_data:
        err += i
        v = 1 if err > 0 else -1
        err -= v
        pdm_data.append(v)
    pdm_data = np.array(pdm_data)/2 + 0.5
    return pdm_data

def pdmToRaw(pdm_data):
    in_data = []
    accum = 0.0
    for idx, i in enumerate((pdm_data - 0.5) * 2):
        accum = (i + accum * 31) / 32
        if idx % 16 == 0:
            in_data.append(accum)
    return in_data

def pdmSum(pdm_0, pdm_1, init_err=0.0):
    pdm_sum = []
    err = init_err
    for i_0, i_1 in list(zip(pdm_0 - 0.5, pdm_1 - 0.5)):
        err += i_0 + i_1
        v = 0.5 if err > 0 else -0.5
        err -= v
        pdm_sum.append(v)
    return np.array(pdm_sum) + 0.5, err

def pdmMult(pdm_0, pdm_1, init_err=0.0):
    pdm_sum = []
    err = init_err
    acc_0 = [0]*10
    acc_1 = [0]*10
    for i_0, i_1 in list(zip(pdm_0 - 0.5, pdm_1 - 0.5)):
        acc_0.append(i_0 * 2)
        acc_1.append(i_1 * 2)
        acc_0 = acc_0[1:]
        acc_1 = acc_1[1:]
        nxt = 0
        if i_0 > 0:
            nxt += np.sum(acc_1)
        else:
            nxt -= np.sum(acc_1)
        if i_1 > 0:
            nxt += np.sum(acc_0)
        else:
            nxt -= np.sum(acc_0)
        nxt /= (4 * len(acc_1))
        err += nxt
        v = 0.5 if err > 0 else -0.5
        err -= v
        pdm_sum.append(v)
    return np.array(pdm_sum) + 0.5, err

def pdmft(pdm):
    pdm_fft = []
    for i in range(int(len(pdm)/2)):
        wd = (i + 1)
        k = int(np.floor(len(pdm_data) / wd))
        s = np.sin(np.linspace(0, np.pi * 2, wd))
        c = np.cos(np.linspace(0, np.pi * 2, wd))
        r = np.reshape(pdm_data[:k*wd], (k, wd)) - 0.5
        sr = np.sum(r, 0)
        delta = np.hypot(np.mean(sr * s), np.mean(sr * c))
        pdm_fft.append(delta)

    return pdm_fft

def genRndBits(l=16000):
    shift_reg_bits = [False] * 24
    data = []
    for i in range(l):
        nxt_bit = (shift_reg_bits[23]
                   ^ shift_reg_bits[22]
                   ^ shift_reg_bits[21]
                   ^ shift_reg_bits[17]
                   ^ True)
        shift_reg_bits.insert(0, nxt_bit)
        data.append(shift_reg_bits.pop(24))
    return np.array(data)


raw_data = 0.5 * np.sin(np.pi * np.linspace(0, 10, 16000))
raw_data_2 = 0.3 * np.sin(np.pi * np.linspace(0, 31, 16000))
raw_sum = raw_data * raw_data_2
pdm_data = rawToPdm(raw_data)
pdm_data_2 = rawToPdm(raw_data_2)
pdm_raw_sum = rawToPdm(raw_sum)
pdm_sum,_ = pdmMult(pdm_data, pdm_data_2)
in_data = pdmToRaw(pdm_data)
in_data_2 = pdmToRaw(pdm_data_2)
in_raw_sum = pdmToRaw(pdm_raw_sum)
in_sum = pdmToRaw(pdm_sum)
fft_raw_sum = np.fft.rfft(in_raw_sum)
fft_sum = pdmft(in_sum)
n_plot = 4

pp.subplot(n_plot, 1, 1)
pp.plot(pdm_raw_sum, linewidth=0.08)
pp.plot(pdm_sum, linewidth=0.08)
pp.subplot(n_plot, 1, 2)
pp.plot(in_raw_sum, linewidth=0.5)
pp.plot(in_sum, linewidth=0.5)
pp.subplot(n_plot, 1, 3)
pp.plot(raw_data, linewidth=0.5)
pp.plot(raw_data_2, linewidth=0.5)
pp.plot(raw_sum, linewidth=0.5)
pp.subplot(n_plot, 1, 4)
pp.plot(np.absolute(fft_raw_sum), linewidth=0.5)
pp.plot(np.absolute(fft_sum), linewidth=0.5)
pp.show()

rnd_bits = genRndBits(32000)
raw = pdmToRaw(rnd_bits)
pp.subplot(2, 1, 1)
pp.plot(raw)
pp.subplot(2, 1, 2)
pp.plot(np.abs(np.fft.rfft(raw)))
pp.show()
