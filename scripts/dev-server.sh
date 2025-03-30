#!/bin/sh

GUILE_LOAD_PATH="../guile-webframe/src:$GUILE_LOAD_PATH" guix shell -L ../guile-webframe/.guix/modules -D -f guix.scm -- ./scripts/start-server.scm
