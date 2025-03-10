DO
$$
    DECLARE
        tbl RECORD;
    BEGIN
        FOR tbl IN
            SELECT tablename FROM pg_tables
            WHERE schemaname = 'public'
            LOOP
                EXECUTE format('DROP TABLE IF EXISTS %I CASCADE;', tbl.tablename);
            END LOOP;
    END;
$$;

DO
$$
    DECLARE
        func RECORD;
    BEGIN
        FOR func IN
            SELECT routine_schema, routine_name
            FROM information_schema.routines
            WHERE routine_type = 'FUNCTION'
              AND routine_schema = 'public'
            LOOP
                EXECUTE format('DROP FUNCTION IF EXISTS %I.%I CASCADE;', func.routine_schema, func.routine_name);
            END LOOP;
    END;
$$;

DO
$$
    DECLARE
        trg RECORD;
    BEGIN
        FOR trg IN
            SELECT event_object_table AS table_name, trigger_name
            FROM information_schema.triggers
            WHERE trigger_schema = 'public'
            LOOP
                EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I CASCADE;', trg.trigger_name, trg.table_name);
            END LOOP;
    END;
$$;

DO
$$
    DECLARE
        pol RECORD;
    BEGIN
        FOR pol IN
            SELECT schemaname, tablename, policyname
            FROM pg_policies
            LOOP
                EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I;', pol.policyname, pol.schemaname, pol.tablename);
            END LOOP;
    END;
$$;
