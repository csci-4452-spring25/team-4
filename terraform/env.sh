#!/bin/sh
# The output must be valid JSON, with strings for both
# keys and values.
cat <<EOF
{
  "foo": "$foo",
}
EOF