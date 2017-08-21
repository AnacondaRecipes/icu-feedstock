#!/bin/bash

cd source

chmod +x configure install-sh

EXTRA_OPTS=""
if [ "$(uname)" == "Darwin" ]; then
  EXTRA_OPTS="--enable-rpath"
fi

./configure --prefix="$PREFIX" \
            --build=$BUILD \
            --host=$HOST \
            --disable-samples \
            --disable-extras \
            --disable-layout \
            --disable-tests \
            --enable-static \
            "${EXTRA_OPTS}"

make -j$CPU_COUNT
make check
make install

rm -rf $PREFIX/sbin
