# Clustering neural network for Lua source code modules
LSTM neural network categorizing unlabeled Lua source code modules based on their similarities.
Preprocessing based on code2vec.

## Project structure
Clustering neural network for Lua source code modules<br/>
├── context_paths<br/>
│&emsp;&ensp; ├── dataset_builder.py<br/>
│&emsp;&ensp; ├── module_handler.py<br/>
│&emsp;&ensp; ├── stats.py<br/>
│&emsp;&ensp; └── stats_output.md<br/>
├── data<br/>
│&emsp;&ensp; ├── data_json<br/>
│&emsp;&ensp; ├── modules<br/>
│&emsp;&ensp; └── dataset.csv<br/>
├── master_autoencoder<br/>
│&emsp;&ensp; ├── autoencoder_plot.png<br/>
│&emsp;&ensp; ├── master_autoencoder.h5<br/>
│&emsp;&ensp; ├── master_autoencoder_acc.png<br/>
│&emsp;&ensp; └── master_autoencoder_loss.png<br/>
├── testing<br/>
│&emsp;&ensp; └── notes.md<br/>
├── autoencoder.py<br/>
├── master.py<br/>
├── pipeline.py<br/>
├── README.md <br/>
├── utils.py<br/>
└── visualisation.py<br/>

- `context_paths` directory contains preprocessing of `json` files into final `csv` file.
    - `dataset_builder.py` is set to generate a new `csv` file so as not to overwrite already generated one.
    - `module_handler.py` is the logic behind generating context paths from AST, `json` files.
    - `stats.py` script calculates interesting statistical information about the dataset.
- `data` directory contains:
    - `data_json` subdirectory containing preprocessed Lua source code modules from `data\modules` into `json` files.
    - `modules` subdirectory containing original Lua modules.
    - `dataset.csv` is a preprocessed dataset from files in `data\data_json`
- `master_autoencoder` directory contains pre-trained master autoencoder and its graphs.
- `testing` directory contains subdirectories of various tests that were conducted during implementation phase.
    - importantly contains `notes.md` which briefly describe each test.
    - subdirectories with an `- X` in their name are failed experiments.
    - `clustering_model.h5` in each directory is the resulting model which predicts labels.
- `autoencoder.py` script can be run to train _only_ an autoencoder.
- `master.py` is the script for training a complete clustering model along with the autoencoder from scratch.
    - can be configured to load a pretrained master autoencoder, set `train_autoencoder` to `False`.
    - change the directory number where you wish to save a new test.
        - not chaning directory number will overwrite old data in said directory.
- `pipeline.py` script loads a single `json` file from `jsonpath` variable, preprocesses it, loads a model which then predicts the final label.
- `utils.py` contains various complementary functions such as `loadFile` and others, along with visualisation functions.
- `visualisation.py` is a standalone script which generates PCA, LDA, t-SNE graphs and a pairplot showcasing label correlations
    - parameters which need to be configured:
        - change `file_number` to point to subdirectory with said number in `testing`
        - change `n_clusters` to match the number of clusters set in the clustering model