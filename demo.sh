#!/bin/bash

DATA_FILE='data/main_data'

if [ -f "${DATA_FILE}" ]
then
  ruby lemmatizer.rb < example_input.txt
else
  echo 'Run `make` command for build data files!'
fi
