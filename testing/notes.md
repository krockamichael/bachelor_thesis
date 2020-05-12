test 1:
    - encoder layers non-trainable
    - 1 LSTM layer
    - regularizers.l1(10e-5)
    - 128 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- only used 2 categories - trash
    
test 2:
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5) on 2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- autoencoder converged sLoWlY
    
test 3:
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5) on 1st LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- only used 2 categories -- trash
    
test 4:
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        1st & 2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- autoencoder converges (?) SLOWLY
           -- same max percentage number for every label
           -- cluster is trash

test 5:
    - encoder layers TRAINABLE
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        1st LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 128 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- high loss on 1st epoch
           -- autoencoder converges slowly
           -- clustering decides based on AST size
           -- trash

test 6:
    - encoder layers non-trainable
    - 3 LSTM layers
    - regularizers.l1(10e-5):
        1st LSTM layer
    - 128 neurons, 64 neurons, 10 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- high loss on 1st epoch
           -- loss was going down, but slowly
           -- accuracy at a ~standstill
           -- used 5 / 7 labels
           -- reached tolerance threshold
           -- clustering decides based on AST size
           -- trash

test 7:
    - NEWEST DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 200 epochs
    - 128 batch size autoencoder
    - 10 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- used only 3 categories
           -- trash
           
test 8:
    - ONLY BIG DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 10 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- used only 2 categories
           -- trash

test 9:
    - MASKING_VALUE = [0, 0, 0]
    - everything DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 10 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- used only 7 / 10 categories, and not well
           -- problem with 10 categories??
           -- trash
           
test 10:
    - MASKING_VALUE = 0
    - everything DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - dropout(0.2):
        1st LSTM layer
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- only used 2 categories
           -- trash
           
test 11:
    - same as 2, retraining clutering layer just to see
    RESULT -- worked well
           -- autoencoder setup from 2 is good - let's try to make it better
    
test 12:
    - same as 2, without masking
    RESULT -- masking is important
           -- only used 2 categories
           -- trash
           
test 13:
    - same as 2, with mask_value=[0, 0, 0]
    RESULT -- trash
    
test 14:
    - same as 2, with dropout
    - dropout 0.2 on LSTM layer 2
    RESULT -- trash
           -- used only 3 categories
           
test 15:
    - same as 2, with dropout 0.2 on LSTM layer 1
    RESULT -- used only 5 categories, with 2 being below 50 members
           -- trash
           
test 16:
    - same as 2, regularizers.l1(10e-4) from 10e-5
    RESULT -- used only 5 categories, with 3 being below 300 members
           -- trash

test 17:
    - same as 2, regularizers.l1(10e-3) from 10e-5
    RESULT -- used only 1 categorie
           -- trash

test 18:
    - same as 2, regularizers.l1(10e-6) from 10e-5
    RESULT -- used 4 / 7 categories, wasn't THAT bad looked ok
           -- check it in BP-visualisation

test 19:
    - 1 LSTM - 16
    RESULT - promising
           - used all categories
           - used one categorie poorly
           - used all 8000 iterations for clustering
           - check in BP-visualisation

test 20:
    - 1 LSTM - 8
    RESULT - same as 16
           - graph warning because of no variance between some labels
           - used 4200 iterations for clustering
           
test 21:
    - 2 LSTM - 16, 8
    RESULT - promising results
           - used 3360 iterations for clustering
           - check in BP-visualisation
           -- ALERT -- first layer in decoder had 64 (instead of 8) by mistake
           
test 22:
    - 2 LSTM - 16, 8 - but with correct first layer in decoder
    RESULT - promising results
           - label 0 and label 4 showed linear correlation
           - checked in BP visualisation - no noticeable patterns
           - subject to closer inspection
           
MIDWAY CONCLUSION - test 2 looks (in BP visualisation) to be the most promising
                  - data samples in categories have something in common, for sure
                  - what is it in detail?
                  - some samples have clear connections between them - structure, order, node types
                  - but those same samples can have no connection whatsoever with other samples in the same label
                  RESULT -- try MORE labels - 10~ and go from there
                  
test 23:
    - same as 2
    - 10 labels (instead of 7)
    RESULT -- trash
    
test 24:
    - same as 2
    - 6 labels (instead of 7)
    RESULT -- trash
    
test 25:
    - same as 2
    - 6 labels
    - loaded autoencoder from 2
    RESULT -- used the categories "well" - one has only 186 members others are acceptable
    
test 26:
    - same as 2
    - 10 labels
    RESULT -- used only 8 / 10 categories
           -- could be better
    
test 27:
    - autoencoder from 2
    - 32000 max iterations
    - 20 labels
    RESULT -- trash
    
test 28:
    - 3 LSTM layers
    - 128, 64, 32
    - regularizer.l1(10e-5) on 3rd layer
    RESULT -- trash
    
test 29:
    - 4 LSTM layers
    - 128, 64, 32, 16
    - regularizer.l1(10e-5) on 2nd and 4th layer
    RESULT -- trash
    
test 30:
    - 3 LSTM
    - 128, 64, 32
    - regularizers.l1(10e-5) on 2nd
    - regularizers.l1(10e-3) on 3rd
    RESULT -- trash
    
test 31:
    - 3 LSTM
    - 128, 64, 32
    - regularizers.l1(10e-5) on 2nd
    RESULT -- trash
    
test 32:
    - loaded autoencoder from 2
    - 8 labels
    RESULT -- okay
    
test 33:
    - laoded autoencoder from 2
    - 9 labels
    RESULT -- trash
    
test 34:
    - master autoencoder
    - 7 lables
    - adam optimizer in clustering model
    RESULT -- trash

test 35:
    - master autoencoder
    - 7 labels
    - SGD(0.01, 0.9) optimizer in clustering model
    - tol == 0.001
    RESULT -- 6 / 7 labels
    
test 36:
    - master autoencoder
    - 6 labels
    - SGD(0.01, 0.9) optimizer in clustering model
    - tol == 0.0015
    RESULT -- used 4 / 6 categories
           -- used a 5th category but only 8 members
           -- trash
           
test 37:
    - autoencoder setup from test 2
    - correct_dataset
    - 7 labels
    - tol == 0.001
    RESULT -- is ok
    
test 38:
    - autoencoder from 37
    - 10 labels
    RESULT -- okay
    
test 39:
    - autoencoder from 37
    - 20 labels
    RESULT -- okay
    
test 40:
    - autoencoder from 37
    - 50 labels
    RESULT -- okay
------------------------------------------------------------------------------------
an error in generating paths was discovered, test 41+ are trained on correct dataset
------------------------------------------------------------------------------------
test 41:
    - clean 2 master autoencoder
    - 10 labels
    RESULT -- okay
    
test 42:
    - same as 41
    - 15 labels
    RESULT -- okay
    
test 43:
    - same as 41
    - 200 labels
    RESULT -- whatever, can't read anything from so many labels
    
test 44:
    - same as 41
    - 10 labels
    - kmeans init 50 (instead of 20)
    RESULT -- same as 41