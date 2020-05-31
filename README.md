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
├── luadb_dependent<br/>
│&emsp;&ensp; ├── all_packages.txt<br/>
│&emsp;&ensp; ├── extract_dir.lua<br/>
│&emsp;&ensp; ├── install_lua_packages.sh<br/>
│&emsp;&ensp; ├── README.md<br/>
│&emsp;&ensp; ├── run_in_single_package.sh<br/>
│&emsp;&ensp; └── start_luadb_in_all_packages.sh<br/>
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

ENGLISH VERSION:
- `context_paths` directory contains preprocessing of `json` files into final `csv` file.
    - `dataset_builder.py` is set to generate a new `csv` file so as not to overwrite already generated one.
    - `module_handler.py` is the logic behind generating context paths from AST, `json` files.
    - `stats.py` script calculates interesting statistical information about the dataset.
- `data` directory contains:
    - `data_json` subdirectory containing preprocessed Lua source code modules from `data\modules` into `json` files.
    - `modules` subdirectory containing original Lua modules.
    - `dataset.csv` is a preprocessed dataset from files in `data\data_json`
- `luadb_dependet` directory contains scripts which download all lua modules (pre-downloaded in `data\modules`) and subsequently parses them into `json` files (pre-parsed in `data\data_json`)
- `master_autoencoder` directory contains pre-trained master autoencoder and its graphs.
- `testing` directory contains subdirectories of various tests that were conducted during implementation phase.
    - importantly contains `notes.md` which briefly describe each test.
    - subdirectories with an `- X` in their name are failed experiments.
    - `clustering_model.h5` in each directory is the resulting model which predicts labels.
- `autoencoder.py` script can be run to train _only_ an autoencoder.
- `master.py` is the script for training a complete clustering model along with the autoencoder from scratch.
    - can be configured to load a pretrained master autoencoder, set `train_autoencoder` to `False`.
    - change the directory number where you wish to save a new test.
        - not changing directory number will overwrite old data in said directory.
- `pipeline.py` script loads a single `json` file from `jsonpath` variable, preprocesses it, loads a model which then predicts the final label.
- `utils.py` contains various complementary functions such as `loadFile` and others, along with visualisation functions.
- `visualisation.py` is a standalone script which generates PCA, LDA, t-SNE graphs and a pairplot showcasing label correlations.
    - parameters which need to be configured:
        - change `file_number` to point to subdirectory with said number in `testing`.
        - change `n_clusters` to match the number of clusters set in the clustering model.
        
SLOVAK VERSION:
- `context_paths` adresár obsahuje predspracovanie `json` súborov do finálneho `csv` súboru.
    - `dataset_builder.py` je nastavený na vygenerovanie nového `csv` súboru aby neprepísal už predpripravený.
    - `module_handler.py` obsahuje logiku generovania context path-ov z AST, `json` súborov.
    - `stats.py` skript počíta zaujímavé štatistické informácie o datesete.
- `data` adresár obsahuje:
    - `data_json` podadresár obsahujúci predspracované Lua moduly z adresára `data\modules` do `json` súborov.
    - `modules` podadresár obsahuje originálne Lua moduly.
    - `dataset.csv` je predspracovaný dataset zo súborov z adresára `data\data_json`
- `luadb_dependet` adresár obsahuje skript ktorý stiahne všetky Lua moduly (už predom stiahnuté v `data\modules`) a následne ich spracuje do `json` súborov (už predom predspracované v `data\data_json`)
- `master_autoencoder` adresár obsahuje už natrénovaný master autoencoder a jeho grafy.
- `testing` adresár obsahuje podadresáre rôznych testov ktoré boli spravené počas implementácie a testovania.
    - dôležité: `notes.md` obsahuje informácie ktoré stručne opisujú každý z testov.
    - podadresáre označené `- X` reprezentujú nepodarené experimenty.
    - `clustering_model.h5` v každom test adresáry je natrénovaný model ktorý predikuje labely.
- `autoencoder.py` skript môže byť spustený aby natrénoval _iba_ autoencoder.
- `master.py` je skript na natrénovanie kompletného clustering modelu spolu s autoencoderom od základu.
    - môže byť nastavený aby načítal predom natrénovaný master autoencoder, treba nastaviť `train_autoencoder` na `False`.
    - je potrebné zmeniť číslo testu adresára kam sa uložia výsledky.
        - nezmenenie spôsobí prepísanie starých dát ktoré boli v adresári predtým uložené.
- `pipeline.py` skript načíta jeden `json` súbor z `jsonpath` premennej, predspracuje ho, načíta model ktorý potom predikuje finálny label.
- `utils.py` obsahuje rôzne doplnkové funkcie ako `loadFile` a ostatné, zároveň obsahuje vizualizačné funkcie.
- `visualisation.py` je samostatný skript ktorý generuje PCA, LDA, t-SNE grafy a pairplot znázorňujúci korelácie medzi labelmi.
    - parametre ktoré treba nastaviť:
        - zmeniť `file_number` aby smeroval na podadresár zhodujúci sa s číslom testu v adresári `testing`.
        - zmeniť `n_clusters` aby bol v súlade s počtom clusterov nastavenom v clustering modeli.