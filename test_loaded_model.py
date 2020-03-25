import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from keras.models import load_model
from utils import loadFile
import sys
import numpy as np

# so that numpy prints the whole array
np.set_printoptions(threshold=sys.maxsize)

# load model
model = load_model('models/model_LSTM_100_mask.h5')
print(model.summary())

# load data
context_paths = loadFile()
print('Loaded data.')

# evaluate the model
print('Evaluating model.')
score = model.evaluate(context_paths, context_paths, verbose=1)
print("%s: %.4f%%" % (model.metrics_names[1], score[1]*100))
print("%s: %.4f%%" % (model.metrics_names[0], score[0]*100))

# predict sample
# predict_sample = context_paths[1].reshape((1, 430, 3))
# predict_output = model.predict(predict_sample, verbose=0)
# print(predict_sample[0])
# print(predict_output[0])
