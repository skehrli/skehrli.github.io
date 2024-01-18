#!/bin/sh

CI=true emacs -Q --batch -l ./publish.el --funcall dw/publish
npx wrangler pages deploy --project-name systemcrafters public/
