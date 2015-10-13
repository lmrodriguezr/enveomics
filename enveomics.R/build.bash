#!/bin/bash

cd $(dirname -- $0)
echo "
library(inlinedocs)
package.skeleton.dx('./');
" | R --vanilla
cat man/enveomics.R-package.Rd | grep -v '^}.$' | grep -v '^\\author{' \
   | perl -pe 's/^\\keyword/}\r\n\\author{Luis M. Rodriguez-R <lmrodriguezr\@gmail.com> [aut, cre]}\r\n\r\n\\keyword/' \
   > o && mv o man/enveomics.R-package.Rd
./install.bash

