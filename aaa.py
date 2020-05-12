from keras.models import load_model, Model
from utils import loadFile, getLastEncoderLayer
from sklearn.decomposition import PCA
import plotly.graph_objs as go
import plotly.offline as py
import pandas as pd

autoencoder = load_model('master_autoencoder/master_autoencoder.h5')
names, data = loadFile()

output_layer_index = getLastEncoderLayer(autoencoder.layers)
encoder = Model(inputs=autoencoder.layers[0].input, outputs=autoencoder.layers[output_layer_index].output, name='encoder')

X = encoder.predict(data, verbose=1)
df = pd.read_csv('testing/test_41/temp.csv', delimiter=',', header=None)

Target = df[df.columns[-2]]

pca = PCA(n_components=5)
pca.fit(X)
X_5d = pca.transform(X)

trace0 = go.Scatter(
    x=X_5d[:, 0],
    y=X_5d[:, 1],
    name=str(Target),
    # hoveron=Target,
    mode='markers',
    # text=Target.unique(),
    showlegend=False,
    marker=dict(
        size=8,
        color=Target,
        colorscale='Jet',
        showscale=False,
        line=dict(
            width=2,
            color='rgb(255, 255, 255)'
        ),
        opacity=0.8
    )
)
data = [trace0]

layout = dict(title='PCA (Principal Component Analysis)',
              hovermode='closest',
              yaxis=dict(zeroline=False),
              xaxis=dict(zeroline=False),
              showlegend=True)

fig = dict(data=data, layout=layout)
py.plot(fig, filename='_PCA-styled-scatter.html')
