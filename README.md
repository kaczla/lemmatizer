# Lemmatizer

Simple lemmatizer base on [PoliMorf - Polish morphological dictionary](http://zil.ipipan.waw.pl/PoliMorf), which is created using [OpenFst automata](http://www.openfst.org/twiki/bin/view/FST/WebHome).

Lemmatizer contains several scripts:
* *convert_data.rb* - ruby script for preparing data from PoliMorf in specific format (read more in **Word format** section)
* *convert_fst.rb* - ruby script for preparing data from *convert_data.rb* to simple *OpenFst automata*
* *get_symbol.rb* - ruby script for getting all characters (alphabet) from *PoliMorf*
* *prepare_main_data.rb* - ruby script for prepraing all data and save them into *data/main_data* file
* ***lemmatizer.rb*** - ruby script running lemmatizer (require *data/main_data*)
* *run.sh* - simple bash script for running lemmatizer
* *demo.sh* - simple demo written in bash (uses *example_input.txt* file)

#### How run

1) run command `make` (build *main_data*)
2) run lemmatizer: `ruby lemmatizer.rb` or `./lemmatizer.rb` (wait few second for loading data, `CTRL+D` will stop lemmatizer)

#### Word format:

Word format: `[input_word][+][how_char_delete][what_add]`

`[input_word]` - input word

`[+]` - static character, separating input word from the rest

`[how_char_delete]` - says how many character delete from input word, mapping is described in *data/counter_map* file, e.x. **0** delete **0** characters, **A** delete **1** characters, **B** delete **2** characters and so on...

`[what_add]` - says what add to input word (after deleting characters), e.x. **abc** - means add **abc** characters to input word

Example:
* **komputerka+Bek** = from **komputerka** delete **2** characters (**B** - means **2**) and add **ek**, result is ***komputerek***
* **internetach+C** = from **internetach** delete **3** characters (**C** - means **3**) add no add characters, result is ***internet***
* **oprogramowanie+0** = from **oprogramowanie** no delete characters (**0** - means **0**) and no add characters, result is ***oprogramowanie***

#### Morphological dictionary

You can use other morphological dictionary, but save them (in *PoliMorf-1.tab.gz* UTF-8 encoding archive file - *Makefile will choose the latest file - sorting by name*) in fomat:

`[input_word][tabulation = \t][base_word]`

example (remember about tabulation):
```
komputerka	komputerek
internetach	internet
oprogramowanie	oprogramowanie
...
```

#### data/counter_map

Lines says how delete characters (read more in **Word format** section in `[how_char_delete]` format), file fomat:

`[mapped_char][tabulation = \t][how_char_delete]`

example (remember about tabulation):
```
0	0
1	A
2	B
3	C
4	D
...
45	w
46	x
47	y
48	z
```

#### data/main_data

Main data for lemmatizer, can be use for custom program. File is divided into several sections:
1) Section `<MAP_SYMBOL> X` - says how characters are mapped for input word - depends on the input data (morphological dictionary), where `X` is numer of lines to read
	1) Next `X` lines are in format: `[CHARACTER][SPACE][NUMBER]`, example:
    	```
    	' 0
		+ 1
		- 2
		. 3
		0 4
		2 5
		A 6
        ...
		š 108
		ū 109
		Ź 110
		ź 111
		Ż 112
		ż 113
		’ 114
    	```
2) Section `<MAP_COUNTER_CHAR> X` - says how map `[how_char_delete]` (read more in **Word format** section in `[how_char_delete]` format), where `X` is numer of lines to read
	1) Next `X` lines are in format: `[NUMBER][SPACE][CHARACTER]` - is the same as *data/counter_map*, example:
    	```
    	0 0
		1 A
		2 B
		3 C
		4 D
        ...
		45 w
		46 x
		47 y
		48 z
    	```
3) Section `<FINAL> X` - says what states are accepting/final (read more in **algorithm** section), where `X` is numer of lines to read
	1) Next `X` lines are in format: `[NUMBER]`, example:
    	```
    	1787
		9304
		9427
        ...
		269837
		403196
		926817
    	```
4) Section `<MAP_STATE> X Y Z` - says how **beginning state** has go through **character** (characters are mapped by `<MAP_COUNTER_CHAR>` section) to **next state**, where `X` is maximum height of the matrix, `Y` is maximum width of the matrix, `Z` is numer of lines to read (you can define array `STATES[X][Y]` or use other data structures, e.x. map/hashmap)
	1) Next `Z` lines are in format: `[NUMBER_BEGINNING_STATE][SPACE][NUMBER_CHARACTER][SPACE][NUMBER_NEXT_STATE]`, example:
    	```
    	0 6 1
		0 7 2
		0 8 3
        ...
		509503 56 607763
		509503 87 607760
		509504 18 607764
		...
		928979 54 928980
		928980 32 928981
		928981 89 1787
    	```

#### Data structures

Lemamatizer structures:
1) map (**MAP_SYMBOL**) for `MAP_SYMBOL` section (see more in section *data/main_data* point 1), where for line `[CHARACTER][SPACE][NUMBER]`, `[CHARACTER]` is key of map and `[NUMBER]` is value of key and will be necessary reversed map  = **MAP_SYMBOL_REVERSED**, where `[NUMBER]` is key of map and `[CHARACTER]` is value of key
2) map (**MAP_COUNTER_CHAR**) for `MAP_COUNTER_CHAR` section (see more in section *data/main_data* point 2), where for line `[NUMBER][SPACE][CHARACTER]`, `[CHARACTER]` is key of map and `[NUMBER]` is value of key
3) array/set (**FINAL**) for `FINAL` section (see more in section *data/main_data* point 3), where for line `[NUMBER]`, `[NUMBER]` is acceping/final state
4) map/two-dimensional array/matrix = **MAP_STATE** for `MAP_STATE` section (see more in section *data/main_data* point 4), where for line `[NUMBER_BEGINNING_STATE][SPACE][NUMBER_CHARACTER][SPACE][NUMBER_NEXT_STATE]`, `[NUMBER_BEGINNING_STATE]` is value `I` for array `STATES[I][J]`, `[NUMBER_CHARACTER]` is value `J` for array `STATES[I][J]` and `[NUMBER_NEXT_STATE]` is value for `[NUMBER_BEGINNING_STATE] = I` and `[NUMBER_CHARACTER] = J` in array `STATES[I][J]`. Or simpler it is array equal `STATES[NUMBER_BEGINNING_STATE][NUMBER_CHARACTER] = [NUMBER_NEXT_STATE]` - important thing:  `unknown value should be save as -1, those that were not in the file = defualt value is -1`

#### Algorithm

Lemmatizer have simple algorithm for searching:
1) Set **beggining state** as **0**
2) For earch **character** for **input word**
	1) If **character** is not in **MAP_SYMBOL** return **NOT FOUND**
    2) Otherwise save value of **character** from **MAP_SYMBOL** into **character_int**
    3) Go through **MAP_STATE** using **state_beggining** and **character_int** and save it into **state_ending** equal **state_ending := MAP_STATE[state_beggining][character_int]**
    4) If **state_ending** not exist (equal **-1**) return **NOT_FOUND**
    5) Otherwise **state_beggining** is **state_ending** eqaul **state_beggining := state_ending**
3) For **character_int** save value of **character + (plus)** from **MAP_SYMBOL**
4) Go through **MAP_STATE** using **state_beggining** and **character_int** and save it into **state_ending**
5) If **state_ending** not exist (equal **-1**) return **NOT_FOUND**
6) Otherwise **state_beggining** is **state_ending**
7) For each **character_int** from **MAP_SYMBOL** where **local_state_beggining** is **state_beggining**
	1) Go through **MAP_STATE** using **local_state_beggining** and **character_int** and save it into **local_state_ending**
    2) If **local_state_ending** not exist (equal **-1**) or **local_state_ending** is in **FINAL** go to next **character_int**, ignore this iteration
    3) Add value of character_int from **MAP_SYMBOL_REVERSED** (letter) into **array**
    4) Otherwise **local_state_beggining** is **local_state_ending**
    5) Go deep - similar as point 7 - get all list combination of letters
8) For each **answer** (element) of **array**
	1) Copy **word input** into **local_input_word**
	1) Remove characters from **local_input_word** based on first element from **answer** - use **MAP_COUNTER_CHAR** for map first character into number
    2) Add rest elements **answer** into cutted **local_input_word**
    3) Add **local_input_word** into **returning list**
8) Return **returing list**

#### Requirements

* Ruby
* Bash
* Makefile
* ~8.5-12 GB RAM (for determinization *OpenFst automata*) - 8GB RAM if for *convert_data.rb* will be used `--ignore-with-prefix` flag (will be ignored word with prefix **naj** and **nie** when *input_word* and *base_word* do not have same beginning characters, e.g. `niemniejszący	mniejszyć`)


#### Extra

* *OpenFst automata* is used for showing how pack data into automata
* U can see how *OpenFst automata* size file change after determinization and minimialization - change `FST_PIPE` to 1, line should be `FST_PIPE=0` and run command `make data/fst_text.fst` - see in *data* dir size files
