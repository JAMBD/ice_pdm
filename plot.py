#!/usr/bin/python3
from matplotlib import pyplot as plt
import numpy as np
from scipy import signal

print( signal.buttord([0.005, 0.5], [0.0025, 0.70], -1, -20))
b, a = signal.butter(5, [0.005, 0.5], btype="bandpass")
w, h = signal.freqz(b, a)
plt.plot(w, 20 * np.log10(abs(h)))
plt.grid(which='both', axis='both')
plt.show()

data = np.array(bytearray(open("data.raw", "rb").read()), dtype=np.int16)
while (data[0] >> 5) != 0x03:
    data = data[1:]
data = data[:(len(data) // 4) * 4]
data = np.reshape(data, (-1, 4))
print(np.std(data[:, 0] & 0xE0))
data = data & 0x1F
data = np.cumsum((data - 8), axis=0)
data = signal.lfilter(b, a, data, axis=0)
plt.plot(data)
plt.show()

for i in range(4):
    f,t,sxx = signal.spectrogram(data[::2, i], 234375, np.hanning(512))
    plt.imshow(np.log10(sxx))
    plt.show()

