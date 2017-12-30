
FST_PIPE=1
POLIMORF:=$(shell ls data/PoliMorf-*.tab.gz | sort -r | head -n 1)
ifndef POLIMORF
$(error Cannot find PoliMorf file. Check data directory)
endif

.PHONY: clean post_process

all: main

main: data/main_data post_process

data/PoliMorf.tab: $(POLIMORF)
	@echo "Preparing PoliMorf file"
	@zcat $< | cut -f 1-2 > $@

data/raw_output: data/PoliMorf.tab data/counter_char
	@echo "Creating file with converted words"
	@ruby convert_data.rb $(word 2,$^) < $< | sort | uniq > $@

data/fst_raw: data/raw_output
	@echo "Creating simple OpenFst automata"
	@ruby convert_fst.rb < $< > $@

data/symbols: data/raw_output
	@echo "Creating map symbol for OpenFst automata"
	@ruby get_symbols.rb < $< > $@


ifeq ($(FST_PIPE),0)
data/fst_bin.fst: data/fst_raw data/symbols
	@echo "Creating binary OpenFst automata"
	@fstcompile --isymbols=$(word 2,$^) --osymbols=$(word 2,$^) $< $@

data/fst_det.fst: data/fst_bin.fst
	@echo "Determinization OpenFst automata"
	@fstdeterminize $< $@

data/fst_min.fst: data/fst_det.fst
	@echo "Minimalization OpenFst automata"
	@fstminimize $< $@

data/fst_text.fst: data/fst_min.fst data/symbols
	@echo "Converting binary OpenFst automata into text OpenFst automata"
	@fstprint --isymbols=$(word 2,$^) --osymbols=$(word 2,$^) $< $@
else
data/fst_text.fst: data/fst_raw data/symbols
	@echo "Creating binary, determinization, minimalization OpenFst automata and convert into text OpenFst automata"
	@fstcompile --isymbols=$(word 2,$^) --osymbols=$(word 2,$^) $< | fstdeterminize | fstminimize | fstprint --isymbols=$(word 2,$^) --osymbols=$(word 2,$^) > $@
endif

data/main_data: data/symbols data/counter_char data/fst_text.fst
	@echo "Creating main data file for main program"
	@ruby prepare_main_data.rb $^ $@

post_process:
	@rm -f data/PoliMorf.tab data/raw* data/fst* data/symbols

clean: post_process
	@echo "Cleaning"
	@rm -f data/main_data
