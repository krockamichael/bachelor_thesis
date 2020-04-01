import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from keras.models import Model
from keras.layers import LSTM, RepeatVector, TimeDistributed, Dense, Masking, Dropout, Input, Lambda
from utils import loadFile, doGraphs, TimingCallback, getModelName, cropOutputs
import numpy as np
import sys

# so that numpy prints the whole array
np.set_printoptions(threshold=sys.maxsize)
np.random.seed(7)

neurons = 100
epochs = 500
batch_size = 256

# TODO dropout
# TODO If the initial predictions of your model are too far from this range, you might like to have a BatchNormalization (not really necessary) before or after the last Dense

inputs = Input(shape=(430, 3))
masked_input = Masking(mask_value=0, input_shape=(430, 3))(inputs)
encoded = LSTM(neurons)(masked_input)
decoded = RepeatVector(430)(encoded)
decoded = LSTM(neurons, return_sequences=True)(decoded)
decoded = TimeDistributed(Dense(3))(decoded)
decoded = Lambda(cropOutputs, output_shape=(430, 3))([decoded, inputs])
model = Model(inputs, decoded)
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])  # binary_crossentropy
print(model.summary())

# load data and split into train, validate and test (70, 20, 10)
context_paths = loadFile()
train, validate, test = np.split(context_paths, [int(.7*len(context_paths)), int(.9*len(context_paths))])

cb = TimingCallback()
print('Fitting model...')
history = model.fit(train, train, epochs=epochs, batch_size=batch_size, verbose=1,
                    shuffle=True, validation_data=(validate, validate), callbacks=[cb])
print(cb.logs)
print(sum(cb.logs))

print('Evaluating model...')
score = model.evaluate(test, test, verbose=1)
print("%s: %.2f%%" % (model.metrics_names[1], score[1]*100))
print("%s: %.2f%%" % (model.metrics_names[0], score[0]*100))

# save model and weights to single file
model_name = getModelName(model, neurons, epochs, batch_size, score[1]*100)
model.save(model_name)
print("Saved model to disk.")

# predict_sample = context_paths[0].reshape((1, 430, 3))
# predict_output = model.predict(predict_sample, verbose=0)
# print(predict_sample[0])
# print(predict_output[0])

# create graphs for loss and accuracy
doGraphs(history, model_name)
