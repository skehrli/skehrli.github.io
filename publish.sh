#!/bin/sh

CI=true emacs -Q --batch -l ./publish.el --funcall dw/publish
wrangler pages deploy --project-name systemcrafters public/
