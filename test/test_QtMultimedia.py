try:
  from PySide2 import QtMultimedia
  QT_BINDING='pyside'
except:
  try:
    from PyQt5 import QtMultimedia
    QT_BINDING='pyqt'
  except:
    QT_BINDING='pyside, pyqt'
    raise ImportError('Qt bindings "(%s)" not found.' % QT_BINDING)

import numpy as np
import time

SAMPLE_MAX = 32767
SAMPLE_MIN = -(SAMPLE_MAX + 1)
SAMPLE_RATE = 44100 # [Hz]
NYQUIST = SAMPLE_RATE / 2
SAMPLE_SIZE = 16 # [bit]
CHANNEL_COUNT = 1
BUFFER_SIZE = 5000

info = QtMultimedia.QAudioDeviceInfo.defaultInputDevice()
format = info.preferredFormat()
#format.setChannels(CHANNEL_COUNT)
format.setChannelCount(CHANNEL_COUNT)
format.setSampleSize(SAMPLE_SIZE)
format.setSampleRate(SAMPLE_RATE)



app = None #QtGui.QApplication(sys.argv)

audio_input = QtMultimedia.QAudioInput(format, app)
audio_input.setBufferSize(BUFFER_SIZE)
source = audio_input.start()

def read_data():
    data = np.frombuffer(source.readAll(), 'int16').astype(float)
    if len(data):
        return data
print('Make sure you are playing music when run this script')
time.sleep(2)
data=read_data()

_max = np.max(data)
_min = np.min(data)
_sum = np.sum(data)
print(_max, _min, _sum)
if _max > 0:
    print('succeeded to catch audio')
else:
    print('failed to catch audio')
