#!/bin/bash

# Cria 10 ficheiros: test1.txt até test10.txt
for i in {1..10}; do
    touch "test${i}.txt"
done

echo "10 ficheiros criados com sucesso!"
