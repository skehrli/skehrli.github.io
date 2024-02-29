#!/bin/sh

if [ "${SKIP_BUILD}" = "true" ]; then
  echo "Skipping site build..."
else
  CI=${CI:-true} emacs -Q --batch -l ./publish.el --funcall dw/publish
fi

npx wrangler pages deploy --skip-caching --project-name systemcrafters --branch ${BRANCH:-master} public/
