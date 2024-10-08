do $$
declare 
    rec record;
    column_number integer := 0;
    attr_info text;
    constraint_info text;
begin
    raise notice 'No.  Имя столбца                Атрибуты';
    raise notice '---  -----------------          ------------------------------------------------------';

    for rec in 
        select 
            a.attname as column_name,
            pg_catalog.format_type(a.atttypid, a.atttypmod) as data_type,
            col_description(a.attrelid::regclass::oid, a.attnum) as comment,
            (select string_agg(concat(c.conname, ' ', c.contype), ', ')
             from pg_constraint c
             where c.conrelid = a.attrelid and a.attnum = any(c.conkey)) as constraints
        from 
            pg_attribute a
        where 
            a.attrelid = 'TABLE_NAME'::regclass and 
            a.attnum > 0 and 
            not a.attisdropped
        order by a.attnum
    loop
        column_number := column_number + 1;
        
        attr_info := format('Type: %s', rec.data_type);
        if rec.comment is not null then
            attr_info := attr_info || format(' Comment: %s', rec.comment);
        end if;
        if rec.constraints is not null then
            attr_info := attr_info || format(' Constraints: %s', rec.constraints);
        end if;

        raise notice '% %', column_number, format('%-30s  %s', rec.column_name, attr_info);
    end loop;
end $$;
