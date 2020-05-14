# Skripty na podporu testovania lua repozitárov

## Rozdelenie logiky

Logika pre import a inštaláciu Lua balíčkov a ich testovanie je rozdelené do troch skriptov. Nachádzajú sa v priečinku `etc/luarocks_test/`

[1. Import a inštalácia balíčkov](#1-import-a-inštalácia-balíčkov)

[3. Spustenie lua v balíčkoch](#2-spustenie-lua-v-balíčkoch)

[2. Načítanie priečinkov s balíčkami v cykle](#2-načítanie-priečinkov-s-balíčkami-v-cykle)


## 1. Import a inštalácia balíčkov

 1.  Stiahne zoznam existujúcich balíčkov a ich verzií
 2.  Vyparsuje zoznam balíčkov oddelený novými riadkami
 3.  V cykle nainštaluje príslušný balíček do samostatného priečinka pomocou prepínača  `--tree`
 4.  Ak inštalácia vrátila chybu, priečinok je vymazaný aj s jeho obsahom.


## 2. Načítanie priečinkov s balíčkami v cykle

1. Nastavenie cesty k lua modulom potrebným pre spustenie LuaDB
2. Načítanie súborov v priečinku `modules`
3. Overenie úspešného nainštalovania balíčka pomocou luarocks príkazu `show`
4. V prípade, že je balíček nainštalovaný je zavolaný skript `extract_dir.lua`, pričom názov testovaného balíčka mu je zaslaný ako argument
5. V prípade, že balíček nebol nainštalovaný je do konzoly vypísané upozornenie.

## 3. Spustenie Lua v balíčkoch

1. Inicializovanie potrebných knižníc
2. Extrahovanie grafu z daného balíčka
3. Spočítanie hrán v danom grafe
4. Vypísanie počtu hrán testovaného grafu

