Model: "clustering_model"
_________________________________________________________________
Layer (type)                 Output Shape              Param #   
=================================================================
input_1 (InputLayer)         (None, 430, 3)            0         
_________________________________________________________________
masking_1 (Masking)          (None, 430, 3)            0         
_________________________________________________________________
lstm_1 (LSTM)                (None, 430, 128)          67584     
_________________________________________________________________
lstm_2 (LSTM)                (None, 64)                49408     
_________________________________________________________________
clustering (ClusteringLayer) (None, 7)                 448       
=================================================================
Total params: 117,440
Trainable params: 117,440
Non-trainable params: 0
_________________________________________________________________