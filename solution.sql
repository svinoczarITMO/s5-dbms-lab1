CREATE OR REPLACE PROCEDURE find_tables_with_nulls(search_schema TEXT)
LANGUAGE plpgsql
AS $$
DECLARE 
    table_rec RECORD;
    col_rec RECORD;
    null_exists BOOLEAN;
    counter INTEGER := 0;
    found_any BOOLEAN := FALSE;
    schema_oid OID;
BEGIN
    SELECT oid INTO schema_oid 
    FROM pg_catalog.pg_namespace 
    WHERE nspname = search_schema;
    
    IF schema_oid IS NULL THEN
        RAISE EXCEPTION 'Схема "%" не существует', search_schema;
    END IF;

    RAISE NOTICE 'Схема: %', search_schema;
    RAISE NOTICE '';
    RAISE NOTICE 'No. Имя таблицы';
    RAISE NOTICE '--- -------------------------------';

    FOR table_rec IN 
        SELECT c.oid AS table_oid, c.relname AS table_name
        FROM pg_catalog.pg_class c
        WHERE c.relnamespace = schema_oid
        AND c.relkind = 'r'
        ORDER BY c.relname
    LOOP
        null_exists := FALSE;
        
        FOR col_rec IN 
            SELECT a.attname AS column_name
            FROM pg_catalog.pg_attribute a
            WHERE a.attrelid = table_rec.table_oid
            AND a.attnum > 0
            AND NOT a.attisdropped
        LOOP
            BEGIN
                EXECUTE format(
                    'SELECT EXISTS (SELECT 1 FROM %I.%I WHERE %I IS NULL LIMIT 1)',
                    search_schema, table_rec.table_name, col_rec.column_name
                ) INTO null_exists;
                
                IF null_exists THEN
                    counter := counter + 1;
                    RAISE NOTICE '% %', 
                        LPAD(counter::text, 3, ' '), 
                        table_rec.table_name;
                    found_any := TRUE;
                    EXIT;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    null_exists := FALSE;
            END;
        END LOOP;
    END LOOP;

    IF NOT found_any THEN
        RAISE NOTICE 'В схеме не найдено таблиц с NULL значениями';
    END IF;
END $$;