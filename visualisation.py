import pandas as pd
import plotly.offline as py
import plotly.graph_objs as go

# Import the 3 dimensionality reduction methods
from sklearn.manifold import TSNE
from sklearn.decomposition import PCA
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis as LDA

file_number = 39
n_clusters = 20
csv_name = 'testing/test_' + str(file_number) + '/temp.csv'

df = pd.read_csv(csv_name, delimiter=',', header=None)
X = df.iloc[:, :df.columns[-2]]
Target = df[df.columns[-2]]


# ------------------------------------------------------------------------------ PCA
# Call the PCA method with 50 components.
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
py.plot(fig, filename=str(file_number) + '_PCA-styled-scatter.html')


# ------------------------------------------------------------------------------ LDA
lda = LDA(n_components=5)
# Taking in as second argument the Target as labels
X_LDA_2D = lda.fit_transform(X, Target.values)

traceLDA = go.Scatter(
    x=X_LDA_2D[:, 0],
    y=X_LDA_2D[:, 1],
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
data = [traceLDA]

layout = dict(title='LDA (Linear Discriminant Analysis)',
              hovermode='closest',
              yaxis=dict(zeroline=False),
              xaxis=dict(zeroline=False),
              showlegend=True)

fig = dict(data=data, layout=layout)
py.plot(fig, filename=str(file_number) + '_LDA-styled-scatter.html')


# ------------------------------------------------------------------------------ T-SNE
# Invoking the t-SNE method
tsne = TSNE()
tsne_results = tsne.fit_transform(X)

traceTSNE = go.Scatter(
    x=tsne_results[:, 0],
    y=tsne_results[:, 1],
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
data = [traceTSNE]

layout = dict(title='TSNE (T-Distributed Stochastic Neighbour Embedding)',
              hovermode='closest',
              yaxis=dict(zeroline=False),
              xaxis=dict(zeroline=False),
              showlegend=True)

fig = dict(data=data, layout=layout)
py.plot(fig, filename=str(file_number) + '_T-SNE-styled-scatter.html')
