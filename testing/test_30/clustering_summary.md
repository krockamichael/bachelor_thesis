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
lstm_2 (LSTM)                (None, 430, 64)           49408     
_________________________________________________________________
lstm_3 (LSTM)                (None, 32)                12416     
_________________________________________________________________
clustering (ClusteringLayer) (None, 7)                 224       
=================================================================
Total params: 129,632
Trainable params: 224
Non-trainable params: 129,408
_________________________________________________________________