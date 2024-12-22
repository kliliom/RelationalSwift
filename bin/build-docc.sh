#!/bin/bash

set -e

cd "$(dirname "$0")"
cd ..

rm -rf .docs
rm -rf .docs-modules
mkdir -p .docs-modules

echo "-- Generating documentation for Interface"

swift package --allow-writing-to-directory .docs-modules/interface \
    generate-documentation \
    --target Interface \
    --disable-indexing \
    --enable-experimental-external-link-support \
    --transform-for-static-hosting \
    --hosting-base-path RelationalSwift/modules/interface \
    --output-path .docs-modules/interface
echo '<script>window.location.href += "documentation/interface"</script>' > .docs-modules/interface/index.html

echo "-- Generating documentation for Table"

swift package --allow-writing-to-directory .docs-modules/table \
    generate-documentation \
    --target Table \
    --disable-indexing \
    --enable-experimental-external-link-support \
    --dependency .docs-modules/interface \
    --transform-for-static-hosting \
    --hosting-base-path RelationalSwift/modules/table \
    --output-path .docs-modules/table
echo '<script>window.location.href += "documentation/table"</script>' > .docs-modules/table/index.html

echo "-- Generating documentation for RelationalSwift"

swift package --allow-writing-to-directory .docs \
    generate-documentation \
    --target RelationalSwift \
    --disable-indexing \
    --enable-experimental-external-link-support \
    --dependency .docs/modules/interface \
    --dependency .docs/modules/table \
    --transform-for-static-hosting \
    --hosting-base-path RelationalSwift \
    --output-path .docs
echo '<script>window.location.href += "/documentation/relationalswift"</script>' > .docs/index.html
mv .docs-modules .docs/modules
