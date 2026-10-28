#!/usr/bin/env bash
set -e

for i; do
  file=${i%.*.rock}.rockspec
  version="$(curl -sLF "rockspec_file=@$file" "https://luarocks.org/api/1/$LUAROCKS_API_KEY/upload" | jq -S .version.id)"
  curl -sLF "rock_file=@$i" "https://luarocks.org/api/1/$LUAROCKS_API_KEY/upload_rock/$version"
done
