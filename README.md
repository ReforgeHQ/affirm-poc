```
brew install dbmate
dbmate up
bundle install --path .bundle/bundle --binstubs .bundle/bundle/bin
.bundle/bundle/bin/rerun -b --no-notify 'rackup config.ru'
```
Open http://localhost:9292.
