import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from keras.models import Sequential, Model
from keras.layers import LSTM, RepeatVector, TimeDistributed, Dense, Masking, Dropout, Input
from utils import loadFile, doGraphs, TimingCallback, getModelName
from sklearn.model_selection import train_test_split
import numpy as np
import sys

# so that numpy prints the whole array
np.set_printoptions(threshold=sys.maxsize)

MAX_CONTEXTS = 430  # mean length of context paths
neurons = 150
epochs = 3
batch_size = 32

# TODO activity_regularizer=regularizers.l1(10e-5) --> sparsity constraints
# TODO dropout
# too much regularization/dropout can cause net to underfit
# TODO different value ranges e.g. [0, 1]
# train for smaller dataset
# TODO experiment with learning rate

inputs = Input(shape=(MAX_CONTEXTS, 3))
masked_input = Masking(mask_value=0, input_shape=(MAX_CONTEXTS, 3))(inputs)
encoded = LSTM(neurons)(masked_input)

decoded = RepeatVector(MAX_CONTEXTS)(encoded)
decoded = LSTM(neurons, return_sequences=True)(decoded)
decoded = TimeDistributed(Dense(3))(decoded)
model = Model(inputs, decoded)

# model = Sequential()
# model.add(Masking(mask_value=0, input_shape=(MAX_CONTEXTS, 3)))
# model.add(LSTM(neurons, input_shape=(MAX_CONTEXTS, 3)))  # encoder
# model.add(RepeatVector(MAX_CONTEXTS))  # decoder
# model.add(LSTM(neurons, return_sequences=True))
# model.add(TimeDistributed(Dense(3)))
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])  # binary_crossentropy
print(model.summary())
# TODO masking

context_paths = loadFile()
X_train, X_test = train_test_split(context_paths, test_size=0.2)

cb = TimingCallback()
print('Fitting model...')
history = model.fit(X_train, X_train, epochs=epochs, batch_size=batch_size, verbose=1, shuffle=True,
                    validation_data=(X_test, X_test), callbacks=[cb])
print(cb.logs)
print(sum(cb.logs))

print('Evaluating model...')
score = model.evaluate(context_paths, context_paths, verbose=1)
print("%s: %.4f%%" % (model.metrics_names[1], score[1]*100))
print("%s: %.4f%%" % (model.metrics_names[0], score[0]*100))

# save model and architecture to single file
model_name = getModelName(model, neurons, epochs, batch_size)
model.save(model_name)
print("Saved model to disk.")

# predict_sample = context_paths[0].reshape((1, 430, 3))
# predict_output = model.predict(predict_sample, verbose=0)
# print(predict_sample[0])
# print(predict_output[0])

# create graphs for loss and accuracy
doGraphs(history)
# TODO save graphs

# # load model
# model = load_model('model_Dense.h5')
# model.summary()
#
# # evaluate the model
# score = model.evaluate(context_paths, context_paths, verbose=0)
# print("%s: %.2f%%" % (model.metrics_names[1], score[1]*100))
