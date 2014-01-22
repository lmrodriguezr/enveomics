#!/bin/bash

echo "
install.packages('$(dirname -- $0)/', repos=NULL);
" | R --vanilla

