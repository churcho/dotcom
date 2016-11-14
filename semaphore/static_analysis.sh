set -e

export MIX_ENV=test

pronto run -f github github_status -c origin/master || true
# check for unsed variables and such
mix compile --force --warnings-as-errors
bash <(curl -s https://codecov.io/bash) -t $CODECOV_UPLOAD_TOKEN

npm run brunch:build && test -f apps/site/priv/static/css/app.css && test -f apps/site/priv/static/js/app.js
