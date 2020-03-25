import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import tensorflow as tf
from tensorflow.keras.layers import Input, Embedding, Concatenate, LSTM, RepeatVector, TimeDistributed, Dense
from utils import loadFile


class EmbeddingModel:
    @staticmethod
    def build():
        MAX_CONTEXTS = 430  # mean length of context paths
        TOKEN_SIZE = 1500  # Number of unique nodes (1477) rounded to 1500 because of collisions
        PATH_SIZE = 16000  # Number of unique paths (15945) rounded to 16000 because of collisions
        DEFAULT_EMBEDDINGS_SIZE = 128
        CODE_VECTOR_SIZE = 128 * 3

        # Each input sample consists of a bag of x`MAX_CONTEXTS` tuples (source_terminal, path, target_terminal).
        path_source_token_input = Input(shape=(MAX_CONTEXTS,), dtype=tf.int32, name='source_input')
        path_input = Input(shape=(MAX_CONTEXTS,), dtype=tf.int32, name='path_input')
        path_target_token_input = Input(shape=(MAX_CONTEXTS,), dtype=tf.int32, name='target_input')

        # Input paths are indexes, we embed these here.
        paths_embedded = Embedding(PATH_SIZE, DEFAULT_EMBEDDINGS_SIZE, name='path_embedding')(path_input)

        # Input terminals are indexes, we embed these here.
        token_embedding_shared_layer = Embedding(TOKEN_SIZE, DEFAULT_EMBEDDINGS_SIZE, name='token_embedding')
        path_source_token_embedded = token_embedding_shared_layer(path_source_token_input)
        path_target_token_embedded = token_embedding_shared_layer(path_target_token_input)

        # `Context` is a concatenation of the 2 terminals & path embedding.
        # Each context is a vector of size 3 * EMBEDDINGS_SIZE (128).
        context_embedded = Concatenate()([path_source_token_embedded, paths_embedded, path_target_token_embedded])  # --> this up to now, is the output of the STANDALONE embedding model
        # FIXME dropout here or in lstm? recurrent_dropout or normal_droput in lstm? use lstm at all?

        # Apply a dense layer for each context vector (using same weights for all of the context).
        # combined context vectors == context_after_dense
        context_after_dense = TimeDistributed(Dense(CODE_VECTOR_SIZE, use_bias=False, activation='tanh'))(context_embedded)  # in short, this layer probably has to stay
        # TODO why is 'tanh' used? why is use_bias False?

        encoded = LSTM(100, activation='relu', input_shape=context_after_dense.shape)(context_after_dense)
        decoded = RepeatVector(MAX_CONTEXTS)(encoded)
        decoded = LSTM(100, activation='relu', return_sequences=True)(decoded)
        result = TimeDistributed(Dense(1), name='PROBLEM_is_here')(decoded)  # this seems to be some trick according to https://github.com/keras-team/keras/issues/10753, so probably don't remove

        inputs = (path_source_token_input, path_input, path_target_token_input)
        model = tf.keras.Model(inputs=inputs, outputs=result)
        print(model.summary())
        return model


model_x = EmbeddingModel.build()
context_paths = loadFile('separate')

model_x.compile(loss='mse', optimizer='adam', metrics=['accuracy'])
print('Compiled model.')
print('Fitting model.')
history = model_x.fit(context_paths, context_paths, epochs=20, batch_size=32, verbose=1)
