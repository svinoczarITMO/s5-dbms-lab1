#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Использование: $0 <имя_схемы>"
    exit 1
fi

SCHEMA_NAME=$1

psql -f solution.sql
psql -c "CALL find_tables_with_nulls('$SCHEMA_NAME');"