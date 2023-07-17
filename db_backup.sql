PGDMP     4                    {           electron    15.2    15.2 +              0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false                       0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                       1262    17116    electron    DATABASE     �   CREATE DATABASE electron WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE electron;
                michaelm    false                        2615    2200    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                postgres    false                       0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                   postgres    false    6                        3079    17117    ltree 	   EXTENSION     9   CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;
    DROP EXTENSION ltree;
                   false    6                       0    0    EXTENSION ltree    COMMENT     Q   COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';
                        false    2            �           1255    17302    downstream_connection(bigint)    FUNCTION     �  CREATE FUNCTION public.downstream_connection(connection_id bigint) RETURNS SETOF bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
	SELECT end_c.id
	FROM connection AS start_c
	JOIN connection as end_c
	ON end_c.start_equipment_id = start_c.end_equipment_id AND end_c.start_interface_id = start_c.end_interface_id
	WHERE start_c.id = connection_id AND start_c.end_equipment_id IS NOT NULL AND start_c.end_interface_id IS NOT NULL;
END;
$$;
 B   DROP FUNCTION public.downstream_connection(connection_id bigint);
       public          postgres    false    6                       0    0 4   FUNCTION downstream_connection(connection_id bigint)    COMMENT     �   COMMENT ON FUNCTION public.downstream_connection(connection_id bigint) IS 'Return all the downstream connections for the combination of equipment and interface at the end of this connection.';
          public          postgres    false    447            �           1255    17303 &   fn_connection_identifier(public.ltree)    FUNCTION     -  CREATE FUNCTION public.fn_connection_identifier(connection_path public.ltree) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN (
        SELECT
	        CASE
		        WHEN (nlevel (path) = 1 OR use_parent_identifier != true) THEN identifier
		        ELSE public.fn_connection_identifier(subpath(path,0, -1))
				|| COALESCE((SELECT value FROM system_settings WHERE LOWER(label) = 'ownership_delimiter'),'')
				|| identifier
	        END
        FROM connection
        WHERE connection.path = connection_path
    );
END;
$$;
 M   DROP FUNCTION public.fn_connection_identifier(connection_path public.ltree);
       public          michaelm    false    6    2    2    6    6    2    6    2    6    2    6                       0    0 ?   FUNCTION fn_connection_identifier(connection_path public.ltree)    ACL     b   GRANT ALL ON FUNCTION public.fn_connection_identifier(connection_path public.ltree) TO sm_webapp;
          public          michaelm    false    474            �           1255    17304 /   fn_connection_identifier_location(public.ltree)    FUNCTION       CREATE FUNCTION public.fn_connection_identifier_location(connection_path public.ltree) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE
    connection_identifier text;
    start_equipment text;
    end_equipment text;
    delimiter_value text;

BEGIN

    SELECT
        public.fn_connection_identifier(connection_path),
        public.fn_equipment_identifier(start_eq.path),
        public.fn_equipment_identifier(end_eq.path)
    INTO
        connection_identifier,
        start_equipment,
        end_equipment
    FROM connection
    JOIN equipment AS start_eq ON connection.start_equipment_id = start_eq.id
    JOIN equipment AS end_eq ON connection.end_equipment_id = end_eq.id
    WHERE connection.path = connection_path;

    SELECT value INTO delimiter_value FROM system_settings WHERE LOWER(label) = 'ownership_delimiter';

    RETURN COALESCE(start_equipment,'') || COALESCE(delimiter_value,'') || COALESCE(connection_identifier,'') || COALESCE(delimiter_value,'') || COALESCE(end_equipment,'');
END;
$$;
 V   DROP FUNCTION public.fn_connection_identifier_location(connection_path public.ltree);
       public          michaelm    false    2    2    6    6    2    6    2    6    2    6    6            	           0    0 H   FUNCTION fn_connection_identifier_location(connection_path public.ltree)    ACL     k   GRANT ALL ON FUNCTION public.fn_connection_identifier_location(connection_path public.ltree) TO sm_webapp;
          public          michaelm    false    473            �           1255    17305 5   fn_connection_ids_check(public.ltree, bigint, bigint)    FUNCTION     �  CREATE FUNCTION public.fn_connection_ids_check(n_path public.ltree, start_interface_id bigint, end_interface_id bigint) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    cnt INTEGER;
BEGIN
    -- Check if the record is parent or not.
    SELECT COUNT(*) INTO cnt FROM connection WHERE path <@ n_path;
    
    IF (cnt > 1 AND start_interface_id IS NOT NULL AND end_interface_id IS NOT NULL) THEN
        RETURN false;
    ELSE
        RETURN true;
    END IF;
END;
$$;
 w   DROP FUNCTION public.fn_connection_ids_check(n_path public.ltree, start_interface_id bigint, end_interface_id bigint);
       public          postgres    false    6    2    2    6    6    2    6    2    6    2    6            �           1255    17306 %   fn_equipment_identifier(public.ltree)    FUNCTION     &  CREATE FUNCTION public.fn_equipment_identifier(equipment_path public.ltree) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN (
        SELECT
	        CASE
		        WHEN (nlevel (path) = 1 OR use_parent_identifier != true) THEN identifier
		        ELSE public.fn_equipment_identifier(subpath(path,0, -1))
				|| COALESCE((SELECT value FROM system_settings WHERE LOWER(label) = 'function_delimiter'),'')
				|| identifier
	        END
        FROM equipment
        WHERE equipment.path = equipment_path
    );
END;
$$;
 K   DROP FUNCTION public.fn_equipment_identifier(equipment_path public.ltree);
       public          michaelm    false    6    2    2    6    6    2    6    2    6    2    6            
           0    0 =   FUNCTION fn_equipment_identifier(equipment_path public.ltree)    ACL     `   GRANT ALL ON FUNCTION public.fn_equipment_identifier(equipment_path public.ltree) TO sm_webapp;
          public          michaelm    false    411            �           1255    17307 *   fn_equipment_identifier_sort(public.ltree)    FUNCTION       CREATE FUNCTION public.fn_equipment_identifier_sort(equipment_path public.ltree) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN (
        SELECT
	        CASE
		        WHEN (nlevel (path) = 1) THEN identifier
		        ELSE public.fn_equipment_identifier_sort(subpath(path,0, -1))
				|| COALESCE((SELECT value FROM system_settings WHERE LOWER(label) = 'function_delimiter'),'')
				|| identifier
	        END
        FROM equipment
        WHERE equipment.path = equipment_path
    );
END;
$$;
 P   DROP FUNCTION public.fn_equipment_identifier_sort(equipment_path public.ltree);
       public          michaelm    false    2    2    6    6    2    6    2    6    2    6    6                       0    0 B   FUNCTION fn_equipment_identifier_sort(equipment_path public.ltree)    ACL     e   GRANT ALL ON FUNCTION public.fn_equipment_identifier_sort(equipment_path public.ltree) TO sm_webapp;
          public          michaelm    false    409            �           1255    17308 /   fn_field_unique_valid(text, text, text, bigint)    FUNCTION       CREATE FUNCTION public.fn_field_unique_valid(table_name text, column_name text, field text, table_id bigint) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE cnt INTEGER;
BEGIN
    -- Check if field of column exists in table(not same with current id)
    IF (table_id > 0) THEN
        IF (column_name = 'id' OR column_name = 'type_id' OR column_name = 'type_resource_id' OR column_name = 'equipment_id' OR column_name = 'connection_id') THEN
            EXECUTE format('SELECT COUNT(*) FROM %I WHERE id <> $1 AND %I = $2', table_name, column_name) INTO cnt USING table_id, CAST(field AS BIGINT);
        ELSE
            EXECUTE format('SELECT COUNT(*) FROM %I WHERE id <> $1 AND %I = $2', table_name, column_name) INTO cnt USING table_id, field;
        END IF;
    ELSE
        IF (column_name = 'id' OR column_name = 'type_id' OR column_name = 'type_resource_id' OR column_name = 'equipment_id' OR column_name = 'connection_id') THEN
            EXECUTE format('SELECT COUNT(*) FROM %I WHERE %I = $1', table_name, column_name) INTO cnt USING CAST(field AS BIGINT);
        ELSE
            EXECUTE format('SELECT COUNT(*) FROM %I WHERE %I = $1', table_name, column_name) INTO cnt USING field;
        END IF;
    END IF;
    
    RETURN NOT cnt > 0;
END;
$_$;
 l   DROP FUNCTION public.fn_field_unique_valid(table_name text, column_name text, field text, table_id bigint);
       public          michaelm    false    6            �           1255    17309 +   fn_hierarchy_path_check(text, public.ltree)    FUNCTION     I  CREATE FUNCTION public.fn_hierarchy_path_check(table_name text, n_path public.ltree DEFAULT NULL::public.ltree) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    cnt integer;
BEGIN
    -- Check the path column if the LTREE hierarchy is valid.
    WHILE n_path IS NOT NULL AND nlevel(n_path) > 1 LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE path = $1', table_name) INTO cnt USING n_path;
        IF cnt = 0 THEN
            RETURN false;
        END IF;
        n_path = subpath(n_path, 0, -1);
    END LOOP;
        
    RETURN true;
END;
$_$;
 T   DROP FUNCTION public.fn_hierarchy_path_check(table_name text, n_path public.ltree);
       public          postgres    false    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            �           1255    17310 #   fn_interface_identifier(text, text)    FUNCTION     3  CREATE FUNCTION public.fn_interface_identifier(equipment_identifier text, interface_identifier text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE delimiter_value TEXT;
BEGIN
    SELECT value INTO delimiter_value FROM system_settings WHERE LOWER(label) = 'interface_delimiter';

    -- Check if delimiter exist
    IF delimiter_value IS NULL THEN
        RAISE EXCEPTION 'label not found in system_settings table'; 
    END IF;

    RETURN COALESCE(equipment_identifier,'') || COALESCE(delimiter_value || interface_identifier,'');
END;
$$;
 d   DROP FUNCTION public.fn_interface_identifier(equipment_identifier text, interface_identifier text);
       public          michaelm    false    6            �           1255    17311 (   fn_property_identifier(text, text, text)    FUNCTION     y  CREATE FUNCTION public.fn_property_identifier(equipment_identifier text, resource_modifier text, property_modifier text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE delimiter_value TEXT;
BEGIN
    SELECT value INTO delimiter_value FROM system_settings WHERE LOWER(label) = 'ownership_delimiter';

    -- Check if delimiter exist
    IF delimiter_value IS NULL THEN
        RAISE EXCEPTION 'label not found in system_settings table'; 
    END IF;

    RETURN COALESCE(equipment_identifier,'') || COALESCE(delimiter_value || resource_modifier,'') || COALESCE(delimiter_value || property_modifier,'');
END;
$$;
 x   DROP FUNCTION public.fn_property_identifier(equipment_identifier text, resource_modifier text, property_modifier text);
       public          michaelm    false    6            �           1255    17312 +   fn_reference_path_check(text, public.ltree)    FUNCTION     �  CREATE FUNCTION public.fn_reference_path_check(table_name text, n_path public.ltree DEFAULT NULL::public.ltree) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE cnt integer;
BEGIN
    -- Check the path column if the circular references in the hierarchy is valid(check existing same index).
    EXECUTE format('SELECT COUNT(*) FROM %I WHERE path = $1', table_name) INTO cnt USING n_path;
    RETURN NOT (cnt > 1);
END;
$_$;
 T   DROP FUNCTION public.fn_reference_path_check(table_name text, n_path public.ltree);
       public          postgres    false    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            �           1255    17313 3   fn_reference_path_check(text, public.ltree, bigint)    FUNCTION     �  CREATE FUNCTION public.fn_reference_path_check(table_name text, n_path public.ltree DEFAULT NULL::public.ltree, n_id bigint DEFAULT NULL::bigint) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE cnt integer;
BEGIN
    -- Check the path column if the circular references in the hierarchy is valid(check existing same index).
    EXECUTE format('SELECT COUNT(*) FROM %I WHERE path = $1', table_name) INTO cnt USING n_path;

    -- Check the path if the last label in the path is same with the record ID
    IF (subpath(n_path, -1)::text != n_id::text) OR cnt > 1 THEN
        RETURN false;
    ELSE
        RETURN true;
    END IF;
END;
$_$;
 a   DROP FUNCTION public.fn_reference_path_check(table_name text, n_path public.ltree, n_id bigint);
       public          postgres    false    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            �           1255    17314 "   fn_resource_identifier(text, text)    FUNCTION     ,  CREATE FUNCTION public.fn_resource_identifier(equipment_identifier text, resource_modifier text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE delimiter_value TEXT;
BEGIN
    SELECT value INTO delimiter_value FROM system_settings WHERE LOWER(label) = 'ownership_delimiter';

    -- Check if delimiter exist
    IF delimiter_value IS NULL THEN
        RAISE EXCEPTION 'label not found in system_settings table'; 
    END IF;

    RETURN COALESCE(equipment_identifier,'') || COALESCE(delimiter_value || resource_modifier,'');
END;
$$;
 `   DROP FUNCTION public.fn_resource_identifier(equipment_identifier text, resource_modifier text);
       public          michaelm    false    6            �           1255    17315 ,   fn_table_column_id_check(text, text, bigint)    FUNCTION     u  CREATE FUNCTION public.fn_table_column_id_check(table_name text, column_name text, table_id bigint) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE cnt INTEGER;
BEGIN
    -- Check if id exists in the table
    EXECUTE format('SELECT COUNT(*) FROM %I WHERE %I = $1', table_name, column_name) INTO cnt USING table_id;
    RETURN (cnt > 0);
END;
$_$;
 c   DROP FUNCTION public.fn_table_column_id_check(table_name text, column_name text, table_id bigint);
       public          postgres    false    6            �           1255    17316    fn_text_field_valid(text, text)    FUNCTION     =  CREATE FUNCTION public.fn_text_field_valid(field text, valid_type text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE cnt INTEGER;
BEGIN
    -- Check if the 'field' is null or empty
    IF (valid_type = 'empty') THEN
        RETURN NOT COALESCE(field, '') = ''; 
    END IF;
    
    -- Check if length of 'field' is greater than 5 characters
    IF (valid_type = 'length') THEN
        RETURN LENGTH(field) > 5;
    END IF;
    
    -- Check if table exists in the database
    IF (valid_type = 'table') THEN
        EXECUTE format('SELECT COUNT(*) FROM information_schema.tables WHERE table_name = %L', field) INTO cnt;
        RETURN cnt > 0;
    END IF;

    -- Check if the 'field' is numerical
    IF (valid_type = 'number') THEN
        RETURN field ~ '^[0-9]*\.?[0-9]*$';
    END IF;
END;
$_$;
 G   DROP FUNCTION public.fn_text_field_valid(field text, valid_type text);
       public          michaelm    false    6            �           1255    17317    fn_type_modifier(public.ltree)    FUNCTION     :  CREATE FUNCTION public.fn_type_modifier(type_path public.ltree) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN (
        SELECT
	        COALESCE(modifier, public.fn_type_modifier(subpath(type_path, 0, -1)))
        FROM equipment_type
        WHERE path = type_path
    );
END;
$$;
 ?   DROP FUNCTION public.fn_type_modifier(type_path public.ltree);
       public          michaelm    false    2    2    6    6    2    6    2    6    2    6    6            �           1255    17952 i   fn_update_equipment(bigint, text, public.ltree, boolean, public.ltree, bigint, text, boolean, text, date)    FUNCTION     8  CREATE FUNCTION public.fn_update_equipment(equipment_id bigint, equipment_identifier text, equipment_path public.ltree, equipment_use_parent_identifier boolean, equipment_location_path public.ltree, equipment_type_id bigint, equipment_description text, equipment_is_approved boolean, equipment_comment text, equipment_modified_at date) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN

        UPDATE equipment
		SET identifier = equipment_identifier,
			path = equipment_path,
			use_parent_identifier = equipment_use_parent_identifier,
			location_path = equipment_location_path,
			type_id = equipment_type_id,
			description = equipment_description,
			is_approved = equipment_is_approved,
			comment = equipment_comment,
			modified_at = equipment_modified_at
		WHERE id = equipment_id;
    
END;
$$;
 O  DROP FUNCTION public.fn_update_equipment(equipment_id bigint, equipment_identifier text, equipment_path public.ltree, equipment_use_parent_identifier boolean, equipment_location_path public.ltree, equipment_type_id bigint, equipment_description text, equipment_is_approved boolean, equipment_comment text, equipment_modified_at date);
       public          postgres    false    6    2    2    6    6    2    6    2    6    2    6            �           1255    17318 ;   proc_add_connection_history(text, text, bigint, text, text) 	   PROCEDURE     �	  CREATE PROCEDURE public.proc_add_connection_history(IN n_modified_by text, IN n_reason text, IN n_connection_id bigint, IN n_description text, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if connection_id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_connection_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"connection_id" cannot be empty or null.';
        RETURN;
    END IF;
    -- -- Check if connection_id exists within table
    -- IF (public.fn_field_unique_valid('connection', 'id', CAST(n_connection_id AS TEXT), NULL) = TRUE) THEN
    --     RAISE EXCEPTION 'id = % does not exist in the "connection" table.', n_connection_id;
    --     RETURN;
    -- END IF;
    
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Create new record into the table
    INSERT INTO connection_history(
        connection_id, 
        description, 
        reason, 
        comment, 
        modified_by, 
        modified_at
    )
    VALUES (
        n_connection_id, 
        n_description, 
        n_reason, 
        n_comment, 
        n_modified_by, 
        CURRENT_TIMESTAMP
    );
END;
$$;
 �   DROP PROCEDURE public.proc_add_connection_history(IN n_modified_by text, IN n_reason text, IN n_connection_id bigint, IN n_description text, IN n_comment text);
       public          michaelm    false    6            �           1255    17319 :   proc_add_equipment_history(text, text, bigint, text, text) 	   PROCEDURE     �	  CREATE PROCEDURE public.proc_add_equipment_history(IN n_modified_by text, IN n_reason text, IN n_equipment_id bigint, IN n_description text, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if equipment_id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_equipment_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"equipment_id" cannot be empty or null.';
        RETURN;
    END IF;
    -- -- Check if equipment_id exists within table
    -- IF (public.fn_field_unique_valid('equipment', 'id', CAST(n_equipment_id AS TEXT), NULL) = TRUE) THEN
    --     RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_equipment_id;
    --     RETURN;
    -- END IF;
    
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Create new record into the table
    INSERT INTO equipment_history(
        equipment_id, 
        description, 
        reason, 
        comment, 
        modified_by, 
        modified_at
    )
    VALUES (
        n_equipment_id, 
        n_description, 
        n_reason, 
        n_comment, 
        n_modified_by, 
        CURRENT_TIMESTAMP
    );
END;
$$;
 �   DROP PROCEDURE public.proc_add_equipment_history(IN n_modified_by text, IN n_reason text, IN n_equipment_id bigint, IN n_description text, IN n_comment text);
       public          michaelm    false    6            �           1255    17320 >   proc_add_general_history(text, text, text, bigint, text, text) 	   PROCEDURE     r  CREATE PROCEDURE public.proc_add_general_history(IN n_modified_by text, IN n_reason text, IN n_table_name text, IN n_table_id bigint, IN n_description text, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if table_name is not empty or null
    IF (public.fn_text_field_valid(n_table_name, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"table_name" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if table_name exists in the database
    IF (public.fn_text_field_valid(n_table_name, 'table') = FALSE) THEN
        RAISE EXCEPTION '"%" table does not exist in the database.', n_table_name;
        RETURN;
    END IF;

    -- Check if table_id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_table_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"table_id" cannot be empty or null.';
        RETURN;
    END IF;
    -- -- Check if table_id exists within table
    -- IF (public.fn_field_unique_valid(n_table_name, 'id', CAST(n_table_id AS TEXT), NULL) = TRUE) THEN
    --     RAISE EXCEPTION 'id = % does not exist in the "%" table.', n_table_id, n_table_name;
    --     RETURN;
    -- END IF;
    
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Create new record in the table
    INSERT INTO general_history(
        table_name,
        table_id,
        description,
        reason,
        comment,
        modified_by,
        modified_at
    )
    VALUES (
        n_table_name,
        n_table_id,
        n_description,
        n_reason,
        n_comment,
        n_modified_by,
        CURRENT_TIMESTAMP
    );
END;
$$;
 �   DROP PROCEDURE public.proc_add_general_history(IN n_modified_by text, IN n_reason text, IN n_table_name text, IN n_table_id bigint, IN n_description text, IN n_comment text);
       public          michaelm    false    6            �           1255    17321 5   proc_add_type_history(text, text, bigint, text, text) 	   PROCEDURE     s	  CREATE PROCEDURE public.proc_add_type_history(IN n_modified_by text, IN n_reason text, IN n_type_id bigint, IN n_description text, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if type_id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_type_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"type_id" cannot be empty or null.';
        RETURN;
    END IF;
    -- -- Check if type_id exists within table
    -- IF (public.fn_field_unique_valid('equipment_type', 'id', CAST(n_type_id AS TEXT), NULL) = TRUE) THEN
    --     RAISE EXCEPTION 'id = % does not exist in the "equipment_type" table.', n_type_id;
    --     RETURN;
    -- END IF;
    
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Create new record into the table
    INSERT INTO type_history(
        type_id, 
        description, 
        reason, 
        comment, 
        modified_by, 
        modified_at
    )
    VALUES (
        n_type_id, 
        n_description, 
        n_reason, 
        n_comment, 
        n_modified_by, 
        CURRENT_TIMESTAMP
    );
END;
$$;
 �   DROP PROCEDURE public.proc_add_type_history(IN n_modified_by text, IN n_reason text, IN n_type_id bigint, IN n_description text, IN n_comment text);
       public          michaelm    false    6            �           1255    17322 (   proc_copy_connection(text, text, bigint) 	   PROCEDURE     r  CREATE PROCEDURE public.proc_copy_connection(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;
DECLARE item record;
DECLARE parent_path ltree;
DECLARE n_connection_id bigint;
DECLARE n_connection_commercial_id bigint;
DECLARE n_connection_state_id bigint;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if id exists within table
    IF (public.fn_field_unique_valid('connection', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection" table.', n_id;
        RETURN;
    END IF;

    -- Get parent_path from the table
    SELECT path INTO parent_path FROM connection WHERE id = n_id;

    -- Copy the record and its descendants records by id in connection table
    WITH RECURSIVE recursive_connection AS (
        -- Find the connection record and all of its childrens
        SELECT
            id, 
            path,
            use_parent_identifier,
            connection_type_id,
            start_equipment_id,
            start_interface_id,
            end_equipment_id,
            end_interface_id,
            identifier, 
            description, 
            comment, 
            length,
            is_approved, 
            modified_at, 
            subpath(path, 0, nlevel(path) - 1) || CAST(nextval('connection_id_seq') + 1 AS TEXT)::ltree AS new_path
        FROM connection
        WHERE id = n_id

        UNION ALL

        -- Recursively find the children of the current connection record and copy them too
        SELECT
            c.id, 
            c.path, 
            c.use_parent_identifier,
            c.connection_type_id,
            c.start_equipment_id,
            c.start_interface_id,
            c.end_equipment_id,
            c.end_interface_id,
            c.identifier, 
            c.description, 
            c.comment, 
            c.length,
            c.is_approved, 
            c.modified_at, 
            new_path || CAST(currval('connection_id_seq') + 1 AS TEXT)
        FROM connection c
        JOIN recursive_connection rc 
        ON c.path <@ rc.path AND nlevel(c.path) = nlevel(rc.path) + 1
    )
    -- Insert the copied connections into the table
    INSERT INTO connection (
        path, 
        origin_path,
        use_parent_identifier,
        connection_type_id,
        start_equipment_id,
        start_interface_id,
        end_equipment_id,
        end_interface_id, 
        identifier, 
        description, 
        comment, 
        length,
        is_approved, 
        modified_at
    )
    SELECT
        new_path,
        path,
        use_parent_identifier,
        connection_type_id,
        null,
        null,
        null,
        null, 
        identifier || '_copy', 
        description, 
        comment,
        length, 
        is_approved, 
        modified_at
    FROM recursive_connection;

    change_description = CONCAT('Copied connection(', n_id::text, ')');

    -- Create new record in connection_history table
    CALL public.proc_add_connection_history(
        n_modified_by,
        n_reason, 
        n_id, 
        change_description
    );

    -- Copy the record related with connection_id in tables
    FOR item IN SELECT id, path, origin_path FROM connection WHERE origin_path <@ parent_path LOOP
        n_connection_id = CAST(subpath(item.origin_path, -1) AS TEXT)::bigint;
        ---------------------------------------------------
        -- Check if connection_id exists within connection_commercial table
        IF (public.fn_field_unique_valid('connection_commercial', 'connection_id', CAST(n_connection_id AS TEXT), NULL) = FALSE) THEN
            -- Copy the record with connection_id in connection_commercial table
            INSERT INTO connection_commercial(
                connection_id, 
                quote_reference,
                quote_price,
                lead_time_days,
                purchase_order_date,
                purchase_order_reference,
                due_date,
                received_date,
                location,
                unique_code,
                installed_date,
                warranty_end_date,
                comment, 
                modified_at
            )
            SELECT 
                item.id, 
                quote_reference,
                quote_price,
                lead_time_days,
                purchase_order_date,
                purchase_order_reference,
                due_date,
                received_date,
                location,
                unique_code,
                installed_date,
                warranty_end_date,
                comment, 
                modified_at
            FROM connection_commercial
            WHERE connection_id = n_connection_id;

            -- Get inserted id in connection_commercial table
            SELECT MAX(id) INTO n_connection_commercial_id FROM connection_commercial;
            change_description = CONCAT('Copied connection_commercial(', n_connection_commercial_id::text, ')');
    
            -- Create new record in general_history table
            CALL public.proc_add_general_history(
            n_modified_by,
            n_reason, 
            'connection_commercial', 
            n_connection_commercial_id, 
            change_description
            );
        END IF;
        -----------------------------------------------------
        -- Check if connection_id exists within connection_state table
        IF (public.fn_field_unique_valid('connection_state', 'connection_id', CAST(n_connection_id AS TEXT), NULL) = FALSE) THEN
            -- Copy the record with connection_id in connection_state table
            INSERT INTO connection_state(
                connection_id, 
                possible_state_id,
                is_state,
                comment, 
                modified_at
            )
            SELECT 
                item.id, 
                possible_state_id,
                is_state,
                comment, 
                modified_at
            FROM connection_state
            WHERE connection_id = n_connection_id;

            -- Get inserted id in connection_state table
            SELECT MAX(id) INTO n_connection_state_id FROM connection_state;
            change_description = CONCAT('Copied connection_state(', n_connection_state_id::text, ')');
    
            -- Create new record in general_history table
            CALL public.proc_add_general_history(
            n_modified_by,
            n_reason, 
            'connection_state', 
            n_connection_state_id, 
            change_description
            );
        END IF;
    END LOOP;
END;
$$;
 e   DROP PROCEDURE public.proc_copy_connection(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17324 '   proc_copy_equipment(text, text, bigint) 	   PROCEDURE     �!  CREATE PROCEDURE public.proc_copy_equipment(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;
DECLARE item record;
DECLARE parent_path ltree;
DECLARE n_equipment_id bigint;
DECLARE n_equipment_commercial_id bigint;
DECLARE n_property_value_id bigint;
DECLARE n_equipment_state_id bigint;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if id exists within table
    IF (public.fn_field_unique_valid('equipment', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_id;
        RETURN;
    END IF;

    -- Get parent_path from the table
    SELECT path INTO parent_path FROM equipment WHERE id = n_id;

    -- Copy the record and its descendants records by id in equipment table
    WITH RECURSIVE recursive_equipment AS (
        -- Find the equipment record and all of its childrens
        SELECT
            id, 
            path,
            location_path,
            use_parent_identifier,
            type_id,
            identifier, 
            description, 
            comment, 
            is_approved, 
            modified_at, 
            subpath(path, 0, nlevel(path) - 1) || CAST(nextval('equipment_id_seq') + 1 AS TEXT)::ltree AS new_path
        FROM equipment
        WHERE id = n_id

        UNION ALL

        -- Recursively find the children of the current equipment record and copy them too
        SELECT
            e.id, 
            e.path, 
            e.location_path,
            e.use_parent_identifier,
            e.type_id,
            e.identifier, 
            e.description, 
            e.comment, 
            e.is_approved, 
            e.modified_at, 
            new_path || CAST(currval('equipment_id_seq') + 1 AS TEXT)
        FROM equipment e
        JOIN recursive_equipment re 
        ON e.path <@ re.path AND nlevel(e.path) = nlevel(re.path) + 1
    )
    -- Insert the copied equipments into the table
    INSERT INTO equipment (
        path, 
        origin_path,
        location_path,
        use_parent_identifier,
        type_id, 
        identifier, 
        description, 
        comment, 
        is_approved, 
        modified_at
    )
    SELECT
        new_path,
        path,
        location_path,
        use_parent_identifier,
        type_id, 
        identifier || '_copy', 
        description, 
        comment, 
        is_approved, 
        modified_at
    FROM recursive_equipment;

    change_description = CONCAT('Copied equipment(', n_id::text, ')');

    -- Create new record in equipment_history table
    CALL public.proc_add_equipment_history(
        n_modified_by,
        n_reason, 
        n_id, 
        change_description
    );

    -- Copy the record related with equipment_id in tables
    FOR item IN SELECT id, path, origin_path FROM equipment WHERE origin_path <@ parent_path LOOP
        n_equipment_id = CAST(subpath(item.origin_path, -1) AS TEXT)::bigint;
        ---------------------------------------------------
        -- Check if quipment_id exists within equipment_commercial table
        IF (public.fn_field_unique_valid('equipment_commercial', 'equipment_id', CAST(n_equipment_id AS TEXT), NULL) = FALSE) THEN
            -- Copy the record with equipment_id in equipment_commercial table
            INSERT INTO equipment_commercial(
                equipment_id, 
                quote_reference,
                quote_price,
                lead_time_days,
                purchase_order_date,
                purchase_order_reference,
                due_date,
                received_date,
                location,
                unique_code,
                installed_date,
                warranty_end_date,
                comment, 
                modified_at
            )
            SELECT 
                item.id, 
                quote_reference,
                quote_price,
                lead_time_days,
                purchase_order_date,
                purchase_order_reference,
                due_date,
                received_date,
                location,
                unique_code,
                installed_date,
                warranty_end_date,
                comment, 
                modified_at
            FROM equipment_commercial
            WHERE equipment_id = n_equipment_id;

            -- Get inserted id in equipment_commercial table
            SELECT MAX(id) INTO n_equipment_commercial_id FROM equipment_commercial;
            change_description = CONCAT('Copied equipment_commercial(', n_equipment_commercial_id::text, ')');
    
            -- Create new record in general_history table
            CALL public.proc_add_general_history(
            n_modified_by,
            n_reason, 
            'equipment_commercial', 
            n_equipment_commercial_id, 
            change_description
            );
        END IF;
        -----------------------------------------------------
        -- Check if equipment_id exists within property_value table
        IF (public.fn_field_unique_valid('property_value', 'equipment_id', CAST(n_equipment_id AS TEXT), NULL) = FALSE) THEN
            -- Copy the record with equipment_id in property_value table
            INSERT INTO property_value(
                equipment_id, 
                resource_property_id,
                value,
                datatype_id,
                comment, 
                modified_at
            )
            SELECT 
                item.id, 
                resource_property_id,
                value,
                datatype_id,
                comment, 
                modified_at
            FROM property_value
            WHERE equipment_id = n_equipment_id;

            -- Get inserted id in property_value table
            SELECT MAX(id) INTO n_property_value_id FROM property_value;
            change_description = CONCAT('Copied property_value(', n_property_value_id::text, ')');
    
            -- Create new record in general_history table
            CALL public.proc_add_general_history(
            n_modified_by,
            n_reason, 
            'property_value', 
            n_property_value_id, 
            change_description
            );
        END IF;
        -----------------------------------------------------
        -- Check if equipment_id exists within equipment_state table
        IF (public.fn_field_unique_valid('equipment_state', 'equipment_id', CAST(n_equipment_id AS TEXT), NULL) = FALSE) THEN
            -- Copy the record with equipment_id in equipment_state table
            INSERT INTO equipment_state(
                equipment_id, 
                possible_state_id,
                is_state,
                comment, 
                modified_at
            )
            SELECT 
                item.id, 
                possible_state_id,
                is_state,
                comment, 
                modified_at
            FROM equipment_state
            WHERE equipment_id = n_equipment_id;

            -- Get inserted id in equipment_state table
            SELECT MAX(id) INTO n_equipment_state_id FROM equipment_state;
            change_description = CONCAT('Copied equipment_state(', n_equipment_state_id::text, ')');
    
            -- Create new record in general_history table
            CALL public.proc_add_general_history(
            n_modified_by,
            n_reason, 
            'equipment_state', 
            n_equipment_state_id, 
            change_description
            );
        END IF;
    END LOOP;
END;
$$;
 d   DROP PROCEDURE public.proc_copy_equipment(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17326 ,   proc_copy_equipment_type(text, text, bigint) 	   PROCEDURE     �#  CREATE PROCEDURE public.proc_copy_equipment_type(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;
DECLARE item record;
DECLARE parent_path ltree;
DECLARE n_type_id bigint;
DECLARE n_type_detail_id bigint;
DECLARE n_type_resource_id bigint;
DECLARE resource_item record;
DECLARE n_type_interface_id bigint;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if id exists within table
    IF (public.fn_field_unique_valid('equipment_type', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment_type" table.', n_id;
        RETURN;
    END IF;

    -- Get parent_path from the table
    SELECT path INTO parent_path FROM equipment_type WHERE id = n_id;

    -- Copy the record and its descendants records by id in equipment_type table
    WITH RECURSIVE recursive_equipment_type AS (
        -- Find the equipment_type record and all of its childrens
        SELECT
            id, 
            path, 
            label, 
            modifier, 
            model, 
            manufacturer, 
            description, 
            comment, 
            is_approved, 
            modified_at, 
            subpath(path, 0, nlevel(path) - 1) || CAST(nextval('equipment_type_id_seq') + 1 AS TEXT)::ltree AS new_path
        FROM equipment_type
        WHERE id = n_id

        UNION ALL

        -- Recursively find the children of the current equipment_type record and copy them too
        SELECT
            et.id, 
            et.path, 
            et.label, 
            et.modifier, 
            et.model, 
            et.manufacturer, 
            et.description, 
            et.comment, 
            et.is_approved, 
            et.modified_at, 
            new_path || CAST(currval('equipment_type_id_seq') + 1 AS TEXT)
        FROM equipment_type et
        JOIN recursive_equipment_type ret 
        ON et.path <@ ret.path AND nlevel(et.path) = nlevel(ret.path) + 1
    )
    -- Insert the copied equipment types into the table
    INSERT INTO equipment_type (
        path, 
        origin_path, 
        label, 
        modifier, 
        model, 
        manufacturer, 
        description, 
        comment, 
        is_approved, 
        modified_at
    )
    SELECT
        new_path,
        path, 
        label || '_copy', 
        modifier, 
        model, 
        manufacturer, 
        description, 
        comment, 
        is_approved, 
        modified_at
    FROM recursive_equipment_type;

    change_description = CONCAT('Copied equipment_type(', n_id::text, ')');

    -- Create new record in type_history table
    CALL public.proc_add_type_history(
        n_modified_by,
        n_reason, 
        n_id, 
        change_description
    );

    -- Copy the record related with type_id in tables
    FOR item IN SELECT id, path, origin_path FROM equipment_type WHERE origin_path <@ parent_path LOOP
        n_type_id = CAST(subpath(item.origin_path, -1) AS TEXT)::bigint;
        ---------------------------------------------------
        -- Check if type_id exists within type_detail table
        IF (public.fn_field_unique_valid('type_detail', 'type_id', CAST(n_type_id AS TEXT), NULL) = FALSE) THEN
            -- Copy the record with type_id in type_detail table
            INSERT INTO type_detail(
                type_id, 
                width, 
                height, 
                depth, 
                top_clearance, 
                bottom_clearance,
                left_clearance,
                right_clearance,
                front_clearance,
                rear_clearance,
                installation_method,
                process_interface,
                control_interface,
                energy_supply,
                energy_use,
                comment, 
                modified_at
            )
            SELECT 
                item.id, 
                width, 
                height, 
                depth, 
                top_clearance, 
                bottom_clearance,
                left_clearance,
                right_clearance,
                front_clearance,
                rear_clearance,
                installation_method,
                process_interface,
                control_interface,
                energy_supply,
                energy_use,
                comment, 
                modified_at
            FROM type_detail
            WHERE type_id = n_type_id;

            -- Get inserted id in type_detail table
            SELECT MAX(id) INTO n_type_detail_id FROM type_detail;
            change_description = CONCAT('Copied type_detail(', n_type_detail_id::text, ')');
    
            -- Create new record in general_history table
            CALL public.proc_add_general_history(
            n_modified_by,
            n_reason, 
            'type_detail', 
            n_type_detail_id, 
            change_description
            );
        END IF;
        -----------------------------------------------------
        -- Check if type_id exists within type_resource table
        IF (public.fn_field_unique_valid('type_resource', 'type_id', CAST(n_type_id AS TEXT), NULL) = FALSE) THEN
            -- Copy the record with type_id in type_resource table
            FOR resource_item IN SELECT id, type_id, resource_id, comment, modified_at FROM type_resource WHERE type_id = n_type_id LOOP
                INSERT INTO type_resource(
                    type_id, 
                    resource_id, 
                    comment, 
                    modified_at
                )
                VALUES (
                    item.id,
                    resource_item.resource_id,
                    resource_item.comment,
                    resource_item.modified_at
                );

                -- Get inserted id in type_resource table
                SELECT MAX(id) INTO n_type_resource_id FROM type_resource;
                change_description = CONCAT('Copied type_resource(', n_type_resource_id::text, ')');
    
                -- Create new record in general_history table
                CALL public.proc_add_general_history(
                    n_modified_by,
                    n_reason, 
                    'type_resource', 
                    n_type_resource_id, 
                    change_description
                );
                -----------------------------------------------------
                -- Copy the record with type_resource_id in type_interface table
                -- Check if type_resource_id exists within type_interface table
                IF (public.fn_field_unique_valid('type_interface', 'type_resource_id', CAST(resource_item.id AS TEXT), NULL) = FALSE) THEN
                    -- Copy the record with type_resource_id in type_interface table
                    INSERT INTO type_interface(
                        type_resource_id, 
                        interface_id, 
                        comment, 
                        is_active,
                        modified_at
                    )
                    SELECT 
                        n_type_resource_id, 
                        interface_id, 
                        comment, 
                        is_active,
                        modified_at
                    FROM type_interface
                    WHERE type_resource_id = resource_item.id;

                    -- Get inserted id in type_interface table
                    SELECT MAX(id) INTO n_type_interface_id FROM type_interface;
                    change_description = CONCAT('Copied type_interface(', n_type_interface_id::text, ')');
            
                    -- Create new record in general_history table
                    CALL public.proc_add_general_history(
                    n_modified_by,
                    n_reason, 
                    'type_interface', 
                    n_type_interface_id, 
                    change_description
                    );
                END IF;
            END LOOP;
        END IF;
    END LOOP;
END;
$$;
 i   DROP PROCEDURE public.proc_copy_equipment_type(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17328 �   proc_modify_connection(text, text, text, bigint, public.ltree, bigint, bigint, bigint, bigint, bigint, text, double precision, text, boolean, boolean) 	   PROCEDURE     l'  CREATE PROCEDURE public.proc_modify_connection(IN n_modified_by text, IN n_reason text, IN n_identifier text, IN connection_id bigint DEFAULT NULL::bigint, IN n_path public.ltree DEFAULT NULL::public.ltree, IN n_connection_type_id bigint DEFAULT NULL::bigint, IN n_start_equipment_id bigint DEFAULT NULL::bigint, IN n_start_interface_id bigint DEFAULT NULL::bigint, IN n_end_equipment_id bigint DEFAULT NULL::bigint, IN n_end_interface_id bigint DEFAULT NULL::bigint, IN n_description text DEFAULT NULL::text, IN n_length double precision DEFAULT NULL::double precision, IN n_comment text DEFAULT NULL::text, IN n_use_parent_identifier boolean DEFAULT true, IN n_is_approved boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_path ltree;
DECLARE o_connection_type_id bigint;
DECLARE o_start_equipment_id bigint;
DECLARE o_start_interface_id bigint;
DECLARE o_end_equipment_id bigint;
DECLARE o_end_interface_id bigint;
DECLARE o_identifer text;
DECLARE o_description text;
DECLARE o_length float;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if connection_type_id is not empty or null and connection_type_id exists within table
    IF (public.fn_text_field_valid(CAST(n_connection_type_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('connection_type', 'id', CAST(n_connection_type_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection_type" table.', n_connection_type_id;
        RETURN;
    END IF;

    -- Check if start_equipment_id is not empty or null and start_equipment_id exists within table
    IF (public.fn_text_field_valid(CAST(n_start_equipment_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment', 'id', CAST(n_start_equipment_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_start_equipment_id;
        RETURN;
    END IF;

    -- Check if start_interface_id is not empty or null and start_interface_id exists within table
    IF (public.fn_text_field_valid(CAST(n_start_interface_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('interface', 'id', CAST(n_start_interface_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface" table.', n_start_interface_id;
        RETURN;
    END IF;

    -- Check if end_equipment_id is not empty or null and end_equipment_id exists within table
    IF (public.fn_text_field_valid(CAST(n_end_equipment_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment', 'id', CAST(n_end_equipment_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_end_equipment_id;
        RETURN;
    END IF;

    -- Check if end_interface_id is not empty or null and end_interface_id exists within table
    IF (public.fn_text_field_valid(CAST(n_end_interface_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('interface', 'id', CAST(n_end_interface_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface" table.', n_end_interface_id;
        RETURN;
    END IF;

    -- Check if identifier is not empty or null
    IF (public.fn_text_field_valid(n_identifier, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"identifier" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if identifier is greater than 5 characters
    IF (public.fn_text_field_valid(n_identifier, 'length') = FALSE) THEN
        RAISE EXCEPTION '"identifier" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(connection_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in connection table --->>>
        
        -- Create new record into the table
        INSERT INTO connection(
            path,
            use_parent_identifier,
            connection_type_id,
            start_equipment_id,
            start_interface_id,
            end_equipment_id,
            end_interface_id,
            identifier,
            description, 
            length,
            comment, 
            is_approved, 
            modified_at
        )
        VALUES (
            n_path,
            n_use_parent_identifier,
            n_connection_type_id,
            n_start_equipment_id,
            n_start_interface_id,
            n_end_equipment_id,
            n_end_interface_id,
            n_identifier,
            n_description, 
            n_length,
            n_comment, 
            n_is_approved, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added connection %s(%s)', n_identifier, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in connection table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('connection', 'id', CAST(connection_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "connection" table.', connection_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            path,
            connection_type_id,
            start_equipment_id,
            start_interface_id,
            end_equipment_id,
            end_interface_id,
            identifier,
            description, 
            length,
            comment 
        INTO 
            o_path,
            o_connection_type_id,
            o_start_equipment_id,
            o_start_interface_id,
            o_end_equipment_id,
            o_end_interface_id,
            o_identifer,
            o_description, 
            o_length,
            o_comment 
        FROM connection WHERE id = connection_id;

        UPDATE connection
        SET path = n_path,
            use_parent_identifier = n_use_parent_identifier,
            connection_type_id = n_connection_type_id,
            start_equipment_id = n_start_equipment_id,
            start_interface_id = n_start_interface_id,
            end_equipment_id = n_end_equipment_id,
            end_interface_id = n_end_interface_id,
            identifier = CASE WHEN n_identifier <> o_identifier THEN n_identifier ELSE identifier END,
            description = n_description,
            length = n_length,
            comment = n_comment,
            is_approved = n_is_approved,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = connection_id;
        
        n_table_id := connection_id;
        
        -- Make change_description content
        IF (n_path <> o_path) THEN
            change_description = CONCAT(change_description, 'path changed from "', o_path, '" to "', n_path, '", ');
        END IF;
        IF (n_connection_type_id <> o_connection_type_id) THEN
            change_description = CONCAT(change_description, 'connection_type_id changed from "', o_connection_type_id, '" to "', n_connection_type_id, '", ');
        END IF;
        IF (n_start_equipment_id <> o_start_equipment_id) THEN
            change_description = CONCAT(change_description, 'start_equipment_id changed from "', o_start_equipment_id, '" to "', n_start_equipment_id, '", ');
        END IF;
        IF (n_start_interface_id <> o_start_interface_id) THEN
            change_description = CONCAT(change_description, 'start_interface_id changed from "', o_start_interface_id, '" to "', n_start_interface_id, '", ');
        END IF;
        IF (n_end_equipment_id <> o_end_equipment_id) THEN
            change_description = CONCAT(change_description, 'end_equipment_id changed from "', o_end_equipment_id, '" to "', n_end_equipment_id, '", ');
        END IF;
        IF (n_end_interface_id <> o_end_interface_id) THEN
            change_description = CONCAT(change_description, 'end_interface_id changed from "', o_end_interface_id, '" to "', n_end_interface_id, '", ');
        END IF;
        IF (n_identifier <> o_identifer) THEN
            change_description = CONCAT(change_description, 'identifier changed from "', o_identifer, '" to "', n_identifier, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_length <> o_length) THEN
            change_description = CONCAT(change_description, 'length changed from "', o_length, '" to "', n_length, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated connection(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in connection_history table
    CALL public.proc_add_connection_history(
        n_modified_by,
        n_reason, 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �  DROP PROCEDURE public.proc_modify_connection(IN n_modified_by text, IN n_reason text, IN n_identifier text, IN connection_id bigint, IN n_path public.ltree, IN n_connection_type_id bigint, IN n_start_equipment_id bigint, IN n_start_interface_id bigint, IN n_end_equipment_id bigint, IN n_end_interface_id bigint, IN n_description text, IN n_length double precision, IN n_comment text, IN n_use_parent_identifier boolean, IN n_is_approved boolean);
       public          postgres    false    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6            �           1255    17330 �   proc_modify_connection_commercial(text, text, bigint, bigint, text, double precision, integer, date, text, date, date, text, text, date, date, text) 	   PROCEDURE     $  CREATE PROCEDURE public.proc_modify_connection_commercial(IN n_modified_by text, IN n_reason text, IN connection_commercial_id bigint DEFAULT NULL::bigint, IN n_connection_id bigint DEFAULT NULL::bigint, IN n_quote_reference text DEFAULT NULL::text, IN n_quote_price double precision DEFAULT NULL::double precision, IN n_lead_time_days integer DEFAULT NULL::integer, IN n_purchase_order_date date DEFAULT NULL::date, IN n_purchase_order_reference text DEFAULT NULL::text, IN n_due_date date DEFAULT NULL::date, IN n_received_date date DEFAULT NULL::date, IN n_location text DEFAULT NULL::text, IN n_unique_code text DEFAULT NULL::text, IN n_installed_date date DEFAULT NULL::date, IN n_warranty_end_date date DEFAULT NULL::date, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_connection_id bigint;
DECLARE o_quote_reference text;
DECLARE o_quote_price float;
DECLARE o_lead_time_days int;
DECLARE o_purchase_order_date date;
DECLARE o_purchase_order_reference text;
DECLARE o_due_date date;
DECLARE o_received_date date;
DECLARE o_location text;
DECLARE o_unique_code text;
DECLARE o_installed_date date;
DECLARE o_warranty_end_date date;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if connection_id is not empty or null and connection_id exists within table
    IF (public.fn_text_field_valid(CAST(n_connection_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('connection', 'id', CAST(n_connection_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection" table.', n_connection_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(connection_commercial_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in connection_commercial table --->>>
        
        -- Create new record into the table
        INSERT INTO connection_commercial(
            connection_id,
            quote_reference,
            quote_price,
            lead_time_days,
            purchase_order_date,
            purchase_order_reference,
            due_date,
            received_date,
            location,
            unique_code,
            installed_date,
            warranty_end_date,
            comment, 
            modified_at
        )
        VALUES (
            n_connection_id,
            n_quote_reference,
            n_quote_price,
            n_lead_time_days,
            n_purchase_order_date,
            n_purchase_order_reference,
            n_due_date,
            n_received_date,
            n_location,
            n_unique_code,
            n_installed_date,
            n_warranty_end_date,
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added connection commercial details');

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in connection_commercial table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('connection_commercial', 'id', CAST(connection_commercial_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "connection_commercial" table.', connection_commercial_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT
            connection_id,
            quote_reference,
            quote_price,
            lead_time_days,
            purchase_order_date,
            purchase_order_reference,
            due_date,
            received_date,
            location,
            unique_code,
            installed_date,
            warranty_end_date, 
            comment 
        INTO 
            o_connection_id,
            o_quote_reference,
            o_quote_price,
            o_lead_time_days,
            o_purchase_order_date,
            o_purchase_order_reference,
            o_due_date,
            o_received_date,
            o_location,
            o_unique_code,
            o_installed_date,
            o_warranty_end_date,
            o_comment 
        FROM connection_commercial WHERE id = connection_commercial_id;

        UPDATE connection_commercial
        SET connection_id = n_connection_id,
            quote_reference = n_quote_reference,
            quote_price = n_quote_price,
            lead_time_days = n_lead_time_days,
            purchase_order_date = n_purchase_order_date,
            purchase_order_reference = n_purchase_order_reference,
            due_date = n_due_date,
            received_date = n_received_date,
            location = n_location,
            unique_code = n_unique_code,
            installed_date = n_installed_date,
            warranty_end_date = n_warranty_end_date,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = connection_commercial_id;
        
        n_table_id := connection_commercial_id;
        
        -- Make change_description content
        IF (n_connection_id <> o_connection_id) THEN
            change_description = CONCAT(change_description, 'connection_id changed from "', o_connection_id, '" to "', n_connection_id, '", ');
        END IF;
        IF (n_quote_reference <> o_quote_reference) THEN
            change_description = CONCAT(change_description, 'quote_reference changed from "', o_quote_reference, '" to "', n_quote_reference, '", ');
        END IF;
        IF (n_quote_price <> o_quote_price) THEN
            change_description = CONCAT(change_description, 'quote_price changed from "', o_quote_price, '" to "', n_quote_price, '", ');
        END IF;
        IF (n_lead_time_days <> o_lead_time_days) THEN
            change_description = CONCAT(change_description, 'lead_time_days changed from "', o_lead_time_days, '" to "', n_lead_time_days, '", ');
        END IF;
        IF (n_purchase_order_date <> o_purchase_order_date) THEN
            change_description = CONCAT(change_description, 'purchase_order_date changed from "', o_purchase_order_date, '" to "', n_purchase_order_date, '", ');
        END IF;
        IF (n_purchase_order_reference <> o_purchase_order_reference) THEN
            change_description = CONCAT(change_description, 'purchase_order_reference changed from "', o_purchase_order_reference, '" to "', n_purchase_order_reference, '", ');
        END IF;
        IF (n_due_date <> o_due_date) THEN
            change_description = CONCAT(change_description, 'due_date changed from "', o_due_date, '" to "', n_due_date, '", ');
        END IF;
        IF (n_received_date <> o_received_date) THEN
            change_description = CONCAT(change_description, 'received_date changed from "', o_received_date, '" to "', n_received_date, '", ');
        END IF;
        IF (n_location <> o_location) THEN
            change_description = CONCAT(change_description, 'location changed from "', o_location, '" to "', n_location, '", ');
        END IF;
        IF (n_unique_code <> o_unique_code) THEN
            change_description = CONCAT(change_description, 'unique_code changed from "', o_unique_code, '" to "', n_unique_code, '", ');
        END IF;
        IF (n_installed_date <> o_installed_date) THEN
            change_description = CONCAT(change_description, 'installed_date changed from "', o_installed_date, '" to "', n_installed_date, '", ');
        END IF;
        IF (n_warranty_end_date <> o_warranty_end_date) THEN
            change_description = CONCAT(change_description, 'warranty_end_date changed from "', o_warranty_end_date, '" to "', n_warranty_end_date, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated connection commercial details(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason,
        'connection_commercial',
        n_table_id, 
        change_description, 
        n_comment 
    );
END;
$$;
 �  DROP PROCEDURE public.proc_modify_connection_commercial(IN n_modified_by text, IN n_reason text, IN connection_commercial_id bigint, IN n_connection_id bigint, IN n_quote_reference text, IN n_quote_price double precision, IN n_lead_time_days integer, IN n_purchase_order_date date, IN n_purchase_order_reference text, IN n_due_date date, IN n_received_date date, IN n_location text, IN n_unique_code text, IN n_installed_date date, IN n_warranty_end_date date, IN n_comment text);
       public          michaelm    false    6            �           1255    17333 O   proc_modify_connection_state(text, text, bigint, bigint, bigint, text, boolean) 	   PROCEDURE     M  CREATE PROCEDURE public.proc_modify_connection_state(IN n_modified_by text, IN n_reason text, IN connection_state_id bigint DEFAULT NULL::bigint, IN n_connection_id bigint DEFAULT NULL::bigint, IN n_possible_state_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text, IN n_is_state boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_connection_id bigint;
DECLARE o_possible_state_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if connection_id is not empty or null and connection_id exists within table
    IF (public.fn_text_field_valid(CAST(n_connection_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('connection', 'id', CAST(n_connection_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection" table.', n_connection_id;
        RETURN;
    END IF;

    -- Check if possible_state_id is not empty or null and possible_state_id exists within table
    IF (public.fn_text_field_valid(CAST(n_possible_state_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('possible_state', 'id', CAST(n_possible_state_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "possible_state" table.', n_possible_state_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(connection_state_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in connection_state table --->>>

        -- Create new record into the table
        INSERT INTO connection_state(
            connection_id,
            possible_state_id, 
            comment, 
            is_state, 
            modified_at
        )
        VALUES (
            n_connection_id,
            n_possible_state_id,
            n_comment, 
            n_is_state, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added connection state (%s)(%s)', n_connection_id, n_possible_state_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in connection_state table --->>>

        -- Check if id exists within connection_state table
        IF (public.fn_field_unique_valid('connection_state', 'id', CAST(connection_state_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "connection_state" table.', connection_state_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            connection_id,
            possible_state_id,
            comment 
        INTO 
            o_connection_id,
            o_possible_state_id,
            o_comment 
        FROM connection_state WHERE id = connection_state_id;

        -- Update current record with the information
        UPDATE connection_state
        SET connection_id = n_connection_id,
            possible_state_id = n_possible_state_id,
            comment = n_comment,
            is_state = n_is_state,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = connection_state_id;

        n_table_id := connection_state_id;

        -- Make change_description content
        IF (n_connection_id <> o_connection_id) THEN
            change_description = CONCAT(change_description, 'connection_id changed from "', o_connection_id, '" to "', n_connection_id, '", ');
        END IF;
        IF (n_possible_state_id <> o_possible_state_id) THEN
            change_description = CONCAT(change_description, 'possible_state_id changed from "', o_possible_state_id, '" to "', n_possible_state_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated connection state(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason,
        'connection_state',
        n_table_id, 
        change_description, 
        n_comment 
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_connection_state(IN n_modified_by text, IN n_reason text, IN connection_state_id bigint, IN n_connection_id bigint, IN n_possible_state_id bigint, IN n_comment text, IN n_is_state boolean);
       public          michaelm    false    6            �           1255    17334 j   proc_modify_connection_type(text, text, text, text, bigint, public.ltree, text, text, text, text, boolean) 	   PROCEDURE       CREATE PROCEDURE public.proc_modify_connection_type(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN connection_type_id bigint DEFAULT NULL::bigint, IN n_path public.ltree DEFAULT NULL::public.ltree, IN n_modifier text DEFAULT NULL::text, IN n_model text DEFAULT NULL::text, IN n_manufacturer text DEFAULT NULL::text, IN n_comment text DEFAULT NULL::text, IN n_is_approved boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_path ltree;
DECLARE o_label text;
DECLARE o_modifier text;
DECLARE o_model text;
DECLARE o_manufacturer text;
DECLARE o_description text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if label is not empty or null
    IF (public.fn_text_field_valid(n_label, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"label" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(connection_type_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in equipment_type table --->>>
        
        -- Check if label is unique in the table
        IF (public.fn_field_unique_valid('connection_type', 'label', n_label, connection_type_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Create new record into the table
        INSERT INTO connection_type(
            path,
            label,
            modifier,
            model,
            manufacturer, 
            description, 
            comment, 
            is_approved, 
            modified_at
        )
        VALUES (
            n_path,
            n_label,
            n_modifier,
            n_model,
            n_manufacturer, 
            n_description, 
            n_comment, 
            n_is_approved, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added connection type %s(%s)', n_label, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in equipment_type table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('connection_type', 'id', CAST(connection_type_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "connection_type" table.', connection_type_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            path,
            label,
            modifier,
            model,
            manufacturer, 
            description, 
            comment 
        INTO 
            o_path,
            o_label,
            o_modifier,
            o_model,
            o_manufacturer, 
            o_description, 
            o_comment 
        FROM connection_type WHERE id = connection_type_id;

        -- Check if label is unique in the table
        IF (n_label <> o_label AND public.fn_field_unique_valid('connection_type', 'label', n_label, connection_type_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        UPDATE connection_type
        SET path = n_path,
            label = CASE WHEN n_label <> o_label THEN n_label ELSE label END,
            modifier = n_modifier,
            model = n_model,
            manufacturer = n_manufacturer,
            description = CASE WHEN n_description <> o_description THEN n_description ELSE description END,
            comment = n_comment,
            is_approved = n_is_approved,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = connection_type_id;
        
        n_table_id := connection_type_id;
        
        -- Make change_description content
        IF (n_path <> o_path) THEN
            change_description = CONCAT(change_description, 'path changed from "', o_path, '" to "', n_path, '", ');
        END IF;
        IF (n_label <> o_label) THEN
            change_description = CONCAT(change_description, 'label changed from "', o_label, '" to "', n_label, '", ');
        END IF;
        IF (n_modifier <> o_modifier) THEN
            change_description = CONCAT(change_description, 'modifier changed from "', o_modifier, '" to "', n_modifier, '", ');
        END IF;
        IF (n_model <> o_model) THEN
            change_description = CONCAT(change_description, 'model changed from "', o_model, '" to "', n_model, '", ');
        END IF;
        IF (n_manufacturer <> o_manufacturer) THEN
            change_description = CONCAT(change_description, 'manufacturer changed from "', o_manufacturer, '" to "', n_manufacturer, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated connection type(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'connection_type',
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 $  DROP PROCEDURE public.proc_modify_connection_type(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN connection_type_id bigint, IN n_path public.ltree, IN n_modifier text, IN n_model text, IN n_manufacturer text, IN n_comment text, IN n_is_approved boolean);
       public          michaelm    false    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6            �           1255    17337 p   proc_modify_datatype(text, text, text, bigint, text, text, text, text, text, text, text, text, text, text, text) 	   PROCEDURE     b  CREATE PROCEDURE public.proc_modify_datatype(IN n_modified_by text, IN n_reason text, IN n_label text, IN datatype_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text, IN n_scada_1 text DEFAULT NULL::text, IN n_scada_2 text DEFAULT NULL::text, IN n_scada_3 text DEFAULT NULL::text, IN n_scada_4 text DEFAULT NULL::text, IN n_scada_5 text DEFAULT NULL::text, IN n_control_1 text DEFAULT NULL::text, IN n_control_2 text DEFAULT NULL::text, IN n_control_3 text DEFAULT NULL::text, IN n_control_4 text DEFAULT NULL::text, IN n_control_5 text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_label text;
DECLARE o_scada_1 text;
DECLARE o_scada_2 text;
DECLARE o_scada_3 text;
DECLARE o_scada_4 text;
DECLARE o_scada_5 text;
DECLARE o_control_1 text;
DECLARE o_control_2 text;
DECLARE o_control_3 text;
DECLARE o_control_4 text;
DECLARE o_control_5 text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if label is not empty or null
    IF (public.fn_text_field_valid(n_label, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"label" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(datatype_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in datatype table --->>>

        -- Check if label is unique in the table
        IF (public.fn_field_unique_valid('datatype', 'label', n_label, datatype_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Create new record into the table
        INSERT INTO datatype(
            label, 
            scada_1, 
            scada_2, 
            scada_3, 
            scada_4, 
            scada_5, 
            control_1, 
            control_2, 
            control_3, 
            control_4, 
            control_5, 
            comment, 
            modified_at
        )
        VALUES (
            n_label, 
            n_scada_1, 
            n_scada_2, 
            n_scada_3, 
            n_scada_4, 
            n_scada_5, 
            n_control_1, 
            n_control_2, 
            n_control_3, 
            n_control_4, 
            n_control_5, 
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Created datatype %s', n_label);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in datatype table --->>>

        -- Check if id exists within table
        IF (public.fn_field_unique_valid('datatype', 'id', CAST(datatype_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "datatype" table.', datatype_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            label,
            scada_1,
            scada_2,
            scada_3,
            scada_4,
            scada_5,
            control_1,
            control_2,
            control_3,
            control_4,
            control_5,
            comment
        INTO 
            o_label,
            o_scada_1,
            o_scada_2,
            o_scada_3,
            o_scada_4,
            o_scada_5,
            o_control_1,
            o_control_2,
            o_control_3,
            o_control_4,
            o_control_5,
            o_comment
        FROM datatype WHERE id = datatype_id;

        -- Check if label is unique in the table
        IF (n_label <> o_label AND public.fn_field_unique_valid('datatype', 'label', n_label, datatype_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Update the record with the information
        UPDATE datatype
        SET label = CASE WHEN n_label <> o_label THEN n_label ELSE label END,
            scada_1 = n_scada_1,
            scada_2 = n_scada_2,
            scada_3 = n_scada_3,
            scada_4 = n_scada_4,
            scada_5 = n_scada_5,
            control_1 = n_control_1,
            control_2 = n_control_2,
            control_3 = n_control_3,
            control_4 = n_control_4,
            control_5 = n_control_5,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = datatype_id;

        n_table_id := datatype_id;

        -- Make change_description content
        IF (n_label <> o_label) THEN
            change_description = CONCAT(change_description, 'label changed from "', o_label, '" to "', n_label, '", ');
        END IF;
        IF (n_scada_1 <> o_scada_1) THEN
            change_description = CONCAT(change_description, 'scada_1 changed from "', o_scada_1, '" to "', n_scada_1, '", ');
        END IF;
        IF (n_scada_2 <> o_scada_2) THEN
            change_description = CONCAT(change_description, 'scada_2 changed from "', o_scada_2, '" to "', n_scada_2, '", ');
        END IF;
        IF (n_scada_3 <> o_scada_3) THEN
            change_description = CONCAT(change_description, 'scada_3 changed from "', o_scada_3, '" to "', n_scada_3, '", ');
        END IF;
        IF (n_scada_4 <> o_scada_4) THEN
            change_description = CONCAT(change_description, 'scada_4 changed from "', o_scada_4, '" to "', n_scada_4, '", ');
        END IF;
        IF (n_scada_5 <> o_scada_5) THEN
            change_description = CONCAT(change_description, 'scada_5 changed from "', o_scada_5, '" to "', n_scada_5, '", ');
        END IF;
        IF (n_control_1 <> o_control_1) THEN
            change_description = CONCAT(change_description, 'control_1 changed from "', o_control_1, '" to "', n_control_1, '", ');
        END IF;
        IF (n_control_2 <> o_control_2) THEN
            change_description = CONCAT(change_description, 'control_2 changed from "', o_control_2, '" to "', n_control_2, '", ');
        END IF;
        IF (n_control_3 <> o_control_3) THEN
            change_description = CONCAT(change_description, 'control_3 changed from "', o_control_3, '" to "', n_control_3, '", ');
        END IF;
        IF (n_control_4 <> o_control_4) THEN
            change_description = CONCAT(change_description, 'control_4 changed from "', o_control_4, '" to "', n_control_4, '", ');
        END IF;
        IF (n_control_5 <> o_control_5) THEN
            change_description = CONCAT(change_description, 'control_5 changed from "', o_control_5, '" to "', n_control_5, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated datatype(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'datatype', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 X  DROP PROCEDURE public.proc_modify_datatype(IN n_modified_by text, IN n_reason text, IN n_label text, IN datatype_id bigint, IN n_comment text, IN n_scada_1 text, IN n_scada_2 text, IN n_scada_3 text, IN n_scada_4 text, IN n_scada_5 text, IN n_control_1 text, IN n_control_2 text, IN n_control_3 text, IN n_control_4 text, IN n_control_5 text);
       public          michaelm    false    6            �           1255    17340 q   proc_modify_equipment(text, text, text, bigint, public.ltree, public.ltree, bigint, text, text, boolean, boolean) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_modify_equipment(IN n_modified_by text, IN n_reason text, IN n_identifier text, IN equipment_id bigint DEFAULT NULL::bigint, IN n_path public.ltree DEFAULT NULL::public.ltree, IN n_location_path public.ltree DEFAULT NULL::public.ltree, IN n_type_id bigint DEFAULT NULL::bigint, IN n_description text DEFAULT NULL::text, IN n_comment text DEFAULT NULL::text, IN n_use_parent_identifier boolean DEFAULT true, IN n_is_approved boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_path ltree;
DECLARE o_location_path ltree;
DECLARE o_type_id bigint;
DECLARE o_identifer text;
DECLARE o_description text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if type_id is not empty or null and type_id exists within table
    IF (public.fn_text_field_valid(CAST(n_type_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment_type', 'id', CAST(n_type_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment_type" table.', n_type_id;
        RETURN;
    END IF;

    -- Check if identifier is not empty or null
    IF (public.fn_text_field_valid(n_identifier, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"identifier" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if identifier is greater than 5 characters
    IF (public.fn_text_field_valid(n_identifier, 'length') = FALSE) THEN
        RAISE EXCEPTION '"identifier" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(equipment_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in equipment table --->>>
        
        -- Create new record into the table
        INSERT INTO equipment(
            path,
            use_parent_identifier,
            location_path,
            type_id,
            identifier,
            description, 
            comment, 
            is_approved, 
            modified_at
        )
        VALUES (
            n_path,
            n_use_parent_identifier,
            n_location_path,
            n_type_id,
            n_identifier,
            n_description, 
            n_comment, 
            n_is_approved, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added equipment %s(%s)', n_identifier, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in equipment table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('equipment', 'id', CAST(equipment_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', equipment_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            path,
            location_path,
            type_id,
            identifier,
            description, 
            comment 
        INTO 
            o_path,
            o_location_path,
            o_type_id,
            o_identifer,
            o_description, 
            o_comment 
        FROM equipment WHERE id = equipment_id;

        UPDATE equipment
        SET path = n_path,
            use_parent_identifier = n_use_parent_identifier,
            location_path = n_location_path,
            type_id = n_type_id,
            identifier = CASE WHEN n_identifier <> o_identifier THEN n_identifier ELSE identifier END,
            description = n_description,
            comment = n_comment,
            is_approved = n_is_approved,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = equipment_id;
        
        n_table_id := equipment_id;
        
        -- Make change_description content
        IF (n_path <> o_path) THEN
            change_description = CONCAT(change_description, 'path changed from "', o_path, '" to "', n_path, '", ');
        END IF;
        IF (n_location_path <> o_location_path) THEN
            change_description = CONCAT(change_description, 'location_path changed from "', o_location_path, '" to "', n_location_path, '", ');
        END IF;
        IF (n_type_id <> o_type_id) THEN
            change_description = CONCAT(change_description, 'type_id changed from "', o_type_id, '" to "', n_type_id, '", ');
        END IF;
        IF (n_identifier <> o_identifer) THEN
            change_description = CONCAT(change_description, 'identifier changed from "', o_identifer, '" to "', n_identifier, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated equipment(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in equipment_history table
    CALL public.proc_add_equipment_history(
        n_modified_by,
        n_reason, 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 :  DROP PROCEDURE public.proc_modify_equipment(IN n_modified_by text, IN n_reason text, IN n_identifier text, IN equipment_id bigint, IN n_path public.ltree, IN n_location_path public.ltree, IN n_type_id bigint, IN n_description text, IN n_comment text, IN n_use_parent_identifier boolean, IN n_is_approved boolean);
       public          postgres    false    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            �           1255    17342 �   proc_modify_equipment_commercial(text, text, bigint, bigint, text, double precision, integer, date, text, date, date, text, text, date, date, text) 	   PROCEDURE     �#  CREATE PROCEDURE public.proc_modify_equipment_commercial(IN n_modified_by text, IN n_reason text, IN equipment_commercial_id bigint DEFAULT NULL::bigint, IN n_equipment_id bigint DEFAULT NULL::bigint, IN n_quote_reference text DEFAULT NULL::text, IN n_quote_price double precision DEFAULT NULL::double precision, IN n_lead_time_days integer DEFAULT NULL::integer, IN n_purchase_order_date date DEFAULT NULL::date, IN n_purchase_order_reference text DEFAULT NULL::text, IN n_due_date date DEFAULT NULL::date, IN n_received_date date DEFAULT NULL::date, IN n_location text DEFAULT NULL::text, IN n_unique_code text DEFAULT NULL::text, IN n_installed_date date DEFAULT NULL::date, IN n_warranty_end_date date DEFAULT NULL::date, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_equipment_id bigint;
DECLARE o_quote_reference text;
DECLARE o_quote_price float;
DECLARE o_lead_time_days int;
DECLARE o_purchase_order_date date;
DECLARE o_purchase_order_reference text;
DECLARE o_due_date date;
DECLARE o_received_date date;
DECLARE o_location text;
DECLARE o_unique_code text;
DECLARE o_installed_date date;
DECLARE o_warranty_end_date date;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if equipment_id is not empty or null and equipment_id exists within table
    IF (public.fn_text_field_valid(CAST(n_equipment_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment', 'id', CAST(n_equipment_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_equipment_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(equipment_commercial_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in equipment_commercial table --->>>
        
        -- Create new record into the table
        INSERT INTO equipment_commercial(
            equipment_id,
            quote_reference,
            quote_price,
            lead_time_days,
            purchase_order_date,
            purchase_order_reference,
            due_date,
            received_date,
            location,
            unique_code,
            installed_date,
            warranty_end_date,
            comment, 
            modified_at
        )
        VALUES (
            n_equipment_id,
            n_quote_reference,
            n_quote_price,
            n_lead_time_days,
            n_purchase_order_date,
            n_purchase_order_reference,
            n_due_date,
            n_received_date,
            n_location,
            n_unique_code,
            n_installed_date,
            n_warranty_end_date,
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added equipment commercial details');

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in equipment_commercial table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('equipment_commercial', 'id', CAST(equipment_commercial_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "equipment_commercial" table.', equipment_commercial_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT
            equipment_id,
            quote_reference,
            quote_price,
            lead_time_days,
            purchase_order_date,
            purchase_order_reference,
            due_date,
            received_date,
            location,
            unique_code,
            installed_date,
            warranty_end_date, 
            comment 
        INTO 
            o_equipment_id,
            o_quote_reference,
            o_quote_price,
            o_lead_time_days,
            o_purchase_order_date,
            o_purchase_order_reference,
            o_due_date,
            o_received_date,
            o_location,
            o_unique_code,
            o_installed_date,
            o_warranty_end_date,
            o_comment 
        FROM equipment_commercial WHERE id = equipment_commercial_id;

        UPDATE equipment_commercial
        SET equipment_id = n_equipment_id,
            quote_reference = n_quote_reference,
            quote_price = n_quote_price,
            lead_time_days = n_lead_time_days,
            purchase_order_date = n_purchase_order_date,
            purchase_order_reference = n_purchase_order_reference,
            due_date = n_due_date,
            received_date = n_received_date,
            location = n_location,
            unique_code = n_unique_code,
            installed_date = n_installed_date,
            warranty_end_date = n_warranty_end_date,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = equipment_commercial_id;
        
        n_table_id := equipment_commercial_id;
        
        -- Make change_description content
        IF (n_equipment_id <> o_equipment_id) THEN
            change_description = CONCAT(change_description, 'equipment_id changed from "', o_equipment_id, '" to "', n_equipment_id, '", ');
        END IF;
        IF (n_quote_reference <> o_quote_reference) THEN
            change_description = CONCAT(change_description, 'quote_reference changed from "', o_quote_reference, '" to "', n_quote_reference, '", ');
        END IF;
        IF (n_quote_price <> o_quote_price) THEN
            change_description = CONCAT(change_description, 'quote_price changed from "', o_quote_price, '" to "', n_quote_price, '", ');
        END IF;
        IF (n_lead_time_days <> o_lead_time_days) THEN
            change_description = CONCAT(change_description, 'lead_time_days changed from "', o_lead_time_days, '" to "', n_lead_time_days, '", ');
        END IF;
        IF (n_purchase_order_date <> o_purchase_order_date) THEN
            change_description = CONCAT(change_description, 'purchase_order_date changed from "', o_purchase_order_date, '" to "', n_purchase_order_date, '", ');
        END IF;
        IF (n_purchase_order_reference <> o_purchase_order_reference) THEN
            change_description = CONCAT(change_description, 'purchase_order_reference changed from "', o_purchase_order_reference, '" to "', n_purchase_order_reference, '", ');
        END IF;
        IF (n_due_date <> o_due_date) THEN
            change_description = CONCAT(change_description, 'due_date changed from "', o_due_date, '" to "', n_due_date, '", ');
        END IF;
        IF (n_received_date <> o_received_date) THEN
            change_description = CONCAT(change_description, 'received_date changed from "', o_received_date, '" to "', n_received_date, '", ');
        END IF;
        IF (n_location <> o_location) THEN
            change_description = CONCAT(change_description, 'location changed from "', o_location, '" to "', n_location, '", ');
        END IF;
        IF (n_unique_code <> o_unique_code) THEN
            change_description = CONCAT(change_description, 'unique_code changed from "', o_unique_code, '" to "', n_unique_code, '", ');
        END IF;
        IF (n_installed_date <> o_installed_date) THEN
            change_description = CONCAT(change_description, 'installed_date changed from "', o_installed_date, '" to "', n_installed_date, '", ');
        END IF;
        IF (n_warranty_end_date <> o_warranty_end_date) THEN
            change_description = CONCAT(change_description, 'warranty_end_date changed from "', o_warranty_end_date, '" to "', n_warranty_end_date, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated equipment commercial details(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason,
        'equipment_commercial',
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �  DROP PROCEDURE public.proc_modify_equipment_commercial(IN n_modified_by text, IN n_reason text, IN equipment_commercial_id bigint, IN n_equipment_id bigint, IN n_quote_reference text, IN n_quote_price double precision, IN n_lead_time_days integer, IN n_purchase_order_date date, IN n_purchase_order_reference text, IN n_due_date date, IN n_received_date date, IN n_location text, IN n_unique_code text, IN n_installed_date date, IN n_warranty_end_date date, IN n_comment text);
       public          michaelm    false    6            �           1255    17345 N   proc_modify_equipment_state(text, text, bigint, bigint, bigint, text, boolean) 	   PROCEDURE     $  CREATE PROCEDURE public.proc_modify_equipment_state(IN n_modified_by text, IN n_reason text, IN equipment_state_id bigint DEFAULT NULL::bigint, IN n_equipment_id bigint DEFAULT NULL::bigint, IN n_possible_state_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text, IN n_is_state boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_equipment_id bigint;
DECLARE o_possible_state_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if equipment_id is not empty or null and equipment_id exists within table
    IF (public.fn_text_field_valid(CAST(n_equipment_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment', 'id', CAST(n_equipment_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_equipment_id;
        RETURN;
    END IF;

    -- Check if possible_state_id is not empty or null and possible_state_id exists within table
    IF (public.fn_text_field_valid(CAST(n_possible_state_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('possible_state', 'id', CAST(n_possible_state_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "possible_state" table.', n_possible_state_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(equipment_state_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in equipment_state table --->>>

        -- Create new record into the table
        INSERT INTO equipment_state(
            equipment_id,
            possible_state_id, 
            comment, 
            is_state, 
            modified_at
        )
        VALUES (
            n_equipment_id,
            n_possible_state_id,
            n_comment, 
            n_is_state, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added equipment state (%s)(%s)', n_equipment_id, n_possible_state_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in equipment_state table --->>>

        -- Check if id exists within equipment_state table
        IF (public.fn_field_unique_valid('equipment_state', 'id', CAST(equipment_state_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "equipment_state" table.', equipment_state_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            equipment_id,
            possible_state_id,
            comment 
        INTO 
            o_equipment_id,
            o_possible_state_id,
            o_comment 
        FROM equipment_state WHERE id = equipment_state_id;

        -- Update current record with the information
        UPDATE equipment_state
        SET equipment_id = n_equipment_id,
            possible_state_id = n_possible_state_id,
            comment = n_comment,
            is_state = n_is_state,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = equipment_state_id;

        n_table_id := equipment_state_id;

        -- Make change_description content
        IF (n_equipment_id <> o_equipment_id) THEN
            change_description = CONCAT(change_description, 'equipment_id changed from "', o_equipment_id, '" to "', n_equipment_id, '", ');
        END IF;
        IF (n_possible_state_id <> o_possible_state_id) THEN
            change_description = CONCAT(change_description, 'possible_state_id changed from "', o_possible_state_id, '" to "', n_possible_state_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated equipment state(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason,
        'equipment_state',
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_equipment_state(IN n_modified_by text, IN n_reason text, IN equipment_state_id bigint, IN n_equipment_id bigint, IN n_possible_state_id bigint, IN n_comment text, IN n_is_state boolean);
       public          michaelm    false    6            �           1255    17346 i   proc_modify_equipment_type(text, text, text, text, bigint, public.ltree, text, text, text, text, boolean) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_modify_equipment_type(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN equipment_type_id bigint DEFAULT NULL::bigint, IN n_path public.ltree DEFAULT NULL::public.ltree, IN n_modifier text DEFAULT NULL::text, IN n_model text DEFAULT NULL::text, IN n_manufacturer text DEFAULT NULL::text, IN n_comment text DEFAULT NULL::text, IN n_is_approved boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_path ltree;
DECLARE o_label text;
DECLARE o_modifier text;
DECLARE o_model text;
DECLARE o_manufacturer text;
DECLARE o_description text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if label is not empty or null
    IF (public.fn_text_field_valid(n_label, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"label" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(equipment_type_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in equipment_type table --->>>
        
        -- Check if label is unique in the table
        IF (public.fn_field_unique_valid('equipment_type', 'label', n_label, equipment_type_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Create new record into the table
        INSERT INTO equipment_type(
            path,
            label,
            modifier,
            model,
            manufacturer, 
            description, 
            comment, 
            is_approved, 
            modified_at
        )
        VALUES (
            n_path,
            n_label,
            n_modifier,
            n_model,
            n_manufacturer, 
            n_description, 
            n_comment, 
            n_is_approved, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added equipment type %s(%s)', n_label, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in equipment_type table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('equipment_type', 'id', CAST(equipment_type_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "equipment_type" table.', equipment_type_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            path,
            label,
            modifier,
            model,
            manufacturer, 
            description, 
            comment 
        INTO 
            o_path,
            o_label,
            o_modifier,
            o_model,
            o_manufacturer, 
            o_description, 
            o_comment 
        FROM equipment_type WHERE id = equipment_type_id;

        -- Check if label is unique in the table
        IF (n_label <> o_label AND public.fn_field_unique_valid('equipment_type', 'label', n_label, equipment_type_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        UPDATE equipment_type
        SET path = n_path,
            label = CASE WHEN n_label <> o_label THEN n_label ELSE label END,
            modifier = n_modifier,
            model = n_model,
            manufacturer = n_manufacturer,
            description = CASE WHEN n_description <> o_description THEN n_description ELSE description END,
            comment = n_comment,
            is_approved = n_is_approved,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = equipment_type_id;
        
        n_table_id := equipment_type_id;
        
        -- Make change_description content
        IF (n_path <> o_path) THEN
            change_description = CONCAT(change_description, 'path changed from "', o_path, '" to "', n_path, '", ');
        END IF;
        IF (n_label <> o_label) THEN
            change_description = CONCAT(change_description, 'label changed from "', o_label, '" to "', n_label, '", ');
        END IF;
        IF (n_modifier <> o_modifier) THEN
            change_description = CONCAT(change_description, 'modifier changed from "', o_modifier, '" to "', n_modifier, '", ');
        END IF;
        IF (n_model <> o_model) THEN
            change_description = CONCAT(change_description, 'model changed from "', o_model, '" to "', n_model, '", ');
        END IF;
        IF (n_manufacturer <> o_manufacturer) THEN
            change_description = CONCAT(change_description, 'manufacturer changed from "', o_manufacturer, '" to "', n_manufacturer, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated equipment type(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in type_history table
    CALL public.proc_add_type_history(
        n_modified_by,
        n_reason, 
        n_table_id, 
        change_description, 
        n_comment 
    );
END;
$$;
 "  DROP PROCEDURE public.proc_modify_equipment_type(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN equipment_type_id bigint, IN n_path public.ltree, IN n_modifier text, IN n_model text, IN n_manufacturer text, IN n_comment text, IN n_is_approved boolean);
       public          michaelm    false    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6            �           1255    17349 T   proc_modify_interface(text, text, text, bigint, bigint, bigint, text, text, boolean) 	   PROCEDURE     J  CREATE PROCEDURE public.proc_modify_interface(IN n_modified_by text, IN n_reason text, IN n_identifier text, IN interface_id bigint DEFAULT NULL::bigint, IN n_interface_class_id bigint DEFAULT NULL::bigint, IN n_connecting_interface_class_id bigint DEFAULT NULL::bigint, IN n_description text DEFAULT NULL::text, IN n_comment text DEFAULT NULL::text, IN n_is_intermediate boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_interface_class_id bigint;
DECLARE o_connecting_interface_class_id bigint;
DECLARE o_identifier text;
DECLARE o_description text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if identifier is not empty or null
    IF (public.fn_text_field_valid(n_identifier, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"identifier" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if identifier is greater than 5 characters
    IF (public.fn_text_field_valid(n_identifier, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"identifier" cannot be less than 5 characters.';
        RETURN;
    END IF;
    
    -- Check if interface_class_id is not empty or null and interface_class_id exists within table
    IF (public.fn_text_field_valid(CAST(n_interface_class_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('interface_class', 'id', CAST(n_interface_class_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface_class" table.', n_interface_class_id;
        RETURN;
    END IF;

    -- Check if connecting_interface_class_id is not empty or null and connecting_interface_class_id exists within table
    IF (public.fn_text_field_valid(CAST(n_connecting_interface_class_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('interface_class', 'id', CAST(n_connecting_interface_class_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface_class" table.', n_connecting_interface_class_id;
        RETURN;
    END IF;
    
    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(interface_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in interface table --->>>

        -- Create new record into the table
        INSERT INTO interface(
            interface_class_id,
            connecting_interface_class_id, 
            identifier, 
            description, 
            comment, 
            is_intermediate, 
            modified_at
        )
        VALUES (
            n_interface_class_id,
            n_connecting_interface_class_id,
            n_identifier, 
            n_description, 
            n_comment, 
            n_is_intermediate, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added interface %s(%s)', n_identifier, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in interface table --->>>

        -- Check if id exists within property table
        IF (public.fn_field_unique_valid('interface', 'id', CAST(interface_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "interface" table.', interface_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            interface_class_id,
            connecting_interface_class_id,
            identifier,
            description,
            comment 
        INTO 
            o_interface_class_id,
            o_connecting_interface_class_id,
            o_identifier,
            o_description,
            o_comment 
        FROM interface WHERE id = interface_id;

        -- Update current record with the information
        UPDATE interface
        SET interface_class_id = n_interface_class_id,
            connecting_interface_class_id = n_connecting_interface_class_id,
            identifier = CASE WHEN n_identifier <> o_identifier THEN n_identifier ELSE identifier END,
            description = n_description,
            comment = n_comment,
            is_intermediate = n_is_intermediate,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = interface_id;

        n_table_id := interface_id;

        -- Make change_description content
        IF (n_interface_class_id <> o_interface_class_id) THEN
            change_description = CONCAT(change_description, 'interface_class_id changed from "', o_interface_class_id, '" to "', n_interface_class_id, '", ');
        END IF;
        IF (n_connecting_interface_class_id <> o_connecting_interface_class_id) THEN
            change_description = CONCAT(change_description, 'connecting_interface_class_id changed from "', o_connecting_interface_class_id, '" to "', n_connecting_interface_class_id, '", ');
        END IF;
        IF (n_identifier <> o_identifier) THEN
            change_description = CONCAT(change_description, 'identifier changed from "', o_identifier, '" to "', n_identifier, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated interface(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'interface', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
   DROP PROCEDURE public.proc_modify_interface(IN n_modified_by text, IN n_reason text, IN n_identifier text, IN interface_id bigint, IN n_interface_class_id bigint, IN n_connecting_interface_class_id bigint, IN n_description text, IN n_comment text, IN n_is_intermediate boolean);
       public          postgres    false    6            �           1255    17351 A   proc_modify_interface_class(text, text, text, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_modify_interface_class(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN interface_class_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_label text;
DECLARE o_description text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if label is not empty or null
    IF (public.fn_text_field_valid(n_label, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"label" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(interface_class_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in interface_class table --->>>
        
        -- Check if label is unique in the table
        IF (public.fn_field_unique_valid('interface_class', 'label', n_label, interface_class_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Create new record into the table
        INSERT INTO interface_class(
            label, 
            description, 
            comment, 
            modified_at
        )
        VALUES (
            n_label, 
            n_description, 
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added interface class %s(%s)', n_label, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in resource_group table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('interface_class', 'id', CAST(interface_class_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "interface_class" table.', interface_class_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            label, 
            description, 
            comment 
        INTO 
            o_label, 
            o_description, 
            o_comment 
        FROM interface_class WHERE id = interface_class_id;

        -- Check if label is unique in the table
        IF (n_label <> o_label AND public.fn_field_unique_valid('interface_class', 'label', n_label, interface_class_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        UPDATE interface_class
        SET label = CASE WHEN n_label <> o_label THEN n_label ELSE label END,
            description = CASE WHEN n_description <> o_description THEN n_description ELSE description END,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = interface_class_id;
        
        n_table_id := interface_class_id;
        
        -- Make change_description content
        IF (n_label <> o_label) THEN
            change_description = CONCAT(change_description, 'label changed from "', o_label, '" to "', n_label, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated interface class(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'interface_class', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_interface_class(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN interface_class_id bigint, IN n_comment text);
       public          michaelm    false    6            �           1255    17352 T   proc_modify_permitted_interface_connection(text, text, bigint, bigint, bigint, text) 	   PROCEDURE     l  CREATE PROCEDURE public.proc_modify_permitted_interface_connection(IN n_modified_by text, IN n_reason text, IN permitted_interface_connection_id bigint DEFAULT NULL::bigint, IN n_interface_class_id bigint DEFAULT NULL::bigint, IN n_connection_type_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_interface_class_id bigint;
DECLARE o_connection_type_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if interface_class_id is not empty or null and interface_class_id exists within table
    IF (public.fn_text_field_valid(CAST(n_interface_class_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('interface_class', 'id', CAST(n_interface_class_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface_class" table.', n_interface_class_id;
        RETURN;
    END IF;

    -- Check if connection_type_id is not empty or null and connection_type_id exists within table
    IF (public.fn_text_field_valid(CAST(n_connection_type_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('connection_type', 'id', CAST(n_connection_type_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection_type" table.', n_connection_type_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(permitted_interface_connection_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in permitted_interface_connection table --->>>

        -- Create new record into the table
        INSERT INTO permitted_interface_connection(
            interface_class_id, 
            connection_type_id, 
            comment, 
            modified_at
        )
        VALUES (
            n_interface_class_id, 
            n_connection_type_id, 
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Allowed connection type(%s) to interface class(%s)', n_connection_type_id, n_interface_class_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in permitted_interface_connection table --->>>

        -- Check if id exists within permitted_interface_connection table
        IF (public.fn_field_unique_valid('permitted_interface_connection', 'id', CAST(permitted_interface_connection_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "permitted_interface_connection" table.', permitted_interface_connection_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            interface_class_id,
            connection_type_id,
            comment
        INTO 
            o_interface_class_id,
            o_connection_type_id,
            o_comment
        FROM permitted_interface_connection WHERE id = permitted_interface_connection_id;

        -- Update current record with the information
        UPDATE permitted_interface_connection
        SET interface_class_id = n_interface_class_id,
            connection_type_id = n_connection_type_id,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = permitted_interface_connection_id;

        n_table_id := permitted_interface_connection_id;
        
        -- Make change_description content
        IF (n_interface_class_id <> o_interface_class_id) THEN
            change_description = CONCAT(change_description, 'interface_class_id changed from "', o_interface_class_id, '" to "', n_interface_class_id, '", ');
        END IF;
        IF (n_connection_type_id <> o_connection_type_id) THEN
            change_description = CONCAT(change_description, 'connection_type_id changed from "', o_connection_type_id, '" to "', n_connection_type_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated permitted interface connection(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'permitted_interface_connection',
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_permitted_interface_connection(IN n_modified_by text, IN n_reason text, IN permitted_interface_connection_id bigint, IN n_interface_class_id bigint, IN n_connection_type_id bigint, IN n_comment text);
       public          michaelm    false    6            �           1255    17353 Z   proc_modify_possible_state(text, text, text, text, bigint, text, boolean, boolean, bigint) 	   PROCEDURE     =  CREATE PROCEDURE public.proc_modify_possible_state(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN possible_state_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text, IN n_valid_for_connection boolean DEFAULT true, IN n_valid_for_equipment boolean DEFAULT true, IN n_authority_id bigint DEFAULT NULL::bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_label text;
DECLARE o_description text;
DECLARE o_authority_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if label is not empty or null
    IF (public.fn_text_field_valid(n_label, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"label" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;
    
    -- Check if authority_id is not empty or null and authority_id exists within table
    IF (public.fn_text_field_valid(CAST(n_authority_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('authority', 'id', CAST(n_authority_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "authority" table.', n_authority_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(possible_state_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in possible_state table --->>>
        
        -- Check if label is unique in the table
        IF (public.fn_field_unique_valid('possible_state', 'label', n_label, possible_state_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Create new record into the table
        INSERT INTO possible_state(
            label, 
            description,
            valid_for_connection,
            valid_for_equipment, 
            comment, 
            authority_id, 
            modified_at
        )
        VALUES (
            n_label, 
            n_description,
            n_valid_for_connection,
            n_valid_for_equipment, 
            n_comment, 
            n_authority_id, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Created possible state %s(%s)', n_label, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in possible_state table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('possible_state', 'id', CAST(possible_state_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "possible_state" table.', possible_state_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            label, 
            description,
            authority_id, 
            comment 
        INTO 
            o_label, 
            o_description, 
            o_authority_id,
            o_comment 
        FROM possible_state WHERE id = possible_state_id;

        -- Check if label is unique in the table
        IF (n_label <> o_label AND public.fn_field_unique_valid('possible_state', 'label', n_label, possible_state_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        UPDATE possible_state
        SET label = CASE WHEN n_label <> o_label THEN n_label ELSE label END,
            description = CASE WHEN n_description <> o_description THEN n_description ELSE description END,
            valid_for_connection = n_valid_for_connection,
            valid_for_equipment = n_valid_for_equipment,
            authority_id = n_authority_id,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = possible_state_id;
        
        n_table_id := possible_state_id;
        
        -- Make change_description content
        IF (n_label <> o_label) THEN
            change_description = CONCAT(change_description, 'label changed from "', o_label, '" to "', n_label, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_authority_id <> o_authority_id) THEN
            change_description = CONCAT(change_description, 'authority_id changed from "', o_authority_id, '" to "', n_authority_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated possible state(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'possible_state', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
   DROP PROCEDURE public.proc_modify_possible_state(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN possible_state_id bigint, IN n_comment text, IN n_valid_for_connection boolean, IN n_valid_for_equipment boolean, IN n_authority_id bigint);
       public          michaelm    false    6            �           1255    17356 Q   proc_modify_property(text, text, text, bigint, text, text, bigint, text, boolean) 	   PROCEDURE     j  CREATE PROCEDURE public.proc_modify_property(IN n_modified_by text, IN n_reason text, IN n_description text, IN property_id bigint DEFAULT NULL::bigint, IN n_modifier text DEFAULT NULL::text, IN n_default_value text DEFAULT NULL::text, IN n_default_datatype_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text, IN n_is_reportable boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_modifier text;
DECLARE o_description text;
DECLARE o_default_value text;
DECLARE o_default_datatype_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;
    
    -- Check if default_datatype_id is not empty or null and default_datatype_id exists within table
    IF (public.fn_text_field_valid(CAST(n_default_datatype_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('datatype', 'id', CAST(n_default_datatype_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "datatype" table.', n_default_datatype_id;
        RETURN;
    END IF;
    
    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(property_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in property table --->>>

        -- Create new record into the table
        INSERT INTO property(
            modifier, 
            description, 
            default_value, 
            default_datatype_id, 
            comment, 
            is_reportable, 
            modified_at
        )
        VALUES (
            n_modifier, 
            n_description, 
            n_default_value, 
            n_default_datatype_id, 
            n_comment, 
            n_is_reportable, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Created property %s(%s)', n_modifier, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in property table --->>>

        -- Check if id exists within property table
        IF (public.fn_field_unique_valid('property', 'id', CAST(property_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "property" table.', property_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            modifier,
            description,
            default_value,
            default_datatype_id,
            comment 
        INTO 
            o_modifier,
            o_description,
            o_default_value,
            o_default_datatype_id,
            o_comment 
        FROM property WHERE id = property_id;

        -- Update current record with the information
        UPDATE property
        SET modifier = n_modifier,
            description = CASE WHEN n_description <> o_description THEN n_description ELSE description END,
            default_value = n_default_value,
            default_datatype_id = n_default_datatype_id,
            comment = n_comment,
            is_reportable = n_is_reportable,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = property_id;

        n_table_id := property_id;

        -- Make change_description content
        IF (n_modifier <> o_modifier) THEN
            change_description = CONCAT(change_description, 'modifier changed from "', o_modifier, '" to "', n_modifier, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_default_value <> o_default_value) THEN
            change_description = CONCAT(change_description, 'default_value changed from "', o_default_value, '" to "', n_default_value, '", ');
        END IF;
        IF (n_default_datatype_id <> o_default_datatype_id) THEN
            change_description = CONCAT(change_description, 'default_datatype_id changed from "', o_default_datatype_id, '" to "', n_default_datatype_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated property(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'property', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
    DROP PROCEDURE public.proc_modify_property(IN n_modified_by text, IN n_reason text, IN n_description text, IN property_id bigint, IN n_modifier text, IN n_default_value text, IN n_default_datatype_id bigint, IN n_comment text, IN n_is_reportable boolean);
       public          michaelm    false    6            �           1255    17359 R   proc_modify_property_value(text, text, bigint, bigint, bigint, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_modify_property_value(IN n_modified_by text, IN n_reason text, IN property_value_id bigint DEFAULT NULL::bigint, IN n_equipment_id bigint DEFAULT NULL::bigint, IN n_resource_property_id bigint DEFAULT NULL::bigint, IN n_value text DEFAULT NULL::text, IN n_datatype_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_equipment_id bigint;
DECLARE o_resource_property_id bigint;
DECLARE o_value text;
DECLARE o_datatype_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if equipment_id is not empty or null and equipment_id exists within table
    IF (public.fn_text_field_valid(CAST(n_equipment_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment', 'id', CAST(n_equipment_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_equipment_id;
        RETURN;
    END IF;

    -- Check if resource_property_id is not empty or null and resource_property_id exists within table
    IF (public.fn_text_field_valid(CAST(n_resource_property_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('resource_property', 'id', CAST(n_resource_property_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "resource_property" table.', n_resource_property_id;
        RETURN;
    END IF;

    -- Check if datatype_id is not empty or null and datatype_id exists within table
    IF (public.fn_text_field_valid(CAST(n_datatype_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('datatype', 'id', CAST(n_datatype_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "datatype" table.', n_datatype_id;
        RETURN;
    END IF;
    
    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(property_value_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in property_value table --->>>

        -- Create new record into the table
        INSERT INTO property_value(
            equipment_id, 
            resource_property_id, 
            value, 
            datatype_id, 
            comment, 
            modified_at
        )
        VALUES (
            n_equipment_id, 
            n_resource_property_id, 
            n_value, 
            n_datatype_id, 
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added property value(%s) of datatype(%s) to resource property(%s)', n_value, n_datatype_id, n_resource_property_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in property_value table --->>>

        -- Check if id exists within property_value table
        IF (public.fn_field_unique_valid('property_value', 'id', CAST(property_value_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "property_value" table.', property_value_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            equipment_id,
            resource_property_id,
            value,
            datatype_id,
            comment
        INTO 
            o_equipment_id,
            o_resource_property_id,
            o_value,
            o_datatype_id,
            o_comment
        FROM property_value WHERE id = property_value_id;

        -- Update current record with the information
        UPDATE property_value
        SET equipment_id = n_equipment_id,
            resource_property_id = n_resource_property_id,
            value = n_value,
            datatype_id = n_datatype_id,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = property_value_id;

        n_table_id := property_value_id;
        
        -- Make change_description content
        IF (n_equipment_id <> o_equipment_id) THEN
            change_description = CONCAT(change_description, 'equipment_id changed from "', o_equipment_id, '" to "', n_equipment_id, '", ');
        END IF;
        IF (n_resource_property_id <> o_resource_property_id) THEN
            change_description = CONCAT(change_description, 'resource_property_id changed from "', o_resource_property_id, '" to "', n_resource_property_id, '", ');
        END IF;
        IF (n_value <> o_value) THEN
            change_description = CONCAT(change_description, 'value changed from "', o_value, '" to "', n_value, '", ');
        END IF;
        IF (n_datatype_id <> o_datatype_id) THEN
            change_description = CONCAT(change_description, 'datatype_id changed from "', o_datatype_id, '" to "', n_datatype_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated property value(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason,
        'property_value',
        n_table_id, 
        change_description, 
        n_comment 
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_property_value(IN n_modified_by text, IN n_reason text, IN property_value_id bigint, IN n_equipment_id bigint, IN n_resource_property_id bigint, IN n_value text, IN n_datatype_id bigint, IN n_comment text);
       public          michaelm    false    6            �           1255    17360 B   proc_modify_resource(text, text, text, bigint, bigint, text, text) 	   PROCEDURE       CREATE PROCEDURE public.proc_modify_resource(IN n_modified_by text, IN n_reason text, IN n_description text, IN resource_id bigint DEFAULT NULL::bigint, IN n_resource_group_id bigint DEFAULT NULL::bigint, IN n_modifier text DEFAULT NULL::text, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_resource_group_id bigint;
DECLARE o_modifier text;
DECLARE o_description text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if resource_group_id is not empty or null and resource_group_id exists within table
    IF (public.fn_text_field_valid(CAST(n_resource_group_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('resource_group', 'id', CAST(n_resource_group_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "resource_group" table.', n_resource_group_id;
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(resource_id AS TEXT), 'empty') = FALSE)
        THEN
            --->>> Start Create new record in resource table --->>>

            -- Insert a new record with the information
            INSERT INTO resource(
                resource_group_id, 
                modifier, 
                description, 
                comment, 
                modified_at
            )
            VALUES (
                n_resource_group_id, 
                n_modifier, 
                n_description, 
                n_comment, 
                CURRENT_TIMESTAMP
            )
            RETURNING id INTO n_table_id;
            
            change_description := format('Created resource group %s(%s)', n_modifier, n_description);

            -- //<<<--- End Create new record <<<---
        ELSE
            --->>> Start Update the record in resource table --->>>

            -- Check if id exists within table
            IF (public.fn_field_unique_valid('resource', 'id', CAST(resource_id AS TEXT), NULL) = TRUE) THEN
                RAISE EXCEPTION 'id = % does not exist in the "resource" table.', resource_id;
                RETURN;
            END IF;

            -- Get prev fields from the table
            SELECT 
                resource_group_id,
                modifier,
                description,
                comment
            INTO 
                o_resource_group_id,
                o_modifier,
                o_description,
                o_comment 
            FROM resource WHERE id = resource_id;

            -- Update current record with the information
            UPDATE resource
            SET resource_group_id = n_resource_group_id,
                modifier = n_modifier,
                description = CASE WHEN n_description <> o_description THEN n_description ELSE description END,
                comment = n_comment,
                modified_at = CURRENT_TIMESTAMP
            WHERE id = resource_id;

            n_table_id := resource_id;

            -- Make change_description content
            IF (n_resource_group_id <> o_resource_group_id) THEN
                change_description = CONCAT(change_description, 'resource_group_id changed from "', o_resource_group_id, '" to "', n_resource_group_id, '", ');
            END IF;
            IF (n_modifier <> o_modifier) THEN
                change_description = CONCAT(change_description, 'modifier changed from "', o_modifier, '" to "', n_modifier, '", ');
            END IF;
            IF (n_description <> o_description) THEN
                change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
            END IF;
            IF (n_comment <> o_comment) THEN
                change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
            END IF;
            change_description = CONCAT('Updated resource(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'resource', 
        n_table_id, 
        change_description, 
        n_comment 
    );

END;
$$;
 �   DROP PROCEDURE public.proc_modify_resource(IN n_modified_by text, IN n_reason text, IN n_description text, IN resource_id bigint, IN n_resource_group_id bigint, IN n_modifier text, IN n_comment text);
       public          michaelm    false    6            �           1255    17361 I   proc_modify_resource_group(text, text, text, text, bigint, text, boolean) 	   PROCEDURE     3  CREATE PROCEDURE public.proc_modify_resource_group(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN resource_group_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text, IN n_is_reportable boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_label text;
DECLARE o_description text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if label is not empty or null
    IF (public.fn_text_field_valid(n_label, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"label" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if description is not empty or null
    IF (public.fn_text_field_valid(n_description, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if description is greater than 5 characters
    IF (public.fn_text_field_valid(n_description, 'length') = FALSE) THEN
        RAISE EXCEPTION '"description" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(resource_group_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in resource_group table --->>>
        
        -- Check if label is unique in the table
        IF (public.fn_field_unique_valid('resource_group', 'label', n_label, resource_group_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Create new record into the table
        INSERT INTO resource_group(
            label, 
            description, 
            comment, 
            is_reportable, 
            modified_at
        )
        VALUES (
            n_label, 
            n_description, 
            n_comment, 
            n_is_reportable, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Created resource group %s(%s)', n_label, n_description);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in resource_group table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('resource_group', 'id', CAST(resource_group_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "resource_group" table.', resource_group_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            label, 
            description, 
            comment 
        INTO 
            o_label, 
            o_description, 
            o_comment 
        FROM resource_group WHERE id = resource_group_id;

        -- Check if label is unique in the table
        IF (n_label <> o_label AND public.fn_field_unique_valid('resource_group', 'label', n_label, resource_group_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        UPDATE resource_group
        SET label = CASE WHEN n_label <> o_label THEN n_label ELSE label END,
            description = CASE WHEN n_description <> o_description THEN n_description ELSE description END,
            comment = n_comment,
            is_reportable = n_is_reportable,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = resource_group_id;
        
        n_table_id := resource_group_id;
        
        -- Make change_description content
        IF (n_label <> o_label) THEN
            change_description = CONCAT(change_description, 'label changed from "', o_label, '" to "', n_label, '", ');
        END IF;
        IF (n_description <> o_description) THEN
            change_description = CONCAT(change_description, 'description changed from "', o_description, '" to "', n_description, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated resource group(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'resource_group', 
        n_table_id, 
        change_description, 
        n_comment 
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_resource_group(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_description text, IN resource_group_id bigint, IN n_comment text, IN n_is_reportable boolean);
       public          michaelm    false    6            �           1255    17362 U   proc_modify_resource_property(text, text, bigint, bigint, bigint, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_modify_resource_property(IN n_modified_by text, IN n_reason text, IN resource_property_id bigint DEFAULT NULL::bigint, IN n_resource_id bigint DEFAULT NULL::bigint, IN n_property_id bigint DEFAULT NULL::bigint, IN n_default_value text DEFAULT NULL::text, IN n_default_datatype_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_resource_id bigint;
DECLARE o_property_id bigint;
DECLARE o_default_value text;
DECLARE o_default_datatype_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if resource_id is not empty or null and resource_id exists within table
    IF (public.fn_text_field_valid(CAST(n_resource_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('resource', 'id', CAST(n_resource_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "resource" table.', n_resource_id;
        RETURN;
    END IF;

    -- Check if property_id is not empty or null and property_id exists within table
    IF (public.fn_text_field_valid(CAST(n_property_id AS TEXT), 'empty') = TRUE and public.fn_field_unique_valid('property', 'id', CAST(n_property_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "property" table.', n_property_id;
        RETURN;
    END IF;

    -- Check if default_datatype_id is not empty or null and default_datatype_id exists within table
    IF (public.fn_text_field_valid(CAST(n_default_datatype_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('datatype', 'id', CAST(n_default_datatype_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "datatype" table.', n_default_datatype_id;
        RETURN;
    END IF;
    
    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(resource_property_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in resource_property table --->>>

        -- Create new record into the table
        INSERT INTO resource_property(
            resource_id, 
            property_id, 
            default_value, 
            default_datatype_id, 
            comment, 
            modified_at
        )
        VALUES (
            n_resource_id, 
            n_property_id, 
            n_default_value, 
            n_default_datatype_id, 
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added property(%s) to resource(%s)', n_property_id, n_resource_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in resource_property table --->>>

        -- Check if id exists within resource_property table
        IF (public.fn_field_unique_valid('resource_property', 'id', CAST(resource_property_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "resource_property" table.', resource_property_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            resource_id,
            property_id,
            default_value,
            default_datatype_id
            comment
        INTO 
            o_resource_id,
            o_property_id,
            o_default_value,
            o_default_datatype_id,
            o_comment
        FROM resource_property WHERE id = resource_property_id;

        -- Update current record with the information
        UPDATE resource_property
        SET resource_id = n_resource_id,
            property_id = n_property_id,
            default_value = n_default_value,
            default_datatype_id = n_default_datatype_id,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = resource_property_id;

        n_table_id := resource_property_id;
        
        -- Make change_description content
        IF (n_resource_id <> o_resource_id) THEN
            change_description = CONCAT(change_description, 'resource_id changed from "', o_resource_id, '" to "', n_resource_id, '", ');
        END IF;
        IF (n_property_id <> o_property_id) THEN
            change_description = CONCAT(change_description, 'property_id changed from "', o_property_id, '" to "', n_property_id, '", ');
        END IF;
        IF (n_default_value <> o_default_value) THEN
            change_description = CONCAT(change_description, 'default_value changed from "', o_default_value, '" to "', n_default_value, '", ');
        END IF;
        IF (n_default_datatype_id <> o_default_datatype_id) THEN
            change_description = CONCAT(change_description, 'default_datatype_id changed from "', o_default_datatype_id, '" to "', n_default_datatype_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated resource property(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'resource_property', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_resource_property(IN n_modified_by text, IN n_reason text, IN resource_property_id bigint, IN n_resource_id bigint, IN n_property_id bigint, IN n_default_value text, IN n_default_datatype_id bigint, IN n_comment text);
       public          michaelm    false    6            �           1255    17365 A   proc_modify_system_settings(text, text, text, text, bigint, text) 	   PROCEDURE     $  CREATE PROCEDURE public.proc_modify_system_settings(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_value text, IN system_settings_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_label text;
DECLARE o_value text;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if label is not empty or null
    IF (public.fn_text_field_valid(n_label, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"label" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if value is not empty or null
    IF (public.fn_text_field_valid(n_value, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"value" cannot be empty or null.';
        RETURN;
    END IF;
    
    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(system_settings_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in system_settings table --->>>
        
        -- Check if label is unique in the table
        IF (public.fn_field_unique_valid('system_settings', 'label', n_label, system_settings_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        -- Create new record into the table
        INSERT INTO system_settings(
            label, 
            value,
            comment, 
            modified_at
        )
        VALUES (
            n_label, 
            n_value,
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Created system settings %s(%s)', n_label, n_value);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in system_settings table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('system_settings', 'id', CAST(system_settings_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "system_settings" table.', system_settings_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            label, 
            value,
            comment 
        INTO 
            o_label, 
            o_value, 
            o_comment 
        FROM system_settings WHERE id = system_settings_id;

        -- Check if label is unique in the table
        IF (n_label <> o_label AND public.fn_field_unique_valid('system_settings', 'label', n_label, system_settings_id) = FALSE) THEN
            RAISE EXCEPTION 'Label "%" already exists. Not unique', n_label;
            RETURN;
        END IF;

        UPDATE system_settings
        SET label = CASE WHEN n_label <> o_label THEN n_label ELSE label END,
            value = n_value,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = system_settings_id;
        
        n_table_id := system_settings_id;
        
        -- Make change_description content
        IF (n_label <> o_label) THEN
            change_description = CONCAT(change_description, 'label changed from "', o_label, '" to "', n_label, '", ');
        END IF;
        IF (n_value <> o_value) THEN
            change_description = CONCAT(change_description, 'value changed from "', o_value, '" to "', n_value, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated system settings(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'system_settings', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_system_settings(IN n_modified_by text, IN n_reason text, IN n_label text, IN n_value text, IN system_settings_id bigint, IN n_comment text);
       public          michaelm    false    6            �           1255    17366   proc_modify_type_detail(text, text, bigint, bigint, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, text, text, text, text, double precision, text) 	   PROCEDURE     �3  CREATE PROCEDURE public.proc_modify_type_detail(IN n_modified_by text, IN n_reason text, IN type_detail_id bigint DEFAULT NULL::bigint, IN n_type_id bigint DEFAULT NULL::bigint, IN n_width double precision DEFAULT NULL::double precision, IN n_height double precision DEFAULT NULL::double precision, IN n_depth double precision DEFAULT NULL::double precision, IN n_top_clearance double precision DEFAULT NULL::double precision, IN n_bottom_clearance double precision DEFAULT NULL::double precision, IN n_left_clearance double precision DEFAULT NULL::double precision, IN n_right_clearance double precision DEFAULT NULL::double precision, IN n_front_clearance double precision DEFAULT NULL::double precision, IN n_rear_clearance double precision DEFAULT NULL::double precision, IN n_installation_method text DEFAULT NULL::text, IN n_process_interface text DEFAULT NULL::text, IN n_control_interface text DEFAULT NULL::text, IN n_energy_supply text DEFAULT NULL::text, IN n_energy_use double precision DEFAULT NULL::double precision, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_type_id bigint;
DECLARE o_width float;
DECLARE o_height float;
DECLARE o_depth float;
DECLARE o_top_clearance float;
DECLARE o_bottom_clearance float;
DECLARE o_left_clearance float;
DECLARE o_right_clearance float;
DECLARE o_front_clearance float;
DECLARE o_rear_clearance float;
DECLARE o_installation_method text;
DECLARE o_process_interface text;
DECLARE o_control_interface text;
DECLARE o_energy_supply text;
DECLARE o_energy_use float;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if type_id is not empty or null and type_id exists within table
    IF (public.fn_text_field_valid(CAST(n_type_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment_type', 'id', CAST(n_type_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment_type" table.', n_type_id;
        RETURN;
    END IF;

    -- Check if width is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_width AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_width AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'width is not a number.';
        RETURN;
    END IF;

    -- Check if height is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_height AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_height AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'height is not a number.';
        RETURN;
    END IF;

    -- Check if depth is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_depth AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_depth AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'depth is not a number.';
        RETURN;
    END IF;

    -- Check if top_clearance is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_top_clearance AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_top_clearance AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'top_clearance is not a number.';
        RETURN;
    END IF;

    -- Check if bottom_clearance is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_bottom_clearance AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_bottom_clearance AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'bottom_clearance is not a number.';
        RETURN;
    END IF;

    -- Check if left_clearance is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_left_clearance AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_left_clearance AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'left_clearance is not a number.';
        RETURN;
    END IF;

    -- Check if right_clearance is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_right_clearance AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_right_clearance AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'right_clearance is not a number.';
        RETURN;
    END IF;

    -- Check if front_clearance is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_front_clearance AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_front_clearance AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'front_clearance is not a number.';
        RETURN;
    END IF;

    -- Check if rear_clearance is not empty or null and is float type
    IF (public.fn_text_field_valid(CAST(n_rear_clearance AS TEXT), 'empty') = TRUE AND public.fn_text_field_valid(CAST(n_rear_clearance AS TEXT), 'number') = FALSE) THEN
        RAISE EXCEPTION 'rear_clearance is not a number.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(type_detail_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in type_detail table --->>>
        
        -- Create new record into the table
        INSERT INTO type_detail(
            type_id,
            width,
            height,
            depth,
            top_clearance,
            bottom_clearance,
            left_clearance,
            right_clearance,
            front_clearance,
            rear_clearance,
            installation_method,
            process_interface,
            control_interface,
            energy_supply,
            energy_use,
            comment, 
            modified_at
        )
        VALUES (
            n_type_id,
            n_width,
            n_height,
            n_depth,
            n_top_clearance,
            n_bottom_clearance,
            n_left_clearance,
            n_right_clearance,
            n_front_clearance,
            n_rear_clearance,
            n_installation_method,
            n_process_interface,
            n_control_interface,
            n_energy_supply,
            n_energy_use,
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added details for type(%s)', n_type_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in type_detail table --->>>
        
        -- Check if id exists within table
        IF (public.fn_field_unique_valid('type_detail', 'id', CAST(type_detail_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "type_detail" table.', type_detail_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            type_id,
            width,
            height,
            depth,
            top_clearance,
            bottom_clearance,
            left_clearance,
            right_clearance,
            front_clearance,
            rear_clearance,
            installation_method,
            process_interface,
            control_interface,
            energy_supply,
            energy_use,
            comment 
        INTO 
            o_type_id,
            o_width,
            o_height,
            o_depth,
            o_top_clearance,
            o_bottom_clearance,
            o_left_clearance,
            o_right_clearance,
            o_front_clearance,
            o_rear_clearance,
            o_installation_method,
            o_process_interface,
            o_control_interface,
            o_energy_supply,
            o_energy_use,
            o_comment 
        FROM type_detail WHERE id = type_detail_id;

        UPDATE type_detail
        SET type_id = n_type_id,
            width = n_width,
            height = n_height,
            depth = n_depth,
            top_clearance = n_top_clearance,
            bottom_clearance = n_bottom_clearance,
            left_clearance = n_left_clearance,
            right_clearance = n_right_clearance,
            front_clearance = n_front_clearance,
            rear_clearance = n_rear_clearance,
            installation_method = n_installation_method,
            process_interface = n_process_interface,
            control_interface = n_control_interface,
            energy_supply = n_energy_supply,
            energy_use = n_energy_use,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = type_detail_id;
        
        n_table_id := type_detail_id;
        
        -- Make change_description content
        IF (n_type_id <> o_type_id) THEN
            change_description = CONCAT(change_description, 'type_id changed from "', o_type_id, '" to "', n_type_id, '", ');
        END IF;
        IF (n_width <> o_width) THEN
            change_description = CONCAT(change_description, 'width changed from "', o_width, '" to "', n_width, '", ');
        END IF;
        IF (n_height <> o_height) THEN
            change_description = CONCAT(change_description, 'height changed from "', o_height, '" to "', n_height, '", ');
        END IF;
        IF (n_depth <> o_depth) THEN
            change_description = CONCAT(change_description, 'depth changed from "', o_depth, '" to "', n_depth, '", ');
        END IF;
        IF (n_top_clearance <> o_top_clearance) THEN
            change_description = CONCAT(change_description, 'top_clearance changed from "', o_top_clearance, '" to "', n_top_clearance, '", ');
        END IF;
        IF (n_bottom_clearance <> o_bottom_clearance) THEN
            change_description = CONCAT(change_description, 'bottom_clearance changed from "', o_bottom_clearance, '" to "', n_bottom_clearance, '", ');
        END IF;
        IF (n_left_clearance <> o_left_clearance) THEN
            change_description = CONCAT(change_description, 'left_clearance changed from "', o_left_clearance, '" to "', n_left_clearance, '", ');
        END IF;
        IF (n_right_clearance <> o_right_clearance) THEN
            change_description = CONCAT(change_description, 'right_clearance changed from "', o_right_clearance, '" to "', n_right_clearance, '", ');
        END IF;
        IF (n_front_clearance <> o_front_clearance) THEN
            change_description = CONCAT(change_description, 'front_clearance changed from "', o_front_clearance, '" to "', n_front_clearance, '", ');
        END IF;
        IF (n_rear_clearance <> o_rear_clearance) THEN
            change_description = CONCAT(change_description, 'rear_clearance changed from "', o_rear_clearance, '" to "', n_rear_clearance, '", ');
        END IF;
        IF (n_installation_method <> o_installation_method) THEN
            change_description = CONCAT(change_description, 'installation_method changed from "', o_installation_method, '" to "', n_installation_method, '", ');
        END IF;
        IF (n_process_interface <> o_process_interface) THEN
            change_description = CONCAT(change_description, 'process_interface changed from "', o_process_interface, '" to "', n_process_interface, '", ');
        END IF;
        IF (n_control_interface <> o_control_interface) THEN
            change_description = CONCAT(change_description, 'control_interface changed from "', o_control_interface, '" to "', n_control_interface, '", ');
        END IF;
        IF (n_energy_supply <> o_energy_supply) THEN
            change_description = CONCAT(change_description, 'bottom_clearance changed from "', o_bottom_clearance, '" to "', n_bottom_clearance, '", ');
        END IF;
        IF (n_energy_use <> o_energy_use) THEN
            change_description = CONCAT(change_description, 'energy_use changed from "', o_energy_use, '" to "', n_energy_use, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated type detail(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'type_detail',
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 m  DROP PROCEDURE public.proc_modify_type_detail(IN n_modified_by text, IN n_reason text, IN type_detail_id bigint, IN n_type_id bigint, IN n_width double precision, IN n_height double precision, IN n_depth double precision, IN n_top_clearance double precision, IN n_bottom_clearance double precision, IN n_left_clearance double precision, IN n_right_clearance double precision, IN n_front_clearance double precision, IN n_rear_clearance double precision, IN n_installation_method text, IN n_process_interface text, IN n_control_interface text, IN n_energy_supply text, IN n_energy_use double precision, IN n_comment text);
       public          michaelm    false    6            �           1255    17369 M   proc_modify_type_interface(text, text, bigint, bigint, bigint, text, boolean) 	   PROCEDURE       CREATE PROCEDURE public.proc_modify_type_interface(IN n_modified_by text, IN n_reason text, IN type_interface_id bigint DEFAULT NULL::bigint, IN n_type_resource_id bigint DEFAULT NULL::bigint, IN n_interface_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text, IN n_is_active boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_type_resource_id bigint;
DECLARE o_interface_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if type_resource_id is not empty or null and type_resource_id exists within table
    IF (public.fn_text_field_valid(CAST(n_type_resource_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('type_resource', 'id', CAST(n_type_resource_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "type_resource" table.', n_type_resource_id;
        RETURN;
    END IF;

    -- Check if interface_id is not empty or null and interface_id exists within table
    IF (public.fn_text_field_valid(CAST(n_interface_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('interface', 'id', CAST(n_interface_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface" table.', n_interface_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(type_interface_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in type_interface table --->>>

        -- Create new record into the table
        INSERT INTO type_interface(
            type_resource_id, 
            interface_id, 
            comment,
            is_active, 
            modified_at
        )
        VALUES (
            n_type_resource_id, 
            n_interface_id, 
            n_comment,
            n_is_active, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added interface(%s) to type_resource(%s)', n_interface_id, n_type_resource_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in type_interface table --->>>

        -- Check if id exists within type_interface table
        IF (public.fn_field_unique_valid('type_interface', 'id', CAST(type_interface_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "type_interface" table.', type_interface_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            type_resource_id,
            interface_id,
            comment
        INTO 
            o_type_resource_id,
            o_interface_id,
            o_comment
        FROM type_interface WHERE id = type_interface_id;

        -- Update current record with the information
        UPDATE type_interface
        SET type_resource_id = n_type_resource_id,
            interface_id = n_interface_id,
            comment = n_comment,
            is_active = n_is_active,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = type_interface_id;

        n_table_id := type_interface_id;
        
        -- Make change_description content
        IF (n_type_resource_id <> o_type_resource_id) THEN
            change_description = CONCAT(change_description, 'type_resource_id changed from "', o_type_resource_id, '" to "', n_type_resource_id, '", ');
        END IF;
        IF (n_interface_id <> o_interface_id) THEN
            change_description = CONCAT(change_description, 'interface_id changed from "', o_interface_id, '" to "', n_interface_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated type interface(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'type_interface', 
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_type_interface(IN n_modified_by text, IN n_reason text, IN type_interface_id bigint, IN n_type_resource_id bigint, IN n_interface_id bigint, IN n_comment text, IN n_is_active boolean);
       public          michaelm    false    6            �           1255    17370 C   proc_modify_type_resource(text, text, bigint, bigint, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_modify_type_resource(IN n_modified_by text, IN n_reason text, IN type_resource_id bigint DEFAULT NULL::bigint, IN n_type_id bigint DEFAULT NULL::bigint, IN n_resource_id bigint DEFAULT NULL::bigint, IN n_comment text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$

DECLARE n_table_id bigint;
DECLARE change_description text;
DECLARE o_type_id bigint;
DECLARE o_resource_id bigint;
DECLARE o_comment text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the user table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if type_id is not empty or null and type_id exists within table
    IF (public.fn_text_field_valid(CAST(n_type_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('equipment_type', 'id', CAST(n_type_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment_type" table.', n_type_id;
        RETURN;
    END IF;

    -- Check if resource_id is not empty or null and resource_id exists within table
    IF (public.fn_text_field_valid(CAST(n_resource_id AS TEXT), 'empty') = TRUE AND public.fn_field_unique_valid('resource', 'id', CAST(n_resource_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "resource" table.', n_resource_id;
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(type_resource_id AS TEXT), 'empty') = FALSE) THEN
        --->>> Start Create new record in type_resource table --->>>

        -- Create new record into the table
        INSERT INTO type_resource(
            type_id, 
            resource_id, 
            comment, 
            modified_at
        )
        VALUES (
            n_type_id, 
            n_resource_id, 
            n_comment, 
            CURRENT_TIMESTAMP
        )
        RETURNING id INTO n_table_id;
            
        change_description := format('Added resource(%s) to type(%s)', n_resource_id, n_type_id);

        -- //<<<--- End Create new record <<<---
    ELSE
        --->>> Start Update the record in type_resource table --->>>

        -- Check if id exists within type_resource table
        IF (public.fn_field_unique_valid('type_resource', 'id', CAST(type_resource_id AS TEXT), NULL) = TRUE) THEN
            RAISE EXCEPTION 'id = % does not exist in the "type_resource" table.', type_resource_id;
            RETURN;
        END IF;

        -- Get prev fields from the table
        SELECT 
            type_id,
            resource_id,
            comment
        INTO 
            o_type_id,
            o_resource_id,
            o_comment
        FROM type_resource WHERE id = type_resource_id;

        -- Update current record with the information
        UPDATE type_resource
        SET type_id = n_type_id,
            resource_id = n_resource_id,
            comment = n_comment,
            modified_at = CURRENT_TIMESTAMP
        WHERE id = type_resource_id;

        n_table_id := type_resource_id;
        
        -- Make change_description content
        IF (n_type_id <> o_type_id) THEN
            change_description = CONCAT(change_description, 'type_id changed from "', o_type_id, '" to "', n_type_id, '", ');
        END IF;
        IF (n_resource_id <> o_resource_id) THEN
            change_description = CONCAT(change_description, 'resource_id changed from "', o_resource_id, '" to "', n_resource_id, '", ');
        END IF;
        IF (n_comment <> o_comment) THEN
            change_description = CONCAT(change_description, 'comment changed from "', o_comment, '" to "', n_comment, '"');
        END IF;
        change_description = CONCAT('Updated type resource(', change_description, ')');

        -- //<<<--- End Update the record <<<---
    END IF;
    
    -- Create new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'type_resource',
        n_table_id, 
        change_description, 
        n_comment
    );
END;
$$;
 �   DROP PROCEDURE public.proc_modify_type_resource(IN n_modified_by text, IN n_reason text, IN type_resource_id bigint, IN n_type_id bigint, IN n_resource_id bigint, IN n_comment text);
       public          michaelm    false    6            �           1255    17371 0   proc_remove_connection(text, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_connection(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within connection table
    IF (public.fn_field_unique_valid('connection', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Set connection_id = NULL in connection_commercial table
    UPDATE connection_commercial
    SET connection_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE connection_id = n_id;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set connection_id = NULL in connection_state table
            UPDATE connection_state
            SET connection_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE connection_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where connection_id = id in connection_state table
            DELETE FROM connection_state WHERE connection_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM connection WHERE id = n_id;

    change_description := format('Deleted connection(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'connection', 
        n_id, 
        change_description
    );

END;
$$;
 y   DROP PROCEDURE public.proc_remove_connection(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17372 5   proc_remove_connection_commercial(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_connection_commercial(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within connection_commercial table
    IF (public.fn_field_unique_valid('connection_commercial', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection_commercial" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM connection_commercial WHERE id = n_id;

    change_description := format('Deleted connection_commercial(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'connection_commercial', 
        n_id, 
        change_description
    );

END;
$$;
 r   DROP PROCEDURE public.proc_remove_connection_commercial(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17373 0   proc_remove_connection_state(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_connection_state(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within connection_state table
    IF (public.fn_field_unique_valid('connection_state', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection_state" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM connection_state WHERE id = n_id;

    change_description := format('Deleted connection_state(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'connection_state', 
        n_id, 
        change_description
    );

END;
$$;
 m   DROP PROCEDURE public.proc_remove_connection_state(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17374 5   proc_remove_connection_type(text, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_connection_type(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within connection_type table
    IF (public.fn_field_unique_valid('connection_type', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "connection_type" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Set connection_type_id = NULL in connection table
    UPDATE connection
    SET connection_type_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE connection_type_id = n_id;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set connection_type_id = NULL in permitted_interface_connection table
            UPDATE permitted_interface_connection
            SET connection_type_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE connection_type_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where connection_type_id = id in permitted_interface_connection table
            DELETE FROM permitted_interface_connection WHERE connection_type_id = n_id;

        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM connection_type WHERE id = n_id;

    change_description := format('Deleted connection_type(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'connection_type', 
        n_id, 
        change_description
    );

END;
$$;
 ~   DROP PROCEDURE public.proc_remove_connection_type(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17375 (   proc_remove_datatype(text, text, bigint) 	   PROCEDURE     �	  CREATE PROCEDURE public.proc_remove_datatype(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within datatype table
    IF (public.fn_field_unique_valid('datatype', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "datatype" table.', n_id;
        RETURN;
    END IF;

    -- Set datatype_id = NULL in property_value table
    UPDATE property_value
    SET datatype_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE datatype_id = n_id;
    
    -- Set default_datatype_id = NULL in property table
    UPDATE property
    SET default_datatype_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE default_datatype_id = n_id;

    -- Set default_datatype_id = NULL in resource_property table
    UPDATE resource_property
    SET default_datatype_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE default_datatype_id = n_id;

    -- Delete record in the table
    DELETE FROM datatype WHERE id = n_id;

    change_description := format('Deleted datatype(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'datatype', 
        n_id, 
        change_description
    );

END;
$$;
 e   DROP PROCEDURE public.proc_remove_datatype(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17376 /   proc_remove_equipment(text, text, bigint, text) 	   PROCEDURE     k  CREATE PROCEDURE public.proc_remove_equipment(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within equipment table
    IF (public.fn_field_unique_valid('equipment', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Set start_equipment_id = NULL in connection table
    UPDATE connection
    SET start_equipment_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE start_equipment_id = n_id;

    -- Set end_equipment_id = NULL in connection table
    UPDATE connection
    SET end_equipment_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE end_equipment_id = n_id;

    -- Set equipment_id = NULL in equipment_commercial table
    UPDATE equipment_commercial
    SET equipment_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE equipment_id = n_id;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set equipment_id = NULL in property_value table
            UPDATE property_value
            SET equipment_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE equipment_id = n_id;

            -- Set equipment_id = NULL in equipment_state table
            UPDATE equipment_state
            SET equipment_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE equipment_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where equipment_id = id in property_value table
            DELETE FROM property_value WHERE equipment_id = n_id;

            -- Delete the records where equipment_id = id in equipment_state table
            DELETE FROM equipment_state WHERE equipment_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM equipment WHERE id = n_id;

    change_description := format('Deleted equipment(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'equipment', 
        n_id, 
        change_description
    );

END;
$$;
 x   DROP PROCEDURE public.proc_remove_equipment(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17377 4   proc_remove_equipment_commercial(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_equipment_commercial(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within equipment_commercial table
    IF (public.fn_field_unique_valid('equipment_commercial', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment_commercial" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM equipment_commercial WHERE id = n_id;

    change_description := format('Deleted equipment_commercial(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'equipment_commercial', 
        n_id, 
        change_description
    );

END;
$$;
 q   DROP PROCEDURE public.proc_remove_equipment_commercial(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17378 /   proc_remove_equipment_state(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_equipment_state(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within equipment_state table
    IF (public.fn_field_unique_valid('equipment_state', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment_state" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM equipment_state WHERE id = n_id;

    change_description := format('Deleted equipment_state(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'equipment_state', 
        n_id, 
        change_description
    );

END;
$$;
 l   DROP PROCEDURE public.proc_remove_equipment_state(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17379 4   proc_remove_equipment_type(text, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_equipment_type(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;
DECLARE item RECORD;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within equipment_type table
    IF (public.fn_field_unique_valid('equipment_type', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "equipment_type" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Set type_id = NULL in equipment table
    UPDATE equipment
    SET type_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE type_id = n_id;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set type_id = NULL in type_detail table
            UPDATE type_detail
            SET type_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE type_id = n_id;

            -- Set type_id = NULL in type_resource table
            UPDATE type_resource
            SET type_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE type_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where type_id = id in type_detail table
            DELETE FROM type_detail WHERE type_id = n_id;

            -- Set type_resource_id = NULL in type_interface table
            FOR item IN SELECT * FROM type_resource WHERE type_id = n_id LOOP
                UPDATE type_interface
                SET type_resource_id = NULL,
                    modified_at = CURRENT_TIMESTAMP
                WHERE type_resource_id = item.id;
            END LOOP;

            -- Delete the records where type_id = id in type_resource table
            DELETE FROM type_resource WHERE type_id = n_id;

        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM equipment_type WHERE id = n_id;

    
    change_description := format('Deleted equipment_type(%s)', n_id);

    -- Insert a new record in type_history table
    CALL public.proc_add_type_history(
        n_modified_by,
        n_reason, 
        n_id, 
        change_description
    );

END;
$$;
 }   DROP PROCEDURE public.proc_remove_equipment_type(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17380 /   proc_remove_interface(text, text, bigint, text) 	   PROCEDURE     1  CREATE PROCEDURE public.proc_remove_interface(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within interface table
    IF (public.fn_field_unique_valid('interface', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Set start_interface_id = NULL in connection table
    UPDATE connection
    SET start_interface_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE start_interface_id = n_id;

    -- Set end_interface_id = NULL in connection table
    UPDATE interface
    SET end_interface_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE end_interface_id = n_id;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set interface_id = NULL in type_interface table
            UPDATE type_interface
            SET interface_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE interface_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where interface_id = id in type_interface table
            DELETE FROM type_interface WHERE interface_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM interface WHERE id = n_id;

    change_description := format('Deleted interface(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'interface', 
        n_id, 
        change_description
    );

END;
$$;
 x   DROP PROCEDURE public.proc_remove_interface(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17381 5   proc_remove_interface_class(text, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_interface_class(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within interface_class table
    IF (public.fn_field_unique_valid('interface_class', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "interface_class" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;


    -- Set interface_class_id = NULL in interface table
    UPDATE interface
    SET interface_class_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE interface_class_id = n_id;

    -- Set connecting_interface_class_id = NULL in interface table
    UPDATE interface
    SET connecting_interface_class_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE connecting_interface_class_id = n_id;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set connecting_interface_class_id = NULL in permitted_interface_connection table
            UPDATE permitted_interface_connection
            SET interface_class_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE interface_class_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where interface_class_id = id in permitted_interface_connection table
            DELETE FROM permitted_interface_connection WHERE interface_class_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM interface_class WHERE id = n_id;

    change_description := format('Deleted interface_class(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'interface_class', 
        n_id, 
        change_description
    );

END;
$$;
 ~   DROP PROCEDURE public.proc_remove_interface_class(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17382 >   proc_remove_permitted_interface_connection(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_permitted_interface_connection(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within permitted_interface_connection table
    IF (public.fn_field_unique_valid('permitted_interface_connection', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "permitted_interface_connection" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM permitted_interface_connection WHERE id = n_id;

    change_description := format('Deleted permitted_interface_connection(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'permitted_interface_connection', 
        n_id, 
        change_description
    );

END;
$$;
 {   DROP PROCEDURE public.proc_remove_permitted_interface_connection(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17383 4   proc_remove_possible_state(text, text, bigint, text) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_possible_state(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within possible_state table
    IF (public.fn_field_unique_valid('possible_state', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "possible_state" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set possible_state_id = NULL in equipment_state table
            UPDATE equipment_state
            SET possible_state_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE possible_state_id = n_id;

            -- Set possible_state_id = NULL in connection_state table
            UPDATE connection_state
            SET possible_state_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE possible_state_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where possible_state_id = id in equipment_state table
            DELETE FROM equipment_state WHERE possible_state_id = n_id;

            -- Delete the records where possible_state_id = id in connection_state table
            DELETE FROM connection_state WHERE possible_state_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM possible_state WHERE id = n_id;

    change_description := format('Deleted possible_state(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'possible_state', 
        n_id, 
        change_description
    );

END;
$$;
 }   DROP PROCEDURE public.proc_remove_possible_state(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17384 .   proc_remove_property(text, text, bigint, text) 	   PROCEDURE     B  CREATE PROCEDURE public.proc_remove_property(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;
DECLARE item RECORD;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within property table
    IF (public.fn_field_unique_valid('property', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "property" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set property_id = NULL in resource_property table
            UPDATE resource_property
            SET property_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE property_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Set resource_property_id = NULL in property_value table
            FOR item IN SELECT * FROM resource_property WHERE property_id = n_id LOOP
                UPDATE property_value
                SET resource_property_id = NULL,
                    modified_at = CURRENT_TIMESTAMP
                WHERE resource_property_id = item.id;
            END LOOP;

            -- Delete the records where property_id = id in resource_property table
            DELETE FROM resource_property WHERE property_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM property WHERE id = n_id;

    change_description := format('Deleted property(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'property', 
        n_id, 
        change_description
    );

END;
$$;
 w   DROP PROCEDURE public.proc_remove_property(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17385 .   proc_remove_property_value(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_property_value(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within property_value table
    IF (public.fn_field_unique_valid('property_value', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "property_value" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM property_value WHERE id = n_id;

    change_description := format('Deleted property_value(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'property_value', 
        n_id, 
        change_description
    );

END;
$$;
 k   DROP PROCEDURE public.proc_remove_property_value(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17386 .   proc_remove_resource(text, text, bigint, text) 	   PROCEDURE       CREATE PROCEDURE public.proc_remove_resource(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;
DECLARE item RECORD;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within resource table
    IF (public.fn_field_unique_valid('resource', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "resource" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set resource_id = NULL in type_resource table
            UPDATE type_resource
            SET resource_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE resource_id = n_id;

            -- Set resource_id = NULL in resource_property table
            UPDATE resource_property
            SET resource_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE resource_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Set type_resource_id = NULL in type_interface table
            FOR item IN SELECT * FROM type_resource WHERE resource_id = n_id LOOP
                UPDATE type_interface
                SET type_resource_id = NULL,
                    modified_at = CURRENT_TIMESTAMP
                WHERE type_resource_id = item.id;
            END LOOP;

            -- Delete the records where resource_id = id in type_resource table
            DELETE FROM type_resource WHERE resource_id = n_id;

            -- Set resource_property_id = NULL in property_value table
            FOR item IN SELECT * FROM resource_property WHERE resource_id = n_id LOOP
                UPDATE property_value
                SET resource_property_id = NULL,
                    modified_at = CURRENT_TIMESTAMP
                WHERE resource_property_id = item.id;
            END LOOP;

            -- Delete the records where resource_id = id in resource_property table
            DELETE FROM resource_property WHERE resource_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM resource WHERE id = n_id;

    change_description := format('Deleted resource(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'resource', 
        n_id, 
        change_description
    );

END;
$$;
 w   DROP PROCEDURE public.proc_remove_resource(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17387 .   proc_remove_resource_group(text, text, bigint) 	   PROCEDURE     G  CREATE PROCEDURE public.proc_remove_resource_group(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within resource_group table
    IF (public.fn_field_unique_valid('resource_group', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "resource_group" table.', n_id;
        RETURN;
    END IF;

    -- Set resource_group_id = NULL in resource table
    UPDATE resource
    SET resource_group_id = NULL,
        modified_at = CURRENT_TIMESTAMP
    WHERE resource_group_id = n_id;
    
    -- Delete record in the table
    DELETE FROM resource_group WHERE id = n_id;

    change_description := format('Deleted resource group(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'resource_group', 
        n_id, 
        change_description
    );

END;
$$;
 k   DROP PROCEDURE public.proc_remove_resource_group(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17388 7   proc_remove_resource_property(text, text, bigint, text) 	   PROCEDURE       CREATE PROCEDURE public.proc_remove_resource_property(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within resource_property table
    IF (public.fn_field_unique_valid('resource_property', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "resource_property" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set resource_property_id = NULL in property_value table
            UPDATE property_value
            SET resource_property_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE resource_property_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where resource_property_id = id in property_value table
            DELETE FROM property_value WHERE resource_property_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM resource_property WHERE id = n_id;

    change_description := format('Deleted resource_property(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'resource_property', 
        n_id, 
        change_description
    );

END;
$$;
 �   DROP PROCEDURE public.proc_remove_resource_property(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �           1255    17389 /   proc_remove_system_settings(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_system_settings(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within system_settings table
    IF (public.fn_field_unique_valid('system_settings', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "system_settings" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM system_settings WHERE id = n_id;

    change_description := format('Deleted system_settings(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'system_settings', 
        n_id, 
        change_description
    );

END;
$$;
 l   DROP PROCEDURE public.proc_remove_system_settings(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17390 +   proc_remove_type_detail(text, text, bigint) 	   PROCEDURE     u  CREATE PROCEDURE public.proc_remove_type_detail(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within type_detail table
    IF (public.fn_field_unique_valid('type_detail', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "type_detail" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM type_detail WHERE id = n_id;

    change_description := format('Deleted type_detail(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'type_detail', 
        n_id, 
        change_description
    );

END;
$$;
 h   DROP PROCEDURE public.proc_remove_type_detail(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17391 .   proc_remove_type_interface(text, text, bigint) 	   PROCEDURE     �  CREATE PROCEDURE public.proc_remove_type_interface(IN n_modified_by text, IN n_reason text, IN n_id bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within type_interface table
    IF (public.fn_field_unique_valid('type_interface', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "type_interface" table.', n_id;
        RETURN;
    END IF;

    -- Delete record in the table
    DELETE FROM type_interface WHERE id = n_id;

    change_description := format('Deleted type_interface(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'type_interface', 
        n_id, 
        change_description
    );

END;
$$;
 k   DROP PROCEDURE public.proc_remove_type_interface(IN n_modified_by text, IN n_reason text, IN n_id bigint);
       public          postgres    false    6            �           1255    17392 3   proc_remove_type_resource(text, text, bigint, text) 	   PROCEDURE     �
  CREATE PROCEDURE public.proc_remove_type_resource(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text)
    LANGUAGE plpgsql
    AS $$

DECLARE change_description text;

BEGIN
    -- Check if user name is not empty or null
    IF (public.fn_text_field_valid(n_modified_by, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"modified_by" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if user name exists within table
    IF (public.fn_field_unique_valid('user', 'os_username', n_modified_by, NULL) = TRUE) THEN
        RAISE EXCEPTION 'modified_by = "%" does not exist in the "user" table.', n_modified_by;
        RETURN;
    END IF;

    -- Check if resason is not empty or null
    IF (public.fn_text_field_valid(n_reason, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be empty or null.';
        RETURN;
    END IF;
    -- Check if reason is greater than 5 characters
    IF (public.fn_text_field_valid(n_reason, 'length') = FALSE) THEN
        RAISE EXCEPTION '"reason" cannot be less than 5 characters.';
        RETURN;
    END IF;

    -- Check if id is not empty or null
    IF (public.fn_text_field_valid(CAST(n_id AS TEXT), 'empty') = FALSE) THEN
        RAISE EXCEPTION '"id" cannot be empty or null.';
        RETURN;
    END IF;

    -- Check if id exists within type_resource table
    IF (public.fn_field_unique_valid('type_resource', 'id', CAST(n_id AS TEXT), NULL) = TRUE) THEN
        RAISE EXCEPTION 'id = % does not exist in the "type_resource" table.', n_id;
        RETURN;
    END IF;

    -- Check if option is not empty or null
    IF (public.fn_text_field_valid(n_option, 'empty') = FALSE) THEN
        RAISE EXCEPTION '"option" cannot be empty or null.';
        RETURN;
    END IF;

    -- Delete the related records with id
    CASE
        WHEN n_option = 'orphan' THEN

            -- Set type_resource_id = NULL in type_interface table
            UPDATE type_interface
            SET type_resource_id = NULL,
                modified_at = CURRENT_TIMESTAMP
            WHERE type_resource_id = n_id;

        WHEN n_option = 'delete' THEN

            -- Delete the records where type_resource_id = id in type_interface table
            DELETE FROM type_interface WHERE type_resource_id = n_id;
        
        ELSE
            RAISE EXCEPTION 'Undefined option type. option should be "orphan" or "delete".';
    END CASE;

    -- Delete record in the table
    DELETE FROM type_resource WHERE id = n_id;

    change_description := format('Deleted type_resource(%s)', n_id);

    -- Insert a new record in general_history table
    CALL public.proc_add_general_history(
        n_modified_by,
        n_reason, 
        'type_resource', 
        n_id, 
        change_description
    );

END;
$$;
 |   DROP PROCEDURE public.proc_remove_type_resource(IN n_modified_by text, IN n_reason text, IN n_id bigint, IN n_option text);
       public          postgres    false    6            �            1259    17541 	   authority    TABLE     �   CREATE TABLE public.authority (
    id bigint NOT NULL,
    label text NOT NULL,
    description text NOT NULL,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
    DROP TABLE public.authority;
       public         heap    postgres    false    6                       0    0    TABLE authority    COMMENT     �   COMMENT ON TABLE public.authority IS 'This is the authority levels required for changing the value of a state of equipment and connections.';
          public          postgres    false    239                       0    0    COLUMN authority.label    COMMENT     e   COMMENT ON COLUMN public.authority.label IS 'a short, meaningful, label for the authority required';
          public          postgres    false    239                       0    0    COLUMN authority.description    COMMENT     l   COMMENT ON COLUMN public.authority.description IS 'a plain language description of the authority required';
          public          postgres    false    239                       0    0    COLUMN authority.comment    COMMENT     [   COMMENT ON COLUMN public.authority.comment IS 'a general comment, not normally displayed';
          public          postgres    false    239                       0    0    COLUMN authority.modified_at    COMMENT     \   COMMENT ON COLUMN public.authority.modified_at IS 'the last time this record was modified';
          public          postgres    false    239            1           1259    17961    all_authority    VIEW     �   CREATE VIEW public.all_authority AS
 SELECT au.id AS authority_id,
    au.label AS authority_label,
    au.description AS authority_description,
    au.comment AS authority_comment,
    au.modified_at AS authority_modified_at
   FROM public.authority au;
     DROP VIEW public.all_authority;
       public          michaelm    false    239    239    239    239    239    6                       0    0    VIEW all_authority    COMMENT     �   COMMENT ON VIEW public.all_authority IS 'Returns all the authorities required to change the value of an equipment or connection state.';
          public          michaelm    false    305            �            1259    17393 
   connection    TABLE     
  CREATE TABLE public.connection (
    id bigint NOT NULL,
    path public.ltree,
    use_parent_identifier boolean DEFAULT false NOT NULL,
    connection_type_id bigint,
    start_equipment_id bigint,
    start_interface_id bigint,
    end_equipment_id bigint,
    end_interface_id bigint,
    identifier text NOT NULL,
    description text,
    comment text,
    length double precision,
    is_approved boolean DEFAULT false NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL,
    origin_path public.ltree
);
    DROP TABLE public.connection;
       public         heap    postgres    false    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6                       0    0    TABLE connection    COMMENT     7  COMMENT ON TABLE public.connection IS 'Connections are used to join interfaces. It must be possible for a connection to be the path used to associate properties from resources at each end of the connection. This association may go through multiple connections. The start and end of a connection are aribtary.';
          public          postgres    false    215                       0    0    COLUMN connection.path    COMMENT     X   COMMENT ON COLUMN public.connection.path IS 'the hierarchical path of this connection';
          public          postgres    false    215                       0    0 '   COLUMN connection.use_parent_identifier    COMMENT     �   COMMENT ON COLUMN public.connection.use_parent_identifier IS 'include the parent identifier in the full identifier of this connection';
          public          postgres    false    215                       0    0 $   COLUMN connection.connection_type_id    COMMENT     n   COMMENT ON COLUMN public.connection.connection_type_id IS 'the record id of the associated connection class';
          public          postgres    false    215                       0    0 $   COLUMN connection.start_equipment_id    COMMENT     |   COMMENT ON COLUMN public.connection.start_equipment_id IS 'the record id of the equipment at the start of this connection';
          public          postgres    false    215                       0    0 $   COLUMN connection.start_interface_id    COMMENT     |   COMMENT ON COLUMN public.connection.start_interface_id IS 'the record id of the interface at the start of this connection';
          public          postgres    false    215                       0    0 "   COLUMN connection.end_equipment_id    COMMENT     x   COMMENT ON COLUMN public.connection.end_equipment_id IS 'the record id of the equipment at the end of this connection';
          public          postgres    false    215                       0    0 "   COLUMN connection.end_interface_id    COMMENT     x   COMMENT ON COLUMN public.connection.end_interface_id IS 'the record id of the interface at the end of this connection';
          public          postgres    false    215                       0    0    COLUMN connection.identifier    COMMENT       COMMENT ON COLUMN public.connection.identifier IS 'the indentifier of this connection, this is typically combined with the identifiers of the preceding connections in the path and possibly the start and end equipment identifiers to form the unique compound name of the connection';
          public          postgres    false    215                       0    0    COLUMN connection.description    COMMENT     f   COMMENT ON COLUMN public.connection.description IS 'a plain language description of this connection';
          public          postgres    false    215                       0    0    COLUMN connection.comment    COMMENT     \   COMMENT ON COLUMN public.connection.comment IS 'a general comment, not normally displayed';
          public          postgres    false    215                       0    0    COLUMN connection.length    COMMENT     Z   COMMENT ON COLUMN public.connection.length IS 'the length of this connection, in metres';
          public          postgres    false    215                       0    0    COLUMN connection.is_approved    COMMENT     Z   COMMENT ON COLUMN public.connection.is_approved IS 'this connection is approved for use';
          public          postgres    false    215                       0    0    COLUMN connection.modified_at    COMMENT     ]   COMMENT ON COLUMN public.connection.modified_at IS 'the last time this record was modified';
          public          postgres    false    215            �            1259    17400    all_connection_series    VIEW     �  CREATE VIEW public.all_connection_series AS
 WITH RECURSIVE cp_tree(id, downstream_id, series) AS (
         SELECT connection.id,
            downstream.downstream_id,
            (((connection.id)::text)::public.ltree OPERATOR(public.||) ((downstream.downstream_id)::text)::public.ltree) AS series
           FROM (public.connection
             LEFT JOIN LATERAL public.downstream_connection(connection.id) downstream(downstream_id) ON (true))
        UNION ALL
         SELECT cp_tree_1.id,
            downstream.downstream_id,
            (cp_tree_1.series OPERATOR(public.||) (downstream.downstream_id)::text) AS series
           FROM (cp_tree cp_tree_1
             LEFT JOIN LATERAL public.downstream_connection(cp_tree_1.downstream_id) downstream(downstream_id) ON (true))
          WHERE (downstream.downstream_id IS NOT NULL)
        )
 SELECT cp_tree.series
   FROM cp_tree
  WHERE (cp_tree.series IS NOT NULL)
UNION
 SELECT ((connection.id)::text)::public.ltree AS series
   FROM public.connection;
 (   DROP VIEW public.all_connection_series;
       public          postgres    false    2    2    6    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    2    6    6    2    6    2    6    2    6    6    2    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    447    215    2    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    6    2    2    6    6    2    6    2    6    2    6                        0    0    VIEW all_connection_series    COMMENT     (  COMMENT ON VIEW public.all_connection_series IS 'This view returns all the connection series paths. This is not based on the connection hierarchy, rather the series of downstream connections that share starting equipment/interface with the ending equipment/interface of the current connection.';
          public          postgres    false    216            �            1259    17405    all_connected_interface    VIEW     �  CREATE VIEW public.all_connected_interface AS
 SELECT start_c.id AS start_connection_id,
    start_c.path AS start_connection_path,
    start_c.start_equipment_id,
    start_c.start_interface_id,
    all_connection_series.series AS connection_series,
    end_c.id AS end_connection_id,
    end_c.path AS end_connection_path,
    end_c.end_equipment_id,
    end_c.end_interface_id
   FROM ((public.connection start_c
     JOIN public.all_connection_series ON ((start_c.id = ((public.subpath(all_connection_series.series, 0, 1))::text)::bigint)))
     JOIN public.connection end_c ON ((end_c.id = ((public.subpath(all_connection_series.series, '-1'::integer, 1))::text)::bigint)));
 *   DROP VIEW public.all_connected_interface;
       public          postgres    false    215    215    216    2    2    2    6    6    2    6    2    6    2    6    6    215    215    215    215    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            !           0    0    VIEW all_connected_interface    COMMENT     �   COMMENT ON VIEW public.all_connected_interface IS 'Only full length connections between interfaces. For series, or multi-level, connections this does not include the intermediate  connections';
          public          postgres    false    217            �            1259    17410    connection_type    TABLE     a  CREATE TABLE public.connection_type (
    id bigint NOT NULL,
    path public.ltree,
    label text NOT NULL,
    model text,
    modifier text,
    manufacturer text,
    description text NOT NULL,
    comment text,
    is_approved boolean NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL,
    is_hidden boolean DEFAULT false NOT NULL
);
 #   DROP TABLE public.connection_type;
       public         heap    postgres    false    2    2    6    6    2    6    2    6    2    6    6            "           0    0    TABLE connection_type    COMMENT     #  COMMENT ON TABLE public.connection_type IS 'The classification of connections allows checking that the connection is suitable for use with specific interfaces. This table has a hierarchical structure so that similar classes may be grouped and inherit properties from the ancestor classes.';
          public          postgres    false    218            #           0    0    COLUMN connection_type.path    COMMENT     t   COMMENT ON COLUMN public.connection_type.path IS 'the hierarchical path of the parent to this type of connections';
          public          postgres    false    218            $           0    0    COLUMN connection_type.label    COMMENT     �   COMMENT ON COLUMN public.connection_type.label IS 'a short label for this type of connections, eg instrumentation cable, pipe';
          public          postgres    false    218            %           0    0    COLUMN connection_type.model    COMMENT     |   COMMENT ON COLUMN public.connection_type.model IS 'the model, part number, manufacturers code for this type of connection';
          public          postgres    false    218            &           0    0    COLUMN connection_type.modifier    COMMENT     �   COMMENT ON COLUMN public.connection_type.modifier IS 'a short text modifier that can be added to the connection identifier when cuilding the compound identifier for connections of this type';
          public          postgres    false    218            '           0    0 #   COLUMN connection_type.manufacturer    COMMENT     i   COMMENT ON COLUMN public.connection_type.manufacturer IS 'the manufacturer of this type of connections';
          public          postgres    false    218            (           0    0 "   COLUMN connection_type.description    COMMENT     v   COMMENT ON COLUMN public.connection_type.description IS 'a plain language description of this class of connections.';
          public          postgres    false    218            )           0    0    COLUMN connection_type.comment    COMMENT     a   COMMENT ON COLUMN public.connection_type.comment IS 'a general comment, not normally displayed';
          public          postgres    false    218            *           0    0 "   COLUMN connection_type.is_approved    COMMENT     g   COMMENT ON COLUMN public.connection_type.is_approved IS 'this type of connection is approved for use';
          public          postgres    false    218            +           0    0 "   COLUMN connection_type.modified_at    COMMENT     b   COMMENT ON COLUMN public.connection_type.modified_at IS 'the last time this record was modified';
          public          postgres    false    218            ,           0    0     COLUMN connection_type.is_hidden    COMMENT     �   COMMENT ON COLUMN public.connection_type.is_hidden IS 'This type of connection is hidden from the display hierarchy of connections. This typically means this connection represents a core within a cable (which should be another connection).';
          public          postgres    false    218            *           1259    17900    all_connection    VIEW     V  CREATE VIEW public.all_connection AS
 SELECT connection.id AS connection_id,
    connection.path AS connection_path,
    public.nlevel(connection.path) AS connection_tree_level,
    public.fn_connection_identifier_location(connection.path) AS connection_identifier_location,
    public.fn_connection_identifier(connection.path) AS connection_identifier,
    connection.identifier AS connection_local_identifier,
    connection_type.id AS connection_type_id,
    connection_type.description AS connection_type_description,
    connection_type.comment AS connection_type_comment,
    connection.length AS connection_length,
    connection.description AS connection_description,
    connection.is_approved AS connection_is_approved,
    connection.comment AS connection_comment,
    connection.start_equipment_id,
    connection.start_interface_id,
    connection.end_equipment_id,
    connection.end_interface_id,
    connection.use_parent_identifier AS connection_use_parent_identifier
   FROM (public.connection
     LEFT JOIN public.connection_type ON ((connection.connection_type_id = connection_type.id)));
 !   DROP VIEW public.all_connection;
       public          postgres    false    215    215    215    218    218    215    218    2    6    2    2    6    6    2    6    2    6    2    6    474    473    215    215    215    215    215    215    215    215    215    2    2    6    6    2    6    2    6    2    6    6            -           0    0    VIEW all_connection    COMMENT     �   COMMENT ON VIEW public.all_connection IS 'More detailed information about all connections, including the connection type information';
          public          postgres    false    298            �            1259    17420 	   equipment    TABLE     �  CREATE TABLE public.equipment (
    id bigint NOT NULL,
    path public.ltree,
    use_parent_identifier boolean DEFAULT true NOT NULL,
    location_path public.ltree,
    type_id bigint,
    identifier text NOT NULL,
    description text,
    is_approved boolean DEFAULT false NOT NULL,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL,
    origin_path public.ltree
);
    DROP TABLE public.equipment;
       public         heap    postgres    false    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6            .           0    0    COLUMN equipment.id    COMMENT     F   COMMENT ON COLUMN public.equipment.id IS 'should be SERIAL datatype';
          public          postgres    false    219            /           0    0    COLUMN equipment.path    COMMENT     �   COMMENT ON COLUMN public.equipment.path IS 'the hierarchical path of the parent to this equipment (typically the parent is in the context of the function, or process, of the equipment)';
          public          postgres    false    219            0           0    0 &   COLUMN equipment.use_parent_identifier    COMMENT     �   COMMENT ON COLUMN public.equipment.use_parent_identifier IS 'include the parent identifier in the full identifier of this piece of equipment';
          public          postgres    false    219            1           0    0    COLUMN equipment.location_path    COMMENT     o   COMMENT ON COLUMN public.equipment.location_path IS 'the hierarchical path of the location of this equipment';
          public          postgres    false    219            2           0    0    COLUMN equipment.type_id    COMMENT     �   COMMENT ON COLUMN public.equipment.type_id IS 'pointer to the equipment_type table for the equipment this is a specific instance of';
          public          postgres    false    219            3           0    0    COLUMN equipment.identifier    COMMENT     �   COMMENT ON COLUMN public.equipment.identifier IS 'portion of the equipment label that is just for this equipment, the full label wll include parent and possibly type information';
          public          postgres    false    219            4           0    0    COLUMN equipment.description    COMMENT     `   COMMENT ON COLUMN public.equipment.description IS 'the description of this piece of equipment';
          public          postgres    false    219            5           0    0    COLUMN equipment.is_approved    COMMENT     X   COMMENT ON COLUMN public.equipment.is_approved IS 'this equipment is approved for use';
          public          postgres    false    219            �            1259    17427    all_equipment    VIEW       CREATE VIEW public.all_equipment AS
 SELECT equipment.id AS equipment_id,
    equipment.path AS equipment_path,
    public.nlevel(equipment.path) AS equipment_tree_level,
    public.fn_equipment_identifier_sort(equipment.path) AS equipment_sort_identifier,
    public.fn_equipment_identifier(equipment.path) AS equipment_full_identifier,
    equipment.location_path AS equipment_location_path,
    'future use'::text AS equipment_location_identifier,
    equipment.identifier AS equipment_local_identifier,
    equipment.type_id,
    equipment.description AS equipment_description,
    equipment.is_approved AS equipment_is_approved,
    equipment.comment AS equipment_comment,
    equipment.use_parent_identifier AS equipment_use_parent_identifier
   FROM public.equipment;
     DROP VIEW public.all_equipment;
       public          postgres    false    219    219    219    409    411    219    219    219    219    219    219    2    6    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            6           0    0    VIEW all_equipment    COMMENT     �   COMMENT ON VIEW public.all_equipment IS 'This view returns all the equipment tree with sort string, node depth and display identifier.';
          public          postgres    false    220            4           1259    17992    all_connection_detail    VIEW     w  CREATE VIEW public.all_connection_detail AS
 SELECT connection.id AS connection_id,
    connection.path AS connection_path,
    public.nlevel(connection.path) AS connection_tree_level,
    public.fn_connection_identifier_location(connection.path) AS connection_identifier_location,
    public.fn_connection_identifier(connection.path) AS connection_identifier,
    connection.identifier AS connection_local_identifier,
    connection_type.id AS connection_type_id,
    connection_type.description AS connection_type_description,
    connection_type.is_hidden AS connection_type_is_hidden,
    connection_type.comment AS connection_type_comment,
    connection.description AS connection_description,
    connection.length AS connection_length,
    connection.is_approved AS connection_is_approved,
    connection.comment AS connection_comment,
    start_equip.equipment_id AS start_equipment_id,
    start_equip.equipment_path AS start_equipment_path,
    start_equip.equipment_tree_level AS start_equipment_tree_level,
    start_equip.equipment_sort_identifier AS start_equipment_sort_identifier,
    start_equip.equipment_full_identifier AS start_equipment_full_identifier,
    start_equip.equipment_location_path AS start_equipment_location_path,
    start_equip.equipment_location_identifier AS start_equipment_location_identifier,
    start_equip.equipment_local_identifier AS start_equipment_local_identifier,
    start_equip.type_id AS start_equipment_type_id,
    start_equip.equipment_description AS start_equipment_description,
    start_equip.equipment_is_approved AS start_equipment_is_approved,
    start_equip.equipment_comment AS start_equipment_comment,
    connection.start_interface_id,
    end_equip.equipment_id AS end_equipment_id,
    end_equip.equipment_path AS end_equipment_path,
    end_equip.equipment_tree_level AS end_equipment_tree_level,
    end_equip.equipment_sort_identifier AS end_equipment_sort_identifier,
    end_equip.equipment_full_identifier AS end_equipment_full_identifier,
    end_equip.equipment_location_path AS end_equipment_location_path,
    end_equip.equipment_location_identifier AS end_equipment_location_identifier,
    end_equip.equipment_local_identifier AS end_equipment_local_identifier,
    end_equip.type_id AS end_equipment_type_id,
    end_equip.equipment_description AS end_equipment_description,
    end_equip.equipment_is_approved AS end_equipment_is_approved,
    end_equip.equipment_comment AS end_equipment_comment,
    connection.end_interface_id,
    connection.use_parent_identifier AS connection_use_parent_identifier
   FROM (((public.connection
     LEFT JOIN public.connection_type ON ((connection.connection_type_id = connection_type.id)))
     LEFT JOIN public.all_equipment start_equip ON ((connection.start_equipment_id = start_equip.equipment_id)))
     LEFT JOIN public.all_equipment end_equip ON ((connection.end_equipment_id = end_equip.equipment_id)));
 (   DROP VIEW public.all_connection_detail;
       public          postgres    false    220    220    220    220    220    220    220    220    220    220    220    220    218    218    218    218    215    215    215    215    215    215    215    215    215    215    215    215    215    473    474    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            7           0    0    VIEW all_connection_detail    COMMENT       COMMENT ON VIEW public.all_connection_detail IS 'The properties available over an connection (single or multi-path series). Only interfaces flagged as active are returned. An interface that is not "active" cannot be used to identify connected properties.';
          public          postgres    false    308            �            1259    17436    equipment_type    TABLE     ^  CREATE TABLE public.equipment_type (
    id bigint NOT NULL,
    path public.ltree,
    label text NOT NULL,
    model text,
    modifier text,
    manufacturer text,
    description text NOT NULL,
    comment text,
    is_approved boolean DEFAULT false NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL,
    origin_path public.ltree
);
 "   DROP TABLE public.equipment_type;
       public         heap    postgres    false    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            8           0    0    COLUMN equipment_type.path    COMMENT     n   COMMENT ON COLUMN public.equipment_type.path IS 'the hierarchical path of the parent to this equipment type';
          public          postgres    false    221            9           0    0    COLUMN equipment_type.label    COMMENT     \   COMMENT ON COLUMN public.equipment_type.label IS 'a sort label for this type of equipment';
          public          postgres    false    221            :           0    0 !   COLUMN equipment_type.is_approved    COMMENT     e   COMMENT ON COLUMN public.equipment_type.is_approved IS 'this type of equipment is approved for use';
          public          postgres    false    221            �            1259    17442    type_resource    TABLE     �   CREATE TABLE public.type_resource (
    id bigint NOT NULL,
    type_id bigint,
    resource_id bigint,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 !   DROP TABLE public.type_resource;
       public         heap    postgres    false    6            ;           0    0    COLUMN type_resource.type_id    COMMENT     T   COMMENT ON COLUMN public.type_resource.type_id IS 'id to the equipment_type table';
          public          postgres    false    222            <           0    0     COLUMN type_resource.resource_id    COMMENT     R   COMMENT ON COLUMN public.type_resource.resource_id IS 'id to the resource table';
          public          postgres    false    222            �            1259    17447    all_type_resource    VIEW     �  CREATE VIEW public.all_type_resource AS
 SELECT type_resource.id,
    et.id AS type_id,
    et.path AS type_path,
    type_resource.type_id AS definition_type_id,
    type_resource.resource_id,
    type_resource.comment
   FROM ((public.equipment_type et
     LEFT JOIN public.equipment_type et_ancestor ON ((et.path OPERATOR(public.<@) et_ancestor.path)))
     JOIN public.type_resource ON ((type_resource.type_id = et_ancestor.id)));
 $   DROP VIEW public.all_type_resource;
       public          postgres    false    222    222    222    222    221    221    2    2    2    6    6    2    6    2    6    2    6    6    2    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6    6            =           0    0    VIEW all_type_resource    COMMENT     �   COMMENT ON VIEW public.all_type_resource IS 'This view returns all the equipment type resources that are defined for an equipment type (including those inherited from ancestor types)';
          public          postgres    false    223            �            1259    17458    attribute_class    TABLE     �   CREATE TABLE public.attribute_class (
    id bigint NOT NULL,
    label text NOT NULL,
    description text NOT NULL,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 #   DROP TABLE public.attribute_class;
       public         heap    postgres    false    6            >           0    0    TABLE attribute_class    COMMENT     �   COMMENT ON TABLE public.attribute_class IS 'The attribute classes are groups of resource attributes (properties and interfaces) that are used to organise properties and interfaces into managable groups.';
          public          postgres    false    225            ?           0    0    COLUMN attribute_class.label    COMMENT     \   COMMENT ON COLUMN public.attribute_class.label IS 'the lable for this class of interfaces';
          public          postgres    false    225            @           0    0 "   COLUMN attribute_class.description    COMMENT     g   COMMENT ON COLUMN public.attribute_class.description IS 'the description of this class of interfaces';
          public          postgres    false    225            �            1259    17452 	   interface    TABLE     2  CREATE TABLE public.interface (
    id bigint NOT NULL,
    attribute_class_id bigint,
    connecting_attribute_class_id bigint,
    identifier text NOT NULL,
    description text,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL,
    is_intermediate boolean DEFAULT true NOT NULL
);
    DROP TABLE public.interface;
       public         heap    postgres    false    6            A           0    0 #   COLUMN interface.attribute_class_id    COMMENT     �   COMMENT ON COLUMN public.interface.attribute_class_id IS 'the id of the classification of this type of interface (maybe 4-20mA output, 3 phase 415V etc)';
          public          postgres    false    224            B           0    0 .   COLUMN interface.connecting_attribute_class_id    COMMENT     �   COMMENT ON COLUMN public.interface.connecting_attribute_class_id IS 'the id of the classification that this interface is intended to connect with  (maybe 4-20mA input, 3 phase 415V etc)';
          public          postgres    false    224            C           0    0    COLUMN interface.identifier    COMMENT     o   COMMENT ON COLUMN public.interface.identifier IS 'the physical identifier on this interface on the equipment';
          public          postgres    false    224            D           0    0     COLUMN interface.is_intermediate    COMMENT     �   COMMENT ON COLUMN public.interface.is_intermediate IS 'This interface is an intermediate point of a connection path, these terminals should be permitted to have >1 connecction, this may not be required';
          public          postgres    false    224            �            1259    17463    resource    TABLE     �   CREATE TABLE public.resource (
    id bigint NOT NULL,
    resource_group_id bigint,
    modifier text,
    description text NOT NULL,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
    DROP TABLE public.resource;
       public         heap    postgres    false    6            E           0    0 !   COLUMN resource.resource_group_id    COMMENT     i   COMMENT ON COLUMN public.resource.resource_group_id IS 'id to the organisational grouping of resources';
          public          postgres    false    226            F           0    0    COLUMN resource.modifier    COMMENT     �   COMMENT ON COLUMN public.resource.modifier IS 'the modifier applied to the equipment identifier to create a unique resource identifier.';
          public          postgres    false    226            �            1259    17468    resource_group    TABLE     �   CREATE TABLE public.resource_group (
    id bigint NOT NULL,
    label text NOT NULL,
    description text NOT NULL,
    comment text,
    is_reportable boolean DEFAULT true NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL
);
 "   DROP TABLE public.resource_group;
       public         heap    postgres    false    6            G           0    0    COLUMN resource_group.label    COMMENT     U   COMMENT ON COLUMN public.resource_group.label IS 'label of this group of resources';
          public          postgres    false    227            H           0    0 !   COLUMN resource_group.description    COMMENT     a   COMMENT ON COLUMN public.resource_group.description IS 'description of this group of resources';
          public          postgres    false    227            I           0    0 #   COLUMN resource_group.is_reportable    COMMENT     w   COMMENT ON COLUMN public.resource_group.is_reportable IS 'it wll be able to generate a report on this resource group';
          public          postgres    false    227            �            1259    17474    type_interface    TABLE     �   CREATE TABLE public.type_interface (
    id bigint NOT NULL,
    type_resource_id bigint,
    interface_id bigint,
    comment text,
    is_active boolean DEFAULT true NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL
);
 "   DROP TABLE public.type_interface;
       public         heap    postgres    false    6            J           0    0 &   COLUMN type_interface.type_resource_id    COMMENT     �   COMMENT ON COLUMN public.type_interface.type_resource_id IS 'the link to the equipment type and resource type for this interface';
          public          postgres    false    228            K           0    0 "   COLUMN type_interface.interface_id    COMMENT     f   COMMENT ON COLUMN public.type_interface.interface_id IS 'the id of the associated interface record.';
          public          postgres    false    228            L           0    0    COLUMN type_interface.is_active    COMMENT     �   COMMENT ON COLUMN public.type_interface.is_active IS 'an active interface is one where information about the associated resource is available. A power supply interface is not usually considered an active interface';
          public          postgres    false    228            �            1259    17480    type_interface_detail    VIEW     �  CREATE VIEW public.type_interface_detail AS
 SELECT equipment_type.id AS type_id,
    all_type_resource.id AS type_resource_id,
    all_type_resource.comment AS type_resource_comment,
    resource.id AS resource_id,
    resource.modifier AS resource_modifier,
    resource.description AS resource_description,
    resource.comment AS resource_comment,
    resource_group.id AS resource_group_id,
    resource_group.label AS resource_group_label,
    resource_group.description AS resource_group_description,
    resource_group.is_reportable AS resource_is_reportable,
    type_interface.id AS type_interface_id,
    type_interface.comment AS type_interface_comment,
    type_interface.is_active AS type_interface_is_active,
    interface.id AS interface_id,
    interface.identifier AS interface_identifier,
    interface.description AS interface_description,
    interface.comment AS interface_comment,
    attribute_class.id AS interface_class_id,
    attribute_class.label AS interface_class_label,
    attribute_class.description AS interface_class_description,
    attribute_class.comment AS interface_class_comment,
    connecting_class.id AS connecting_class_id,
    connecting_class.label AS connecting_class_label,
    connecting_class.description AS connecting_class_description,
    connecting_class.comment AS connecting_class_comment
   FROM (((((((public.interface
     JOIN public.attribute_class ON ((attribute_class.id = interface.attribute_class_id)))
     LEFT JOIN public.attribute_class connecting_class ON ((connecting_class.id = interface.connecting_attribute_class_id)))
     JOIN public.type_interface ON ((type_interface.interface_id = interface.id)))
     JOIN public.all_type_resource ON ((all_type_resource.id = type_interface.type_resource_id)))
     JOIN public.resource ON ((resource.id = all_type_resource.resource_id)))
     JOIN public.resource_group ON ((resource.resource_group_id = resource_group.id)))
     JOIN public.equipment_type ON ((all_type_resource.type_id = equipment_type.id)));
 (   DROP VIEW public.type_interface_detail;
       public          postgres    false    225    226    223    223    221    225    224    227    224    224    224    225    225    226    226    226    226    227    228    228    228    228    228    227    227    224    224    223    223    6            M           0    0    VIEW type_interface_detail    COMMENT     |   COMMENT ON VIEW public.type_interface_detail IS 'Detailed information about all interfaces present on types of equipment.';
          public          postgres    false    229            �            1259    17485    all_equipment_interface    VIEW     �	  CREATE VIEW public.all_equipment_interface AS
 SELECT all_equipment.equipment_id,
    all_equipment.equipment_path,
    all_equipment.equipment_tree_level,
    all_equipment.equipment_sort_identifier,
    all_equipment.equipment_full_identifier,
    all_equipment.equipment_location_path,
    all_equipment.equipment_location_identifier,
    all_equipment.equipment_local_identifier,
    all_equipment.type_id,
    all_equipment.equipment_description,
    all_equipment.equipment_is_approved,
    all_equipment.equipment_comment,
    type_interface_detail.type_resource_id,
    type_interface_detail.type_resource_comment,
    type_interface_detail.resource_id,
    public.fn_resource_identifier(all_equipment.equipment_sort_identifier, type_interface_detail.resource_modifier) AS resource_sort_identifier,
    public.fn_resource_identifier(all_equipment.equipment_full_identifier, type_interface_detail.resource_modifier) AS resource_full_identifier,
    type_interface_detail.resource_modifier,
    type_interface_detail.resource_description,
    type_interface_detail.resource_comment,
    type_interface_detail.resource_group_id,
    type_interface_detail.resource_group_label,
    type_interface_detail.resource_group_description,
    type_interface_detail.resource_is_reportable,
    type_interface_detail.type_interface_id,
    type_interface_detail.type_interface_comment,
    type_interface_detail.type_interface_is_active,
    type_interface_detail.interface_id,
    public.fn_interface_identifier(all_equipment.equipment_sort_identifier, type_interface_detail.interface_identifier) AS interface_sort_identifier,
    public.fn_interface_identifier(all_equipment.equipment_full_identifier, type_interface_detail.interface_identifier) AS interface_full_identifier,
    type_interface_detail.interface_identifier,
    type_interface_detail.interface_description,
    type_interface_detail.interface_comment,
    type_interface_detail.interface_class_id,
    type_interface_detail.interface_class_label,
    type_interface_detail.interface_class_description,
    type_interface_detail.interface_class_comment,
    type_interface_detail.connecting_class_id,
    type_interface_detail.connecting_class_label,
    type_interface_detail.connecting_class_description,
    type_interface_detail.connecting_class_comment
   FROM (public.all_equipment
     JOIN public.type_interface_detail ON ((all_equipment.type_id = type_interface_detail.type_id)));
 *   DROP VIEW public.all_equipment_interface;
       public          postgres    false    229    416    413    220    220    220    220    220    220    220    220    220    220    220    220    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    229    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            N           0    0    VIEW all_equipment_interface    COMMENT     b   COMMENT ON VIEW public.all_equipment_interface IS 'Return all the interfaces for all equipment.';
          public          postgres    false    230            5           1259    17998    all_connection_interface    VIEW     o  CREATE VIEW public.all_connection_interface AS
 SELECT all_connection_detail.connection_id,
    all_connection_detail.connection_path,
    all_connection_detail.connection_tree_level,
    all_connection_detail.connection_identifier_location,
    all_connection_detail.connection_identifier,
    all_connection_detail.connection_local_identifier,
    all_connection_detail.connection_type_id,
    all_connection_detail.connection_type_is_hidden,
    all_connection_detail.connection_type_description,
    all_connection_detail.connection_type_comment,
    all_connection_detail.connection_description,
    all_connection_detail.connection_length,
    all_connection_detail.connection_is_approved,
    all_connection_detail.connection_comment,
    all_connection_detail.start_equipment_id,
    all_connection_detail.start_equipment_path,
    all_connection_detail.start_equipment_tree_level,
    all_connection_detail.start_equipment_sort_identifier,
    all_connection_detail.start_equipment_full_identifier,
    all_connection_detail.start_equipment_location_path,
    all_connection_detail.start_equipment_location_identifier,
    all_connection_detail.start_equipment_local_identifier,
    all_connection_detail.start_equipment_type_id,
    all_connection_detail.start_equipment_description,
    all_connection_detail.start_equipment_is_approved,
    all_connection_detail.start_equipment_comment,
    start_if.type_resource_id AS start_type_resource_id,
    start_if.type_resource_comment AS start_type_resource_comment,
    start_if.resource_id AS start_resource_id,
    start_if.resource_sort_identifier AS start_resource_sort_identifier,
    start_if.resource_full_identifier AS start_resource_full_identifier,
    start_if.resource_modifier AS start_resource_modifier,
    start_if.resource_description AS start_resource_description,
    start_if.resource_comment AS start_resource_comment,
    start_if.resource_group_id AS start_resource_group_id,
    start_if.resource_group_label AS start_resource_group_label,
    start_if.resource_group_description AS start_resource_group_description,
    start_if.resource_is_reportable AS start_resource_is_reportable,
    start_if.type_interface_id AS start_type_interface_id,
    start_if.type_interface_comment AS start_type_interface_comment,
    start_if.type_interface_is_active AS start_type_interface_is_active,
    start_if.interface_id AS start_interface_id,
    start_if.interface_sort_identifier AS start_interface_sort_identifier,
    start_if.interface_full_identifier AS start_interface_full_identifier,
    start_if.interface_identifier AS start_interface_identifier,
    start_if.interface_description AS start_interface_description,
    start_if.interface_comment AS start_interface_comment,
    start_if.interface_class_id AS start_interface_class_id,
    start_if.interface_class_label AS start_interface_class_label,
    start_if.interface_class_description AS start_interface_class_description,
    start_if.interface_class_comment AS start_interface_class_comment,
    start_if.connecting_class_id AS start_connecting_class_id,
    start_if.connecting_class_label AS start_connecting_class_label,
    start_if.connecting_class_description AS start_connecting_class_description,
    start_if.connecting_class_comment AS start_connecting_class_comment,
    all_connection_detail.end_equipment_id,
    all_connection_detail.end_equipment_path,
    all_connection_detail.end_equipment_tree_level,
    all_connection_detail.end_equipment_sort_identifier,
    all_connection_detail.end_equipment_full_identifier,
    all_connection_detail.end_equipment_location_path,
    all_connection_detail.end_equipment_location_identifier,
    all_connection_detail.end_equipment_local_identifier,
    all_connection_detail.end_equipment_type_id,
    all_connection_detail.end_equipment_description,
    all_connection_detail.end_equipment_is_approved,
    all_connection_detail.end_equipment_comment,
    end_if.type_resource_id AS end_type_resource_id,
    end_if.type_resource_comment AS end_type_resource_comment,
    end_if.resource_id AS end_resource_id,
    end_if.resource_sort_identifier AS end_resource_sort_identifier,
    end_if.resource_full_identifier AS end_resource_full_identifier,
    end_if.resource_modifier AS end_resource_modifier,
    end_if.resource_description AS end_resource_description,
    end_if.resource_comment AS end_resource_comment,
    end_if.resource_group_id AS end_resource_group_id,
    end_if.resource_group_label AS end_resource_group_label,
    end_if.resource_group_description AS end_resource_group_description,
    end_if.resource_is_reportable AS end_resource_is_reportable,
    end_if.type_interface_id AS end_type_interface_id,
    end_if.type_interface_comment AS end_type_interface_comment,
    end_if.type_interface_is_active AS end_type_interface_is_active,
    end_if.interface_id AS end_interface_id,
    end_if.interface_sort_identifier AS end_interface_sort_identifier,
    end_if.interface_full_identifier AS end_interface_full_identifier,
    end_if.interface_identifier AS end_interface_identifier,
    end_if.interface_description AS end_interface_description,
    end_if.interface_comment AS end_interface_comment,
    end_if.interface_class_id AS end_interface_class_id,
    end_if.interface_class_label AS end_interface_class_label,
    end_if.interface_class_description AS end_interface_class_description,
    end_if.interface_class_comment AS end_interface_class_comment,
    end_if.connecting_class_id AS end_connecting_class_id,
    end_if.connecting_class_label AS end_connecting_class_label,
    end_if.connecting_class_description AS end_connecting_class_description,
    end_if.connecting_class_comment AS end_connecting_class_comment,
    all_connection_detail.connection_use_parent_identifier
   FROM ((public.all_connection_detail
     LEFT JOIN public.all_equipment_interface start_if ON (((all_connection_detail.start_equipment_id = start_if.equipment_id) AND (all_connection_detail.start_interface_id = start_if.interface_id))))
     LEFT JOIN public.all_equipment_interface end_if ON (((all_connection_detail.end_equipment_id = end_if.equipment_id) AND (all_connection_detail.end_interface_id = end_if.interface_id))));
 +   DROP VIEW public.all_connection_interface;
       public          postgres    false    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    308    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            O           0    0    VIEW all_connection_interface    COMMENT     w   COMMENT ON VIEW public.all_connection_interface IS 'Start and end interface information for all defined connections,';
          public          postgres    false    309            &           1259    17855    connection_commercial    TABLE     3  CREATE TABLE public.connection_commercial (
    id bigint NOT NULL,
    connection_id bigint,
    quote_reference text,
    quote_price double precision,
    lead_time_days integer,
    purchase_order_date date,
    purchase_order_reference text,
    due_date date,
    received_date date,
    location text,
    unique_code text,
    installed_date date,
    warranty_end_date date,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL,
    design_approved date,
    fat_complete date,
    sat_complete date,
    commissioning_complete date
);
 )   DROP TABLE public.connection_commercial;
       public         heap    postgres    false    6            P           0    0 *   COLUMN connection_commercial.connection_id    COMMENT        COMMENT ON COLUMN public.connection_commercial.connection_id IS 'the record id of the connection associated with this record';
          public          postgres    false    294            Q           0    0 ,   COLUMN connection_commercial.quote_reference    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.quote_reference IS 'the code, number or reference of the quotaton that included this connection';
          public          postgres    false    294            R           0    0 (   COLUMN connection_commercial.quote_price    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.quote_price IS 'the price for this connection in the quotation referenced above';
          public          postgres    false    294            S           0    0 +   COLUMN connection_commercial.lead_time_days    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.lead_time_days IS 'the expected number of days between ordering and receiving this connection';
          public          postgres    false    294            T           0    0 0   COLUMN connection_commercial.purchase_order_date    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.purchase_order_date IS 'the issue date of the purchase order that included this connection';
          public          postgres    false    294            U           0    0 5   COLUMN connection_commercial.purchase_order_reference    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.purchase_order_reference IS 'the code, number or reference of the purchase order that included this connection';
          public          postgres    false    294            V           0    0 %   COLUMN connection_commercial.due_date    COMMENT     h   COMMENT ON COLUMN public.connection_commercial.due_date IS 'the date this connection is due to arrive';
          public          postgres    false    294            W           0    0 *   COLUMN connection_commercial.received_date    COMMENT     i   COMMENT ON COLUMN public.connection_commercial.received_date IS 'the date this connection was received';
          public          postgres    false    294            X           0    0 %   COLUMN connection_commercial.location    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.location IS 'a short text description of the current location of this connection, typically used for pre-installation tracking';
          public          postgres    false    294            Y           0    0 (   COLUMN connection_commercial.unique_code    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.unique_code IS 'a unique code, serial number, batch code for the material this connection is made from';
          public          postgres    false    294            Z           0    0 +   COLUMN connection_commercial.installed_date    COMMENT     �   COMMENT ON COLUMN public.connection_commercial.installed_date IS 'date the connection was installed, typically this is the start of the warranty period';
          public          postgres    false    294            [           0    0 .   COLUMN connection_commercial.warranty_end_date    COMMENT     q   COMMENT ON COLUMN public.connection_commercial.warranty_end_date IS 'date the manufacturer''s warranty expires';
          public          postgres    false    294            \           0    0 $   COLUMN connection_commercial.comment    COMMENT     g   COMMENT ON COLUMN public.connection_commercial.comment IS 'a general comment, not normally displayed';
          public          postgres    false    294            ]           0    0 (   COLUMN connection_commercial.modified_at    COMMENT     h   COMMENT ON COLUMN public.connection_commercial.modified_at IS 'the last time this record was modified';
          public          postgres    false    294            ,           1259    17931    connection_purchasing_detail    VIEW     �  CREATE VIEW public.connection_purchasing_detail AS
 SELECT cn.id AS connection_id,
    cn.path AS connection_path,
    public.nlevel(cn.path) AS connection_tree_level,
    public.fn_connection_identifier(cn.path) AS connection_identifier,
    public.fn_connection_identifier_location(cn.path) AS connection_location_identifier,
    cn.identifier AS connection_local_identifier,
    cn.connection_type_id,
    cn.description AS connection_description,
    cn.is_approved AS connection_is_approved,
    cn.comment AS connection_comment,
    cc.id AS connection_commercial_id,
    cc.design_approved,
    cc.quote_reference,
    cc.quote_price,
    cc.lead_time_days,
    cc.purchase_order_date,
    cc.purchase_order_reference,
    cc.due_date,
    cc.received_date,
    cc.location,
    cc.unique_code,
    cc.fat_complete,
    cc.sat_complete,
    cc.commissioning_complete,
    cc.installed_date,
    cc.warranty_end_date,
    cc.comment AS connection_commercial_comment,
    ct.path AS connection_type_path,
    ct.label AS connection_type_label,
    ct.model,
    ct.modifier AS connection_type_modifier,
    ct.manufacturer,
    ct.description AS connection_type_description,
    ct.comment AS connection_type_comment,
    ct.is_approved AS connection_type_is_approved,
    (cc.id IS NOT NULL) AS to_supply
   FROM ((public.connection cn
     JOIN public.connection_commercial cc ON ((cn.id = cc.connection_id)))
     LEFT JOIN public.connection_type ct ON ((cn.connection_type_id = ct.id)));
 /   DROP VIEW public.connection_purchasing_detail;
       public          michaelm    false    218    218    215    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    294    218    218    218    218    218    218    218    2    6    2    2    6    6    2    6    2    6    2    6    474    473    215    215    215    215    215    215    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            ^           0    0 !   VIEW connection_purchasing_detail    COMMENT     �   COMMENT ON VIEW public.connection_purchasing_detail IS 'Detailed purchasing information for each connection. There must be a corresponding row in the connection_commercial table for a connection to appear here.';
          public          michaelm    false    300            .           1259    17941    all_connection_state    VIEW     c  CREATE VIEW public.all_connection_state AS
 SELECT ac.connection_id,
    ac.connection_path,
    ac.connection_tree_level,
    ac.connection_identifier,
    ac.connection_identifier_location,
    ac.connection_local_identifier,
    ac.connection_type_id,
    ac.connection_length,
    ac.connection_description,
    ac.connection_is_approved,
    ac.connection_comment,
    cpd.location,
    (cpd.design_approved <= CURRENT_DATE) AS design_approved,
    (cpd.quote_reference IS NOT NULL) AS quote_received,
    ((cpd.purchase_order_date <= CURRENT_DATE) AND (cpd.purchase_order_reference IS NOT NULL)) AS is_ordered,
    cpd.due_date,
    (cpd.received_date <= CURRENT_DATE) AS is_received,
    (cpd.fat_complete <= CURRENT_DATE) AS fat_complete,
    (cpd.installed_date < CURRENT_DATE) AS is_installed,
    (cpd.sat_complete <= CURRENT_DATE) AS sat_complete,
    (cpd.commissioning_complete <= CURRENT_DATE) AS is_commissioned,
    (cpd.warranty_end_date >= CURRENT_DATE) AS in_warranty
   FROM (public.all_connection ac
     LEFT JOIN public.connection_purchasing_detail cpd ON ((ac.connection_id = cpd.connection_id)));
 '   DROP VIEW public.all_connection_state;
       public          postgres    false    300    298    298    298    298    298    298    298    298    298    298    300    300    300    300    300    300    300    300    300    300    298    300    300    2    2    6    6    2    6    2    6    2    6    6            _           0    0    VIEW all_connection_state    COMMENT     �   COMMENT ON VIEW public.all_connection_state IS 'calculates the current state of connections from the all_connection view, the connection_purchasing_detail view and the connection_state table.';
          public          postgres    false    302            9           1259    18018    all_connection_type    VIEW     j  CREATE VIEW public.all_connection_type AS
 SELECT ct.id,
    ct.path,
    ct.label,
    ct.modifier,
    ct.model,
    ct.manufacturer,
    ct.description,
    ct.comment,
    ct.is_approved,
    (EXISTS ( SELECT connection.id
           FROM public.connection
          WHERE (connection.connection_type_id = ct.id))) AS used
   FROM public.connection_type ct;
 &   DROP VIEW public.all_connection_type;
       public          michaelm    false    215    218    218    218    218    218    218    218    218    218    215    6    2    2    6    6    2    6    2    6    2    6            `           0    0    VIEW all_connection_type    COMMENT     h   COMMENT ON VIEW public.all_connection_type IS 'All the defined connection types and if they are used.';
          public          michaelm    false    313            �            1259    17495    datatype    TABLE     n  CREATE TABLE public.datatype (
    id bigint NOT NULL,
    label text NOT NULL,
    scada_1 text,
    scada_2 text,
    scada_3 text,
    scada_4 text,
    scada_5 text,
    control_1 text,
    control_2 text,
    control_3 text,
    control_4 text,
    control_5 text,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL,
    description text
);
    DROP TABLE public.datatype;
       public         heap    postgres    false    6            a           0    0    TABLE datatype    COMMENT     i   COMMENT ON TABLE public.datatype IS 'The mapping of system model data types to target system datatypes';
          public          postgres    false    231            b           0    0    COLUMN datatype.label    COMMENT     d   COMMENT ON COLUMN public.datatype.label IS 'a unique short label for this collection of datatypes';
          public          postgres    false    231            c           0    0    COLUMN datatype.scada_1    COMMENT     l   COMMENT ON COLUMN public.datatype.scada_1 IS 'this is typically the datatype used by the local HMI system';
          public          postgres    false    231            d           0    0    COLUMN datatype.scada_2    COMMENT     �   COMMENT ON COLUMN public.datatype.scada_2 IS 'this is typically the datatype used by the site SCADa (operator interface system)';
          public          postgres    false    231            e           0    0    COLUMN datatype.scada_3    COMMENT     q   COMMENT ON COLUMN public.datatype.scada_3 IS 'this is typically the datatype used by the site historian system';
          public          postgres    false    231            f           0    0    COLUMN datatype.scada_4    COMMENT     u   COMMENT ON COLUMN public.datatype.scada_4 IS 'this is typically the datatype used by the site manufacturing system';
          public          postgres    false    231            g           0    0    COLUMN datatype.scada_5    COMMENT     b   COMMENT ON COLUMN public.datatype.scada_5 IS 'datatype available for use in other SCADA systems';
          public          postgres    false    231            h           0    0    COLUMN datatype.control_1    COMMENT     �   COMMENT ON COLUMN public.datatype.control_1 IS 'this is typically the datatype for use in the local (device/machine) controller';
          public          postgres    false    231            i           0    0    COLUMN datatype.control_2    COMMENT     s   COMMENT ON COLUMN public.datatype.control_2 IS 'this is typically the datatype for use in the process controller';
          public          postgres    false    231            j           0    0    COLUMN datatype.control_3    COMMENT     w   COMMENT ON COLUMN public.datatype.control_3 IS 'this is typically the datatype for use in the supervisory controller';
          public          postgres    false    231            k           0    0    COLUMN datatype.control_4    COMMENT     w   COMMENT ON COLUMN public.datatype.control_4 IS 'this is typically the datatype for use in the supervisory controller';
          public          postgres    false    231            l           0    0    COLUMN datatype.control_5    COMMENT     o   COMMENT ON COLUMN public.datatype.control_5 IS 'this is a datatype available for use in any other controller';
          public          postgres    false    231            =           1259    18036    all_datatype    VIEW     )  CREATE VIEW public.all_datatype AS
 SELECT dt.id,
    dt.label,
    dt.description,
    dt.scada_1,
    dt.scada_2,
    dt.scada_3,
    dt.scada_4,
    dt.scada_5,
    dt.control_1,
    dt.control_2,
    dt.control_3,
    dt.control_4,
    dt.control_5,
    dt.comment
   FROM public.datatype dt;
    DROP VIEW public.all_datatype;
       public          michaelm    false    231    231    231    231    231    231    231    231    231    231    231    231    231    231    6            m           0    0    VIEW all_datatype    COMMENT     {   COMMENT ON VIEW public.all_datatype IS 'All the defined target system datatypes for each internal system model datatype.';
          public          michaelm    false    317            �            1259    17500    property    TABLE     ;  CREATE TABLE public.property (
    id bigint NOT NULL,
    modifier text,
    description text NOT NULL,
    default_value text,
    default_datatype_id bigint,
    comment text,
    is_reportable boolean DEFAULT true NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL,
    attribute_class_id bigint
);
    DROP TABLE public.property;
       public         heap    postgres    false    6            n           0    0    COLUMN property.modifier    COMMENT     �   COMMENT ON COLUMN public.property.modifier IS 'the modifier applied to the resource identifier to create a unique property identifier.';
          public          postgres    false    232            o           0    0    COLUMN property.description    COMMENT     S   COMMENT ON COLUMN public.property.description IS 'a description of this property';
          public          postgres    false    232            p           0    0    COLUMN property.default_value    COMMENT     �   COMMENT ON COLUMN public.property.default_value IS 'the default value of this property, will be overwritten by the resource_property definition and the property_value definition';
          public          postgres    false    232            q           0    0 #   COLUMN property.default_datatype_id    COMMENT     �   COMMENT ON COLUMN public.property.default_datatype_id IS 'reference to the datatype table for the datatype of this property, overwritten by the resource_property and then property_value definition';
          public          postgres    false    232            r           0    0    COLUMN property.is_reportable    COMMENT     d   COMMENT ON COLUMN public.property.is_reportable IS 'this property will appear in resource reports';
          public          postgres    false    232            �            1259    17506    property_value    TABLE     �   CREATE TABLE public.property_value (
    id bigint NOT NULL,
    equipment_id bigint,
    resource_property_id bigint,
    value text,
    datatype_id bigint,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 "   DROP TABLE public.property_value;
       public         heap    postgres    false    6            s           0    0 "   COLUMN property_value.equipment_id    COMMENT     e   COMMENT ON COLUMN public.property_value.equipment_id IS 'the id of the associated equipment record';
          public          postgres    false    233            t           0    0 *   COLUMN property_value.resource_property_id    COMMENT     �   COMMENT ON COLUMN public.property_value.resource_property_id IS 'the id of the associated resource property defining which resource and property this value applies to';
          public          postgres    false    233            u           0    0    COLUMN property_value.value    COMMENT     h   COMMENT ON COLUMN public.property_value.value IS 'the value of this specific instance of the property';
          public          postgres    false    233            v           0    0 !   COLUMN property_value.datatype_id    COMMENT     }   COMMENT ON COLUMN public.property_value.datatype_id IS 'the id of the table defining the datatype to use for this property';
          public          postgres    false    233            �            1259    17511    resource_property    TABLE     �   CREATE TABLE public.resource_property (
    id bigint NOT NULL,
    resource_id bigint,
    property_id bigint,
    default_value text,
    default_datatype_id bigint,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 %   DROP TABLE public.resource_property;
       public         heap    postgres    false    6            w           0    0 $   COLUMN resource_property.resource_id    COMMENT     P   COMMENT ON COLUMN public.resource_property.resource_id IS 'id of the resource';
          public          postgres    false    234            x           0    0 $   COLUMN resource_property.property_id    COMMENT     P   COMMENT ON COLUMN public.resource_property.property_id IS 'id of the property';
          public          postgres    false    234            y           0    0 &   COLUMN resource_property.default_value    COMMENT     �   COMMENT ON COLUMN public.resource_property.default_value IS 'the default value of this property, will be overwritten by the property_value definition';
          public          postgres    false    234            z           0    0 ,   COLUMN resource_property.default_datatype_id    COMMENT     �   COMMENT ON COLUMN public.resource_property.default_datatype_id IS 'reference to the datatype table for the datatype of this property, overwritten by the property_value definition';
          public          postgres    false    234            �            1259    17516    type_property_detail    VIEW     �	  CREATE VIEW public.type_property_detail AS
 SELECT equipment_type.id AS type_id,
    all_type_resource.id AS type_resource_id,
    all_type_resource.comment AS type_resource_comment,
    resource.id AS resource_id,
    resource.modifier AS resource_modifier,
    resource.description AS resource_description,
    resource.comment AS resource_comment,
    resource_group.id AS resource_group_id,
    resource_group.label AS resource_group_label,
    resource_group.description AS resource_group_description,
    resource_group.is_reportable AS resource_is_reportable,
    resource_property.id AS resource_property_id,
    resource_property.comment AS resource_property_comment,
    datatype.id AS datatype_id,
    datatype.label AS datatype_label,
    datatype.comment AS datatype_comment,
    datatype.scada_1 AS datatype_scada_1,
    datatype.scada_2 AS datatype_scada_2,
    datatype.scada_3 AS datatype_scada_3,
    datatype.scada_4 AS datatype_scada_4,
    datatype.scada_5 AS datatype_scada_5,
    datatype.control_1 AS datatype_control_1,
    datatype.control_2 AS datatype_control_2,
    datatype.control_3 AS datatype_control_3,
    datatype.control_4 AS datatype_control_4,
    datatype.control_5 AS datatype_control_5,
    property.id AS property_id,
    property.modifier AS property_modifier,
    property.description AS property_description,
    property.is_reportable AS property_is_reportable,
    property.comment AS property_comment,
    COALESCE(resource_property.default_value, property.default_value) AS default_value,
    property.attribute_class_id AS property_class_id,
    attribute_class.label AS property_class_label,
    attribute_class.description AS property_class_description,
    attribute_class.comment AS property_class_comment
   FROM (((((((public.property
     JOIN public.resource_property ON ((property.id = resource_property.property_id)))
     JOIN public.resource ON ((resource_property.resource_id = resource.id)))
     JOIN public.resource_group ON ((resource.resource_group_id = resource_group.id)))
     LEFT JOIN public.datatype ON ((COALESCE(resource_property.default_datatype_id, property.default_datatype_id) = datatype.id)))
     JOIN public.all_type_resource ON ((resource.id = all_type_resource.resource_id)))
     JOIN public.equipment_type ON ((all_type_resource.type_id = equipment_type.id)))
     LEFT JOIN public.attribute_class ON ((property.attribute_class_id = attribute_class.id)));
 '   DROP VIEW public.type_property_detail;
       public          postgres    false    221    223    223    223    223    225    225    225    225    226    226    226    234    234    234    234    234    234    232    232    232    232    232    232    232    232    231    231    231    231    231    231    231    231    231    231    231    231    231    227    227    227    227    226    226    6            {           0    0    VIEW type_property_detail    COMMENT     z   COMMENT ON VIEW public.type_property_detail IS 'Detailed information about the properties available to equipment types.';
          public          postgres    false    235            �            1259    17521    all_equipment_property    VIEW     4  CREATE VIEW public.all_equipment_property AS
 SELECT all_equipment.equipment_id,
    all_equipment.equipment_path,
    all_equipment.equipment_tree_level,
    all_equipment.equipment_sort_identifier,
    all_equipment.equipment_full_identifier,
    all_equipment.equipment_location_path,
    all_equipment.equipment_location_identifier,
    all_equipment.equipment_local_identifier,
    all_equipment.type_id,
    all_equipment.equipment_description,
    all_equipment.equipment_is_approved,
    all_equipment.equipment_comment,
    type_property_detail.type_resource_id,
    type_property_detail.type_resource_comment,
    type_property_detail.resource_id,
    public.fn_resource_identifier(all_equipment.equipment_sort_identifier, type_property_detail.resource_modifier) AS resource_sort_identifier,
    public.fn_resource_identifier(all_equipment.equipment_full_identifier, type_property_detail.resource_modifier) AS resource_full_identifier,
    type_property_detail.resource_modifier,
    type_property_detail.resource_description,
    type_property_detail.resource_comment,
    type_property_detail.resource_group_id,
    type_property_detail.resource_group_label,
    type_property_detail.resource_group_description,
    type_property_detail.resource_is_reportable,
    type_property_detail.resource_property_id,
    type_property_detail.resource_property_comment,
    type_property_detail.datatype_id,
    type_property_detail.datatype_label,
    type_property_detail.datatype_comment,
    type_property_detail.datatype_scada_1,
    type_property_detail.datatype_scada_2,
    type_property_detail.datatype_scada_3,
    type_property_detail.datatype_scada_4,
    type_property_detail.datatype_scada_5,
    type_property_detail.datatype_control_1,
    type_property_detail.datatype_control_2,
    type_property_detail.datatype_control_3,
    type_property_detail.datatype_control_4,
    type_property_detail.datatype_control_5,
    type_property_detail.property_id,
    public.fn_property_identifier(all_equipment.equipment_sort_identifier, type_property_detail.resource_modifier, type_property_detail.property_modifier) AS property_sort_identifier,
    public.fn_property_identifier(all_equipment.equipment_full_identifier, type_property_detail.resource_modifier, type_property_detail.property_modifier) AS property_full_identifier,
    type_property_detail.property_modifier,
    type_property_detail.property_description,
    type_property_detail.property_is_reportable,
    type_property_detail.property_comment,
    COALESCE(property_value.value, type_property_detail.default_value) AS property_value
   FROM ((public.all_equipment
     JOIN public.type_property_detail ON ((all_equipment.type_id = type_property_detail.type_id)))
     LEFT JOIN public.property_value ON ((type_property_detail.resource_property_id = property_value.resource_property_id)));
 )   DROP VIEW public.all_equipment_property;
       public          postgres    false    220    417    413    220    220    220    220    220    220    220    220    220    220    220    233    233    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    235    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            |           0    0    VIEW all_equipment_property    COMMENT     �   COMMENT ON VIEW public.all_equipment_property IS 'Return all the properties for all equipment with the current value, default if no entry in the property_value table.';
          public          postgres    false    236            �            1259    17526    all_equipment_resource    VIEW     `  CREATE VIEW public.all_equipment_resource AS
 SELECT all_equipment.equipment_id,
    all_equipment.equipment_path,
    all_equipment.equipment_tree_level,
    all_equipment.equipment_sort_identifier,
    all_equipment.equipment_full_identifier,
    all_equipment.equipment_location_path,
    all_equipment.equipment_location_identifier,
    all_equipment.equipment_local_identifier,
    all_equipment.type_id,
    all_equipment.equipment_description,
    all_equipment.equipment_is_approved,
    all_equipment.equipment_comment,
    all_type_resource.id AS type_resource_id,
    all_type_resource.type_path,
    all_type_resource.definition_type_id,
    all_type_resource.resource_id,
    all_type_resource.comment AS type_resource_comment
   FROM (public.all_equipment
     JOIN public.all_type_resource ON ((all_equipment.type_id = all_type_resource.type_id)));
 )   DROP VIEW public.all_equipment_resource;
       public          postgres    false    220    220    223    223    223    223    223    220    220    220    220    220    220    223    220    220    220    220    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            }           0    0    VIEW all_equipment_resource    COMMENT     e   COMMENT ON VIEW public.all_equipment_resource IS 'Return all the type resources for all equipment.';
          public          postgres    false    237            �            1259    17586    equipment_commercial    TABLE     I  CREATE TABLE public.equipment_commercial (
    id bigint NOT NULL,
    equipment_id bigint,
    quote_reference text,
    quote_price double precision,
    lead_time_days integer,
    purchase_order_date date,
    purchase_order_reference text,
    due_date date,
    received_date date,
    location text,
    unique_code text,
    installed_date date,
    warranty_end_date date,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL,
    design_approved date,
    ready_for_fat date,
    fat_complete date,
    sat_complete date,
    commissioning_complete date
);
 (   DROP TABLE public.equipment_commercial;
       public         heap    postgres    false    6            ~           0    0 +   COLUMN equipment_commercial.quote_reference    COMMENT     �   COMMENT ON COLUMN public.equipment_commercial.quote_reference IS 'the reference, or number, of the quotation for this equipment';
          public          postgres    false    252                       0    0 '   COLUMN equipment_commercial.quote_price    COMMENT     e   COMMENT ON COLUMN public.equipment_commercial.quote_price IS 'the original price of this equipment';
          public          postgres    false    252            �           0    0 *   COLUMN equipment_commercial.lead_time_days    COMMENT     m   COMMENT ON COLUMN public.equipment_commercial.lead_time_days IS 'the expected lead time for this equipment';
          public          postgres    false    252            �           0    0 /   COLUMN equipment_commercial.purchase_order_date    COMMENT     k   COMMENT ON COLUMN public.equipment_commercial.purchase_order_date IS 'the date the equipment was ordered';
          public          postgres    false    252            �           0    0 4   COLUMN equipment_commercial.purchase_order_reference    COMMENT     �   COMMENT ON COLUMN public.equipment_commercial.purchase_order_reference IS 'the reference or number of the purchase order for this equipment';
          public          postgres    false    252            �           0    0 $   COLUMN equipment_commercial.due_date    COMMENT     g   COMMENT ON COLUMN public.equipment_commercial.due_date IS 'the date the equipment should be received';
          public          postgres    false    252            �           0    0 )   COLUMN equipment_commercial.received_date    COMMENT     f   COMMENT ON COLUMN public.equipment_commercial.received_date IS 'the date the equipment was received';
          public          postgres    false    252            �           0    0 $   COLUMN equipment_commercial.location    COMMENT     c   COMMENT ON COLUMN public.equipment_commercial.location IS 'the current location of the euqipment';
          public          postgres    false    252            �           0    0 '   COLUMN equipment_commercial.unique_code    COMMENT     �   COMMENT ON COLUMN public.equipment_commercial.unique_code IS 'the serial number or unique identifier of this piece of equipment';
          public          postgres    false    252            �           0    0 *   COLUMN equipment_commercial.installed_date    COMMENT     i   COMMENT ON COLUMN public.equipment_commercial.installed_date IS 'the date this equipment was installed';
          public          postgres    false    252            �           0    0 -   COLUMN equipment_commercial.warranty_end_date    COMMENT     w   COMMENT ON COLUMN public.equipment_commercial.warranty_end_date IS 'the date the warranty for this equipment expires';
          public          postgres    false    252            +           1259    17926    equipment_purchasing_detail    VIEW     �  CREATE VIEW public.equipment_purchasing_detail AS
 SELECT e.id AS equipment_id,
    e.path AS equipment_path,
    public.nlevel(e.path) AS equipment_tree_level,
    public.fn_equipment_identifier_sort(e.path) AS equipment_sort_identifier,
    public.fn_equipment_identifier(e.path) AS equipment_full_identifier,
    e.location_path AS equipment_location_path,
    'future use'::text AS equipment_location_identifier,
    e.identifier AS equipment_local_identifier,
    e.type_id,
    e.description AS equipment_description,
    e.is_approved AS equipment_is_approved,
    e.comment AS equipment_comment,
    ec.id AS equipment_commercial_id,
    ec.quote_reference,
    ec.quote_price,
    ec.lead_time_days,
    ec.design_approved,
    ec.purchase_order_date,
    ec.purchase_order_reference,
    ec.due_date,
    ec.received_date,
    ec.location,
    ec.unique_code,
    ec.ready_for_fat,
    ec.fat_complete,
    ec.sat_complete,
    ec.commissioning_complete,
    ec.installed_date,
    ec.warranty_end_date,
    ec.comment AS equipment_commercial_comment,
    et.path AS type_path,
    et.label AS type_label,
    et.model,
    et.modifier AS type_modifier,
    et.manufacturer,
    et.description AS type_description,
    et.comment AS type_comment,
    et.is_approved AS type_is_approved,
    (ec.id IS NOT NULL) AS to_supply
   FROM ((public.equipment e
     JOIN public.equipment_commercial ec ON ((e.id = ec.equipment_id)))
     LEFT JOIN public.equipment_type et ON ((e.type_id = et.id)));
 .   DROP VIEW public.equipment_purchasing_detail;
       public          michaelm    false    252    252    252    252    252    252    252    252    252    252    252    252    252    252    252    252    252    252    252    221    221    221    221    221    221    221    221    221    219    219    219    219    219    219    219    219    409    411    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            �           0    0     VIEW equipment_purchasing_detail    COMMENT     �   COMMENT ON VIEW public.equipment_purchasing_detail IS 'Detailed purchasing information for each piece of equipment. There must be a corresponding row in the equipment_commercial table for equipment to appear here.';
          public          michaelm    false    299            -           1259    17936    all_equipment_state    VIEW     �  CREATE VIEW public.all_equipment_state AS
 SELECT ae.equipment_id,
    ae.equipment_path,
    ae.equipment_tree_level,
    ae.equipment_sort_identifier,
    ae.equipment_full_identifier,
    ae.equipment_location_path,
    ae.equipment_location_identifier,
    ae.equipment_local_identifier,
    ae.type_id,
    ae.equipment_description,
    ae.equipment_is_approved,
    ae.equipment_comment,
    epd.location,
    (epd.design_approved <= CURRENT_DATE) AS design_approved,
    (epd.quote_reference IS NOT NULL) AS quote_received,
    ((epd.purchase_order_date <= CURRENT_DATE) AND (epd.purchase_order_reference IS NOT NULL)) AS is_ordered,
    epd.due_date,
    (epd.received_date <= CURRENT_DATE) AS is_received,
    (epd.ready_for_fat <= CURRENT_DATE) AS is_configured,
    (epd.fat_complete <= CURRENT_DATE) AS fat_complete,
    (epd.sat_complete <= CURRENT_DATE) AS sat_complete,
    (epd.commissioning_complete <= CURRENT_DATE) AS is_commissioned,
    (epd.installed_date < CURRENT_DATE) AS is_installed,
    (epd.warranty_end_date >= CURRENT_DATE) AS in_warranty
   FROM (public.all_equipment ae
     LEFT JOIN public.equipment_purchasing_detail epd ON ((ae.equipment_id = epd.equipment_id)));
 &   DROP VIEW public.all_equipment_state;
       public          michaelm    false    299    299    299    299    299    299    299    299    299    299    299    299    220    220    220    220    299    220    220    220    220    299    220    220    220    220    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            �           0    0    VIEW all_equipment_state    COMMENT     �   COMMENT ON VIEW public.all_equipment_state IS 'calculates the current state of equipment from the all_equipment view, the equipment_purchasing_detail view and the equipment_state table.';
          public          michaelm    false    301            :           1259    18022    all_equipment_type    VIEW     n  CREATE VIEW public.all_equipment_type AS
 SELECT et.id,
    et.path,
    et.label,
    et.modifier,
    et.model,
    et.manufacturer,
    et.description,
    et.comment,
    et.is_approved,
    (EXISTS ( SELECT equipment.id
           FROM public.equipment
          WHERE (equipment.type_id = et.id))) AS used,
    et.modified_at
   FROM public.equipment_type et;
 %   DROP VIEW public.all_equipment_type;
       public          michaelm    false    221    221    221    221    221    221    219    219    221    221    221    221    6    2    2    6    6    2    6    2    6    2    6            �           0    0    VIEW all_equipment_type    COMMENT     f   COMMENT ON VIEW public.all_equipment_type IS 'All the defined equipment types and if they are used.';
          public          michaelm    false    314            <           1259    18030    all_interface    VIEW     w  CREATE VIEW public.all_interface AS
 SELECT i.id,
    i.attribute_class_id AS interface_class_id,
    ac.label AS interface_class_label,
    ac.description AS interface_class_description,
    ac.comment AS interface_class_comment,
    i.connecting_attribute_class_id AS connecting_interface_class_id,
    cac.label AS connecting_interface_class_label,
    cac.description AS connecting_interface_class_description,
    cac.comment AS connecting_interface_class_comment,
    i.identifier,
    i.description,
    i.is_intermediate,
    i.comment,
    (EXISTS ( SELECT type_interface.id
           FROM public.type_interface
          WHERE (type_interface.interface_id = i.id))) AS is_used
   FROM ((public.interface i
     LEFT JOIN public.attribute_class ac ON ((i.attribute_class_id = ac.id)))
     LEFT JOIN public.attribute_class cac ON ((i.connecting_attribute_class_id = cac.id)));
     DROP VIEW public.all_interface;
       public          postgres    false    224    228    228    225    225    225    225    224    224    224    224    224    224    6            3           1259    17983    all_interface_class    VIEW     L  CREATE VIEW public.all_interface_class AS
 SELECT ac.id,
    ac.label,
    ac.description,
    ac.comment,
    (EXISTS ( SELECT interface.id
           FROM public.interface
          WHERE ((interface.attribute_class_id = ac.id) OR (interface.connecting_attribute_class_id = ac.id)))) AS is_used
   FROM public.attribute_class ac;
 &   DROP VIEW public.all_interface_class;
       public          michaelm    false    225    224    224    224    225    225    225    6            �           0    0    VIEW all_interface_class    COMMENT     �   COMMENT ON VIEW public.all_interface_class IS 'Returns all interfaces, there class and connecting class details and an indication if each is used or not.';
          public          michaelm    false    307            �            1259    17531    permitted_interface_connection    TABLE     �   CREATE TABLE public.permitted_interface_connection (
    id bigint NOT NULL,
    interface_class_id bigint,
    connection_type_id bigint,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 2   DROP TABLE public.permitted_interface_connection;
       public         heap    postgres    false    6            �           0    0 8   COLUMN permitted_interface_connection.interface_class_id    COMMENT     z   COMMENT ON COLUMN public.permitted_interface_connection.interface_class_id IS 'the id of the associated interface class';
          public          postgres    false    238            �           0    0 8   COLUMN permitted_interface_connection.connection_type_id    COMMENT     {   COMMENT ON COLUMN public.permitted_interface_connection.connection_type_id IS 'the id of the associated connection class';
          public          postgres    false    238            6           1259    18003 "   all_permitted_interface_connection    VIEW       CREATE VIEW public.all_permitted_interface_connection AS
 SELECT all_c.connection_id,
    all_c.connection_path,
    all_c.connection_tree_level,
    all_c.connection_identifier_location,
    all_c.connection_identifier,
    all_c.connection_local_identifier,
    all_c.connection_type_id,
    all_c.connection_type_description,
    all_c.connection_type_comment,
    all_c.connection_description,
    all_c.connection_length,
    all_c.connection_is_approved,
    all_c.connection_type_is_hidden,
    all_c.connection_use_parent_identifier,
    all_c.connection_comment
   FROM public.all_connection_interface all_c
  WHERE ((all_c.start_interface_class_id IS NOT NULL) AND (all_c.connection_type_id IS NOT NULL) AND (NOT (all_c.start_interface_class_id IN ( SELECT permitted.interface_class_id
           FROM public.permitted_interface_connection permitted
          WHERE (all_c.connection_type_id = permitted.connection_type_id)))))
UNION
 SELECT all_c.connection_id,
    all_c.connection_path,
    all_c.connection_tree_level,
    all_c.connection_identifier_location,
    all_c.connection_identifier,
    all_c.connection_local_identifier,
    all_c.connection_type_id,
    all_c.connection_type_description,
    all_c.connection_type_comment,
    all_c.connection_description,
    all_c.connection_length,
    all_c.connection_is_approved,
    all_c.connection_type_is_hidden,
    all_c.connection_use_parent_identifier,
    all_c.connection_comment
   FROM public.all_connection_interface all_c
  WHERE ((all_c.end_interface_class_id IS NOT NULL) AND (all_c.connection_type_id IS NOT NULL) AND (NOT (all_c.end_interface_class_id IN ( SELECT permitted.interface_class_id
           FROM public.permitted_interface_connection permitted
          WHERE (all_c.connection_type_id = permitted.connection_type_id)))));
 5   DROP VIEW public.all_permitted_interface_connection;
       public          postgres    false    309    2    2    6    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6    2    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    238    238    309    309    309    309    309    309    309    309    309    309    309    309    309    309    309    309    2    2    6    6    2    6    2    6    2    6    6            �           0    0 '   VIEW all_permitted_interface_connection    COMMENT     �   COMMENT ON VIEW public.all_permitted_interface_connection IS 'Return all the connections that are not the correct class for either of the interfaces.';
          public          postgres    false    310                       1259    17625    possible_state    TABLE     -  CREATE TABLE public.possible_state (
    id bigint NOT NULL,
    label text NOT NULL,
    description text NOT NULL,
    valid_for_connection boolean NOT NULL,
    valid_for_equipment boolean NOT NULL,
    comment text,
    authority_id bigint,
    modified_at timestamp(0) with time zone NOT NULL
);
 "   DROP TABLE public.possible_state;
       public         heap    postgres    false    6            �           0    0    COLUMN possible_state.label    COMMENT     ]   COMMENT ON COLUMN public.possible_state.label IS 'the short label for this equipment state';
          public          postgres    false    267            �           0    0 !   COLUMN possible_state.description    COMMENT     b   COMMENT ON COLUMN public.possible_state.description IS 'the description of this equipment state';
          public          postgres    false    267            �           0    0 *   COLUMN possible_state.valid_for_connection    COMMENT     i   COMMENT ON COLUMN public.possible_state.valid_for_connection IS 'this is a valid state for connections';
          public          postgres    false    267            �           0    0 )   COLUMN possible_state.valid_for_equipment    COMMENT     f   COMMENT ON COLUMN public.possible_state.valid_for_equipment IS 'this is a valid state for equipment';
          public          postgres    false    267            �           0    0 "   COLUMN possible_state.authority_id    COMMENT     v   COMMENT ON COLUMN public.possible_state.authority_id IS 'link to the authority table of users and their authorities';
          public          postgres    false    267            0           1259    17957    all_possible_state    VIEW     L  CREATE VIEW public.all_possible_state AS
 SELECT ps.id AS state_id,
    ps.label AS state_label,
    ps.description AS state_description,
    ps.valid_for_connection,
    ps.valid_for_equipment,
    ps.comment AS state_comment,
    au.id AS authority_id,
    au.label AS authority_label,
    au.description AS authority_description,
    au.comment AS authority_comment,
    true AS state_is_editable,
    ps.modified_at AS state_modified_at,
    au.modified_at AS authority_modified_at
   FROM (public.possible_state ps
     LEFT JOIN public.authority au ON ((ps.authority_id = au.id)));
 %   DROP VIEW public.all_possible_state;
       public          michaelm    false    239    239    239    239    267    267    267    267    267    267    267    267    239    6            �           0    0    VIEW all_possible_state    COMMENT     �   COMMENT ON VIEW public.all_possible_state IS 'Returns all the possible user defined states that can be applied to equipment or connections.';
          public          michaelm    false    304            ;           1259    18026    all_property_class    VIEW       CREATE VIEW public.all_property_class AS
 SELECT ac.id,
    ac.label,
    ac.description,
    ac.comment,
    (EXISTS ( SELECT property.id
           FROM public.property
          WHERE (property.attribute_class_id = ac.id))) AS is_used
   FROM public.attribute_class ac;
 %   DROP VIEW public.all_property_class;
       public          michaelm    false    225    225    225    232    232    225    6            �           0    0    VIEW all_property_class    COMMENT     �   COMMENT ON VIEW public.all_property_class IS 'Returns all properties, their class and connecting class details and an indication if each is used or not.';
          public          michaelm    false    315            7           1259    18008    all_resource    VIEW     �  CREATE VIEW public.all_resource AS
 SELECT r.id,
    r.modifier,
    r.description,
    r.comment,
    rg.id AS group_id,
    COALESCE(rg.label, 'Unassigned'::text) AS group_label,
    COALESCE(rg.description, 'Not assigned to a resource group'::text) AS group_description,
    rg.comment AS group_comment,
    COALESCE(rg.is_reportable, true) AS group_is_reportable,
    (EXISTS ( SELECT type_resource.id,
            type_resource.type_id,
            type_resource.resource_id,
            type_resource.comment,
            type_resource.modified_at
           FROM public.type_resource
          WHERE (type_resource.resource_id = r.id))) AS is_used
   FROM (public.resource r
     LEFT JOIN public.resource_group rg ON ((r.resource_group_id = rg.id)));
    DROP VIEW public.all_resource;
       public          postgres    false    227    227    227    227    227    226    226    226    226    226    222    222    222    222    222    6            �           0    0    VIEW all_resource    COMMENT     @   COMMENT ON VIEW public.all_resource IS 'All defined resources';
          public          postgres    false    311            8           1259    18013    all_resource_property    VIEW       CREATE VIEW public.all_resource_property AS
 SELECT pr1.id,
    pr1.modifier,
    pr1.description,
    pr1.default_value,
    pr1.default_datatype_id,
    ( SELECT datatype.label
           FROM public.datatype
          WHERE (datatype.id = pr1.default_datatype_id)) AS default_datatype_label,
    ( SELECT datatype.comment
           FROM public.datatype
          WHERE (datatype.id = pr1.default_datatype_id)) AS default_datatype_comment,
    pr1.is_reportable,
    pr1.comment,
    rp.default_value AS resource_property_default_value,
    rp.default_datatype_id AS resource_property_default_datatype_id,
    ( SELECT datatype.label
           FROM public.datatype
          WHERE (datatype.id = rp.default_datatype_id)) AS resource_property_default_datatype_label,
    ( SELECT datatype.comment
           FROM public.datatype
          WHERE (datatype.id = rp.default_datatype_id)) AS resource_property_default_datatype_comment,
    rp.comment AS resource_property_comment,
    rp.resource_id,
    ar.modifier AS resource_modifier,
    ar.description AS resource_description,
    ar.group_id AS resource_group_id,
    ar.group_label AS resource_group_label,
    ar.group_description AS resource_group_description,
    ar.group_comment AS resource_group_comment,
    ar.group_is_reportable AS resource_is_reportable,
    ar.is_used AS resource_is_used,
    true AS property_is_used
   FROM ((public.resource_property rp
     LEFT JOIN public.property pr1 ON ((pr1.id = rp.property_id)))
     LEFT JOIN public.all_resource ar ON ((ar.id = rp.resource_id)))
UNION
 SELECT pr2.id,
    pr2.modifier,
    pr2.description,
    pr2.default_value,
    pr2.default_datatype_id,
    ( SELECT datatype.label
           FROM public.datatype
          WHERE (datatype.id = pr2.default_datatype_id)) AS default_datatype_label,
    ( SELECT datatype.comment
           FROM public.datatype
          WHERE (datatype.id = pr2.default_datatype_id)) AS default_datatype_comment,
    pr2.is_reportable,
    pr2.comment,
    NULL::text AS resource_property_default_value,
    NULL::bigint AS resource_property_default_datatype_id,
    NULL::text AS resource_property_default_datatype_label,
    NULL::text AS resource_property_default_datatype_comment,
    NULL::text AS resource_property_comment,
    NULL::bigint AS resource_id,
    NULL::text AS resource_modifier,
    NULL::text AS resource_description,
    NULL::bigint AS resource_group_id,
    NULL::text AS resource_group_label,
    NULL::text AS resource_group_description,
    NULL::text AS resource_group_comment,
    NULL::boolean AS resource_is_reportable,
    NULL::boolean AS resource_is_used,
    false AS property_is_used
   FROM public.property pr2
  WHERE (NOT (pr2.id IN ( SELECT DISTINCT resource_property.property_id
           FROM public.resource_property)));
 (   DROP VIEW public.all_resource_property;
       public          postgres    false    311    311    311    234    234    234    234    234    232    232    232    232    232    231    231    231    232    232    311    311    311    311    311    311    6            �           0    0    VIEW all_resource_property    COMMENT     \   COMMENT ON VIEW public.all_resource_property IS 'All defined properties for all resources';
          public          postgres    false    312                       1259    17636    system_settings    TABLE     �   CREATE TABLE public.system_settings (
    id bigint NOT NULL,
    label text NOT NULL,
    value text NOT NULL,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 #   DROP TABLE public.system_settings;
       public         heap    postgres    false    6            �           0    0    TABLE system_settings    COMMENT       COMMENT ON TABLE public.system_settings IS 'This table records settings/parameters that tune the behaviour of the system model. For example the "location delimiter", "process delimiter" and "ownership delimiter" for use when we create the compound names.';
          public          postgres    false    274            �           0    0    COLUMN system_settings.label    COMMENT     ]   COMMENT ON COLUMN public.system_settings.label IS 'the setting label, this must be unique.';
          public          postgres    false    274            �           0    0    COLUMN system_settings.value    COMMENT     N   COMMENT ON COLUMN public.system_settings.value IS 'the value of the setting';
          public          postgres    false    274            �           0    0    COLUMN system_settings.comment    COMMENT     a   COMMENT ON COLUMN public.system_settings.comment IS 'a general comment, not normally displayed';
          public          postgres    false    274            �           0    0 "   COLUMN system_settings.modified_at    COMMENT     ^   COMMENT ON COLUMN public.system_settings.modified_at IS 'last time this record was modified';
          public          postgres    false    274            /           1259    17953    all_system_settings    VIEW     �   CREATE VIEW public.all_system_settings AS
 SELECT system_settings.id,
    system_settings.label,
    system_settings.value,
    system_settings.comment,
    system_settings.modified_at
   FROM public.system_settings;
 &   DROP VIEW public.all_system_settings;
       public          michaelm    false    274    274    274    274    274    6            �           0    0    VIEW all_system_settings    COMMENT     Y   COMMENT ON VIEW public.all_system_settings IS 'This returns all of the system settings';
          public          michaelm    false    303            2           1259    17970    all_target_system    VIEW     p  CREATE VIEW public.all_target_system AS
 SELECT ss.id AS system_settings_id,
    ss.label,
    ss.value,
    ss.comment
   FROM public.system_settings ss
  WHERE (ss.label = ANY (ARRAY['scada_1'::text, 'scada_2'::text, 'scada_3'::text, 'scada_4'::text, 'scada_5'::text, 'control_1'::text, 'control_2'::text, 'control_3'::text, 'control_4'::text, 'control_5'::text]));
 $   DROP VIEW public.all_target_system;
       public          michaelm    false    274    274    274    274    6            �           0    0    VIEW all_target_system    COMMENT     �   COMMENT ON VIEW public.all_target_system IS 'This displays the defined datatypes and the appropriate datatype defintion reference for each target system';
          public          michaelm    false    306            �            1259    17546    authority_id_seq    SEQUENCE     y   CREATE SEQUENCE public.authority_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.authority_id_seq;
       public          postgres    false    6    239            �           0    0    authority_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.authority_id_seq OWNED BY public.authority.id;
          public          postgres    false    240            �            1259    17547    intermediate_connection    VIEW     �  CREATE VIEW public.intermediate_connection AS
 SELECT all_connection_series.series,
    public.nlevel(all_connection_series.series) AS path_length,
    public.subpath(all_connection_series.series, 0, (public.nlevel(all_connection_series.series) - 1)) AS start_subpath,
    public.subpath(all_connection_series.series, ('-1'::integer * (public.nlevel(all_connection_series.series) - 1))) AS end_subpath
   FROM public.all_connection_series
  WHERE (public.nlevel(all_connection_series.series) > 1);
 *   DROP VIEW public.intermediate_connection;
       public          postgres    false    216    2    2    2    6    6    2    6    2    6    2    6    6    2    6    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6            �           0    0    VIEW intermediate_connection    COMMENT     �   COMMENT ON VIEW public.intermediate_connection IS 'This is all the multi-path connection series and their starting and ending sub paths.';
          public          postgres    false    241            �            1259    17551    connection_series    VIEW     �  CREATE VIEW public.connection_series AS
 SELECT all_connection_series.series,
    public.nlevel(all_connection_series.series) AS series_length
   FROM public.all_connection_series
  WHERE ((NOT (all_connection_series.series OPERATOR(public.=) ANY ( SELECT intermediate_connection.start_subpath
           FROM public.intermediate_connection))) AND (NOT (all_connection_series.series OPERATOR(public.=) ANY ( SELECT intermediate_connection.end_subpath
           FROM public.intermediate_connection))));
 $   DROP VIEW public.connection_series;
       public          postgres    false    2    2    6    6    2    6    2    6    2    6    241    241    216    2    6    2    2    6    6    2    6    2    6    2    6    2    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6    6            �           0    0    VIEW connection_series    COMMENT     �   COMMENT ON VIEW public.connection_series IS 'This only returns the unique full connection series. No intermediate connections are included.';
          public          postgres    false    242            �            1259    17555    connected_interface    VIEW     �  CREATE VIEW public.connected_interface AS
 SELECT start_c.id AS start_connection_id,
    start_c.path AS start_connection_path,
    start_c.start_equipment_id,
    start_c.start_interface_id,
    connection_series.series AS connection_series,
    connection_series.series_length AS connection_series_length,
    end_c.id AS end_connection_id,
    end_c.path AS end_connection_path,
    end_c.end_equipment_id,
    end_c.end_interface_id
   FROM ((public.connection start_c
     JOIN public.connection_series ON ((start_c.id = ((public.subpath(connection_series.series, 0, 1))::text)::bigint)))
     JOIN public.connection end_c ON ((end_c.id = ((public.subpath(connection_series.series, '-1'::integer, 1))::text)::bigint)));
 &   DROP VIEW public.connected_interface;
       public          postgres    false    2    2    2    6    6    2    6    2    6    2    6    6    242    242    215    215    215    215    215    215    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            �           0    0    VIEW connected_interface    COMMENT     �   COMMENT ON VIEW public.connected_interface IS 'Returns all the connections between interfaces, showing the starting and ending equipment and interface ids.';
          public          postgres    false    243            �            1259    17560    connected_property    VIEW       CREATE VIEW public.connected_property AS
 SELECT start_equip.equipment_id AS start_equipment_id,
    start_equip.equipment_path AS start_equipment_path,
    start_equip.equipment_sort_identifier AS start_equipment_sort_identifier,
    start_equip.equipment_full_identifier AS start_equipment_full_identifier,
    start_equip.equipment_local_identifier AS start_equipment_local_identifier,
    start_equip.type_id AS start_type_id,
    start_equip.equipment_description AS start_equipment_description,
    start_equip.equipment_is_approved AS start_equipment_is_approved,
    start_equip.equipment_comment AS start_equipment_comment,
    start_equip.type_resource_id AS start_type_resource_id,
    start_equip.type_resource_comment AS start_type_resource_comment,
    start_equip.resource_id AS start_resource_id,
    start_equip.resource_modifier AS start_resource_modifier,
    start_equip.resource_full_identifier AS start_resource_full_identifier,
    start_equip.resource_description AS start_resource_description,
    start_equip.resource_comment AS start_resource_comment,
    start_equip.resource_group_id AS start_resource_group_id,
    start_equip.resource_group_label AS start_resource_group_label,
    start_equip.resource_group_description AS start_resource_is_reportable,
    start_equip.resource_group_description AS start_resource_group_description,
    start_equip.interface_id AS start_interface_id,
    start_equip.interface_full_identifier AS start_interface_full_identifier,
    start_equip.interface_identifier AS start_interface_identifier,
    start_equip.interface_description AS start_interface_description,
    start_equip.interface_comment AS start_interface_comment,
    start_equip.interface_class_id AS start_interface_class_id,
    start_equip.interface_class_label AS start_interface_class_label,
    start_equip.interface_class_description AS start_interface_class_description,
    start_equip.interface_class_comment AS start_interface_class_comment,
    connected.start_connection_id,
    connected.start_connection_path,
    connected.connection_series,
    connected.connection_series_length,
    connected.end_connection_id,
    connected.end_connection_path,
    end_property.equipment_id AS end_equipment_id,
    end_property.equipment_path AS end_equipment_path,
    end_property.equipment_sort_identifier AS end_equipment_sort_identifier,
    end_property.equipment_full_identifier AS end_equipment_full_identifier,
    end_property.equipment_local_identifier AS end_equipment_local_identifier,
    end_property.type_id AS end_type_id,
    end_property.equipment_description AS end_equipment_description,
    end_property.equipment_is_approved AS end_equipment_is_approved,
    end_property.equipment_comment AS end_equipment_comment,
    end_property.type_resource_id AS end_type_resource_id,
    end_property.type_resource_comment AS end_type_resource_comment,
    end_property.resource_id AS end_resource_id,
    end_property.resource_modifier AS end_resource_modifier,
    end_property.resource_full_identifier AS end_resource_full_identifier,
    end_property.resource_group_id AS end_resource_group_id,
    end_property.resource_group_label AS end_resource_group_label,
    end_property.resource_group_description AS end_resource_group_description,
    end_property.resource_is_reportable AS end_resource_is_reportable,
    end_property.resource_property_id AS end_resource_property_id,
    end_property.resource_property_comment AS end_resource_property_comment,
    end_property.datatype_id AS end_datatype_id,
    end_property.datatype_label AS end_datatype_label,
    end_property.datatype_comment AS end_datatype_comment,
    end_property.datatype_scada_1 AS end_datatype_scada_1,
    end_property.datatype_scada_2 AS end_datatype_scada_2,
    end_property.datatype_scada_3 AS end_datatype_scada_3,
    end_property.datatype_scada_4 AS end_datatype_scada_4,
    end_property.datatype_scada_5 AS end_datatype_scada_5,
    end_property.datatype_control_1 AS end_datatype_control_1,
    end_property.datatype_control_2 AS end_datatype_control_2,
    end_property.datatype_control_3 AS end_datatype_control_3,
    end_property.datatype_control_4 AS end_datatype_control_4,
    end_property.datatype_control_5 AS end_datatype_control_5,
    end_property.property_id AS end_property_id,
    end_property.property_sort_identifier AS end_property_sort_identifier,
    end_property.property_full_identifier AS end_property_full_identifier,
    end_property.property_modifier AS end_property_modifier,
    end_property.property_description AS end_property_description,
    end_property.property_is_reportable AS end_property_is_reportable,
    end_property.property_comment AS end_property_comment,
    end_property.property_value AS end_property_value
   FROM ((public.all_equipment_interface start_equip
     JOIN public.connected_interface connected ON (((start_equip.equipment_id = connected.start_equipment_id) AND (start_equip.interface_id = connected.start_interface_id))))
     JOIN public.all_equipment_property end_property ON (((connected.end_equipment_id = end_property.equipment_id) AND (connected.end_interface_id IN ( SELECT type_interface.interface_id
           FROM public.type_interface
          WHERE (type_interface.type_resource_id = end_property.type_resource_id))))))
  WHERE start_equip.type_interface_is_active;
 %   DROP VIEW public.connected_property;
       public          postgres    false    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    230    228    228    243    243    243    243    243    243    243    243    236    236    236    236    243    243    236    236    236    236    236    236    236    236    236    236    236    236    236    236    236    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6            �           0    0    VIEW connected_property    COMMENT     �   COMMENT ON VIEW public.connected_property IS 'The list of properties available to equipment through connections with other equipment.';
          public          postgres    false    244            '           1259    17860    connection_commerical_id_seq    SEQUENCE     �   CREATE SEQUENCE public.connection_commerical_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.connection_commerical_id_seq;
       public          postgres    false    294    6            �           0    0    connection_commerical_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.connection_commerical_id_seq OWNED BY public.connection_commercial.id;
          public          postgres    false    295            �            1259    17571    connection_history    TABLE       CREATE TABLE public.connection_history (
    id bigint NOT NULL,
    connection_id bigint NOT NULL,
    description text NOT NULL,
    reason text NOT NULL,
    comment text,
    modified_by text NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL
);
 &   DROP TABLE public.connection_history;
       public         heap    postgres    false    6            �           0    0 '   COLUMN connection_history.connection_id    COMMENT     v   COMMENT ON COLUMN public.connection_history.connection_id IS 'the record id of the connection change in this record';
          public          postgres    false    245            �           0    0 %   COLUMN connection_history.description    COMMENT     o   COMMENT ON COLUMN public.connection_history.description IS 'a plain language description of the modification';
          public          postgres    false    245            �           0    0 !   COLUMN connection_history.comment    COMMENT     d   COMMENT ON COLUMN public.connection_history.comment IS 'a general comment, not normally displayed';
          public          postgres    false    245            �           0    0 %   COLUMN connection_history.modified_at    COMMENT     e   COMMENT ON COLUMN public.connection_history.modified_at IS 'the last time this record was modified';
          public          postgres    false    245            �            1259    17576    connection_history_id_seq    SEQUENCE     �   CREATE SEQUENCE public.connection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.connection_history_id_seq;
       public          postgres    false    245    6            �           0    0    connection_history_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.connection_history_id_seq OWNED BY public.connection_history.id;
          public          postgres    false    246            �            1259    17577    connection_id_seq    SEQUENCE     z   CREATE SEQUENCE public.connection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.connection_id_seq;
       public          postgres    false    215    6            �           0    0    connection_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.connection_id_seq OWNED BY public.connection.id;
          public          postgres    false    247            �            1259    17578    connection_state    TABLE     �   CREATE TABLE public.connection_state (
    id bigint NOT NULL,
    connection_id bigint,
    possible_state_id bigint,
    is_state boolean NOT NULL,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 $   DROP TABLE public.connection_state;
       public         heap    postgres    false    6            �           0    0 %   COLUMN connection_state.connection_id    COMMENT     z   COMMENT ON COLUMN public.connection_state.connection_id IS 'the record id of the connection associated with this record';
          public          postgres    false    248            �           0    0 )   COLUMN connection_state.possible_state_id    COMMENT     �   COMMENT ON COLUMN public.connection_state.possible_state_id IS 'the record id of the state definition indicated by this record';
          public          postgres    false    248            �           0    0     COLUMN connection_state.is_state    COMMENT     c   COMMENT ON COLUMN public.connection_state.is_state IS 'is the connection currently in this state';
          public          postgres    false    248            �           0    0    COLUMN connection_state.comment    COMMENT     b   COMMENT ON COLUMN public.connection_state.comment IS 'a general comment, not normally displayed';
          public          postgres    false    248            �           0    0 #   COLUMN connection_state.modified_at    COMMENT     c   COMMENT ON COLUMN public.connection_state.modified_at IS 'the last time this record was modified';
          public          postgres    false    248            �            1259    17583    connection_state_id_seq    SEQUENCE     �   CREATE SEQUENCE public.connection_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.connection_state_id_seq;
       public          postgres    false    6    248            �           0    0    connection_state_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.connection_state_id_seq OWNED BY public.connection_state.id;
          public          postgres    false    249            �            1259    17584    connection_type_id_seq    SEQUENCE        CREATE SEQUENCE public.connection_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.connection_type_id_seq;
       public          postgres    false    218    6            �           0    0    connection_type_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.connection_type_id_seq OWNED BY public.connection_type.id;
          public          postgres    false    250            )           1259    17870    connection_type_purchasing    VIEW     �  CREATE VIEW public.connection_type_purchasing AS
SELECT
    NULL::public.ltree AS type_path,
    NULL::text AS type_label,
    NULL::text AS model,
    NULL::text AS type_modifier,
    NULL::text AS manufacturer,
    NULL::text AS type_description,
    NULL::text AS type_comment,
    NULL::boolean AS type_is_approved,
    NULL::bigint AS total_quantity,
    NULL::double precision AS total_length,
    NULL::bigint AS ordered_count,
    NULL::double precision AS ordered_length,
    NULL::bigint AS to_order_count,
    NULL::double precision AS to_order_length,
    NULL::bigint AS received_count,
    NULL::bigint AS installed_count,
    NULL::integer AS lead_time_days;
 -   DROP VIEW public.connection_type_purchasing;
       public          michaelm    false    2    2    6    6    2    6    2    6    2    6    6            �            1259    17585    datatype_id_seq    SEQUENCE     x   CREATE SEQUENCE public.datatype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.datatype_id_seq;
       public          postgres    false    231    6            �           0    0    datatype_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.datatype_id_seq OWNED BY public.datatype.id;
          public          postgres    false    251            �            1259    17591    equipment_commercial_id_seq    SEQUENCE     �   CREATE SEQUENCE public.equipment_commercial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.equipment_commercial_id_seq;
       public          postgres    false    252    6            �           0    0    equipment_commercial_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.equipment_commercial_id_seq OWNED BY public.equipment_commercial.id;
          public          postgres    false    253            �            1259    17592    equipment_history    TABLE       CREATE TABLE public.equipment_history (
    id bigint NOT NULL,
    equipment_id bigint NOT NULL,
    description text NOT NULL,
    reason text NOT NULL,
    comment text,
    modified_by text NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL
);
 %   DROP TABLE public.equipment_history;
       public         heap    postgres    false    6            �           0    0 %   COLUMN equipment_history.equipment_id    COMMENT     r   COMMENT ON COLUMN public.equipment_history.equipment_id IS 'the id of the equipment associated with this change';
          public          postgres    false    254            �           0    0 $   COLUMN equipment_history.description    COMMENT     e   COMMENT ON COLUMN public.equipment_history.description IS 'a brief description of the modification';
          public          postgres    false    254            �           0    0    COLUMN equipment_history.reason    COMMENT     X   COMMENT ON COLUMN public.equipment_history.reason IS 'the reason for the modification';
          public          postgres    false    254            �           0    0 $   COLUMN equipment_history.modified_by    COMMENT     W   COMMENT ON COLUMN public.equipment_history.modified_by IS 'who made the modification';
          public          postgres    false    254            �            1259    17597    equipment_history_id_seq    SEQUENCE     �   CREATE SEQUENCE public.equipment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.equipment_history_id_seq;
       public          postgres    false    254    6            �           0    0    equipment_history_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.equipment_history_id_seq OWNED BY public.equipment_history.id;
          public          postgres    false    255                        1259    17598    equipment_id_seq    SEQUENCE     y   CREATE SEQUENCE public.equipment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.equipment_id_seq;
       public          postgres    false    219    6            �           0    0    equipment_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.equipment_id_seq OWNED BY public.equipment.id;
          public          postgres    false    256                       1259    17599    equipment_state    TABLE     �   CREATE TABLE public.equipment_state (
    id bigint NOT NULL,
    equipment_id bigint,
    possible_state_id bigint,
    is_state boolean DEFAULT false NOT NULL,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 #   DROP TABLE public.equipment_state;
       public         heap    postgres    false    6            �           0    0 #   COLUMN equipment_state.equipment_id    COMMENT     d   COMMENT ON COLUMN public.equipment_state.equipment_id IS 'the equipent associates with this state';
          public          postgres    false    257            �           0    0 (   COLUMN equipment_state.possible_state_id    COMMENT     V   COMMENT ON COLUMN public.equipment_state.possible_state_id IS 'the associated state';
          public          postgres    false    257            �           0    0    COLUMN equipment_state.is_state    COMMENT     W   COMMENT ON COLUMN public.equipment_state.is_state IS 'is the equipment in this state';
          public          postgres    false    257                       1259    17605    equipment_state_id_seq    SEQUENCE        CREATE SEQUENCE public.equipment_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.equipment_state_id_seq;
       public          postgres    false    257    6            �           0    0    equipment_state_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.equipment_state_id_seq OWNED BY public.equipment_state.id;
          public          postgres    false    258                       1259    17606    equipment_type_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.equipment_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.equipment_type_id_seq;
       public          postgres    false    6    221            �           0    0    equipment_type_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.equipment_type_id_seq OWNED BY public.equipment_type.id;
          public          postgres    false    259                       1259    17607    full_connection_series    VIEW     j  CREATE VIEW public.full_connection_series AS
 SELECT paths.series,
    public.nlevel(paths.series) AS series_length
   FROM public.all_connection_series paths
  WHERE (NOT (paths.series OPERATOR(public.=) ANY ( SELECT public.subltree(subpaths.series, 0, (public.nlevel(subpaths.series) - 1)) AS subltree
           FROM public.all_connection_series subpaths)));
 )   DROP VIEW public.full_connection_series;
       public          postgres    false    2    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6    2    6    2    2    6    6    2    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    216    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6            �           0    0    VIEW full_connection_series    COMMENT     �   COMMENT ON VIEW public.full_connection_series IS 'This only returns the unique full connection series. No intermediate connections are included.';
          public          postgres    false    260                       1259    17611    full_connected_interface    VIEW     �  CREATE VIEW public.full_connected_interface AS
 SELECT start_c.id AS start_connection_id,
    start_c.path AS start_connection_path,
    start_c.start_equipment_id,
    start_c.start_interface_id,
    full_connection_series.series AS connection_series,
    full_connection_series.series_length AS connection_series_length,
    end_c.id AS end_connection_id,
    end_c.path AS end_connection_path,
    end_c.end_equipment_id,
    end_c.end_interface_id
   FROM ((public.connection start_c
     JOIN public.full_connection_series ON ((start_c.id = ((public.subpath(full_connection_series.series, 0, 1))::text)::bigint)))
     JOIN public.connection end_c ON ((end_c.id = ((public.subpath(full_connection_series.series, '-1'::integer, 1))::text)::bigint)));
 +   DROP VIEW public.full_connected_interface;
       public          postgres    false    260    2    2    2    6    6    2    6    2    6    2    6    6    215    215    215    215    215    215    260    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    2    2    6    6    2    6    2    6    2    6    6                       1259    17616    general_history    TABLE       CREATE TABLE public.general_history (
    id bigint NOT NULL,
    table_name text NOT NULL,
    table_id bigint NOT NULL,
    description text NOT NULL,
    reason text NOT NULL,
    comment text,
    modified_by text NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL
);
 #   DROP TABLE public.general_history;
       public         heap    postgres    false    6                       1259    17621    general_history_id_seq    SEQUENCE        CREATE SEQUENCE public.general_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.general_history_id_seq;
       public          postgres    false    6    262            �           0    0    general_history_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.general_history_id_seq OWNED BY public.general_history.id;
          public          postgres    false    263                       1259    17622    interface_class_id_seq    SEQUENCE        CREATE SEQUENCE public.interface_class_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.interface_class_id_seq;
       public          postgres    false    225    6            �           0    0    interface_class_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.interface_class_id_seq OWNED BY public.attribute_class.id;
          public          postgres    false    264            	           1259    17623    interface_id_seq    SEQUENCE     y   CREATE SEQUENCE public.interface_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.interface_id_seq;
       public          postgres    false    224    6            �           0    0    interface_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.interface_id_seq OWNED BY public.interface.id;
          public          postgres    false    265            
           1259    17624 %   permitted_interface_connection_id_seq    SEQUENCE     �   CREATE SEQUENCE public.permitted_interface_connection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.permitted_interface_connection_id_seq;
       public          postgres    false    238    6            �           0    0 %   permitted_interface_connection_id_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE public.permitted_interface_connection_id_seq OWNED BY public.permitted_interface_connection.id;
          public          postgres    false    266                       1259    17630    possible_state_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.possible_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.possible_state_id_seq;
       public          postgres    false    6    267            �           0    0    possible_state_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.possible_state_id_seq OWNED BY public.possible_state.id;
          public          postgres    false    268                       1259    17631    property_id_seq    SEQUENCE     x   CREATE SEQUENCE public.property_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.property_id_seq;
       public          postgres    false    6    232            �           0    0    property_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.property_id_seq OWNED BY public.property.id;
          public          postgres    false    269                       1259    17632    property_value_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.property_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.property_value_id_seq;
       public          postgres    false    6    233            �           0    0    property_value_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.property_value_id_seq OWNED BY public.property_value.id;
          public          postgres    false    270                       1259    17633    resource_group_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.resource_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.resource_group_id_seq;
       public          postgres    false    227    6            �           0    0    resource_group_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.resource_group_id_seq OWNED BY public.resource_group.id;
          public          postgres    false    271                       1259    17634    resource_id_seq    SEQUENCE     x   CREATE SEQUENCE public.resource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.resource_id_seq;
       public          postgres    false    226    6            �           0    0    resource_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.resource_id_seq OWNED BY public.resource.id;
          public          postgres    false    272                       1259    17635    resource_property_id_seq    SEQUENCE     �   CREATE SEQUENCE public.resource_property_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.resource_property_id_seq;
       public          postgres    false    6    234            �           0    0    resource_property_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.resource_property_id_seq OWNED BY public.resource_property.id;
          public          postgres    false    273                       1259    17641    system_settings_id_seq    SEQUENCE        CREATE SEQUENCE public.system_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.system_settings_id_seq;
       public          postgres    false    274    6            �           0    0    system_settings_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.system_settings_id_seq OWNED BY public.system_settings.id;
          public          postgres    false    275                       1259    17642    type_detail    TABLE     ]  CREATE TABLE public.type_detail (
    id bigint NOT NULL,
    type_id bigint,
    width double precision,
    height double precision,
    depth double precision,
    top_clearance double precision,
    bottom_clearance double precision,
    left_clearance double precision,
    right_clearance double precision,
    front_clearance double precision,
    rear_clearance double precision,
    installation_method text,
    process_interface text,
    control_interface text,
    energy_supply text,
    energy_use double precision,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
    DROP TABLE public.type_detail;
       public         heap    postgres    false    6            �           0    0    COLUMN type_detail.width    COMMENT     A   COMMENT ON COLUMN public.type_detail.width IS 'the width in mm';
          public          postgres    false    276            �           0    0    COLUMN type_detail.height    COMMENT     C   COMMENT ON COLUMN public.type_detail.height IS 'the height in mm';
          public          postgres    false    276            �           0    0    COLUMN type_detail.depth    COMMENT     A   COMMENT ON COLUMN public.type_detail.depth IS 'the depth in mm';
          public          postgres    false    276            �           0    0     COLUMN type_detail.top_clearance    COMMENT     f   COMMENT ON COLUMN public.type_detail.top_clearance IS 'minimum allowed clearance from the top in mm';
          public          postgres    false    276            �           0    0 #   COLUMN type_detail.bottom_clearance    COMMENT     l   COMMENT ON COLUMN public.type_detail.bottom_clearance IS 'minimum allowed clearance from the bottom in mm';
          public          postgres    false    276            �           0    0 !   COLUMN type_detail.left_clearance    COMMENT     m   COMMENT ON COLUMN public.type_detail.left_clearance IS 'minimum allowed clearance from the left side in mm';
          public          postgres    false    276            �           0    0 "   COLUMN type_detail.right_clearance    COMMENT     n   COMMENT ON COLUMN public.type_detail.right_clearance IS 'minimum allowed clearance from the left side in mm';
          public          postgres    false    276            �           0    0 "   COLUMN type_detail.front_clearance    COMMENT     j   COMMENT ON COLUMN public.type_detail.front_clearance IS 'minimum allowed clearance from the front in mm';
          public          postgres    false    276            �           0    0 !   COLUMN type_detail.rear_clearance    COMMENT     h   COMMENT ON COLUMN public.type_detail.rear_clearance IS 'minimum allowed clearance from the rear in mm';
          public          postgres    false    276            �           0    0 &   COLUMN type_detail.installation_method    COMMENT     �   COMMENT ON COLUMN public.type_detail.installation_method IS 'how this device should be installed, eg panel mount, direct buried etc';
          public          postgres    false    276            �           0    0 $   COLUMN type_detail.process_interface    COMMENT     �   COMMENT ON COLUMN public.type_detail.process_interface IS 'Thi interface of this device to the process equipment, maybe 1"BSP, DN100 ANSI flange etc.';
          public          postgres    false    276            �           0    0 $   COLUMN type_detail.control_interface    COMMENT     �   COMMENT ON COLUMN public.type_detail.control_interface IS 'a text description of the interface for control, maybe 24Vdc, 4-20mA, volt-free contacts';
          public          postgres    false    276            �           0    0     COLUMN type_detail.energy_supply    COMMENT     �   COMMENT ON COLUMN public.type_detail.energy_supply IS 'a description of the enery supply for this equipment, eg 24Vdc, loop powered, 6bar compressed air etc.';
          public          postgres    false    276            �           0    0    COLUMN type_detail.energy_use    COMMENT     �   COMMENT ON COLUMN public.type_detail.energy_use IS 'a number representing the nominal energy use by this device, could be W (for electricity), kg/hr (for air or steam) etc.';
          public          postgres    false    276                       1259    17647    type_detail_id_seq    SEQUENCE     {   CREATE SEQUENCE public.type_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.type_detail_id_seq;
       public          postgres    false    6    276            �           0    0    type_detail_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.type_detail_id_seq OWNED BY public.type_detail.id;
          public          postgres    false    277                       1259    17648    type_history    TABLE     �   CREATE TABLE public.type_history (
    id bigint NOT NULL,
    type_id bigint NOT NULL,
    description text NOT NULL,
    reason text NOT NULL,
    comment text,
    modified_by text NOT NULL,
    modified_at timestamp(0) with time zone NOT NULL
);
     DROP TABLE public.type_history;
       public         heap    postgres    false    6                       1259    17653    type_history_id_seq    SEQUENCE     |   CREATE SEQUENCE public.type_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.type_history_id_seq;
       public          postgres    false    6    278            �           0    0    type_history_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.type_history_id_seq OWNED BY public.type_history.id;
          public          postgres    false    279                       1259    17654    type_interface_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.type_interface_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.type_interface_id_seq;
       public          postgres    false    228    6            �           0    0    type_interface_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.type_interface_id_seq OWNED BY public.type_interface.id;
          public          postgres    false    280            (           1259    17865    type_purchasing    VIEW       CREATE VIEW public.type_purchasing AS
SELECT
    NULL::public.ltree AS type_path,
    NULL::text AS type_label,
    NULL::text AS model,
    NULL::text AS type_modifier,
    NULL::text AS manufacturer,
    NULL::text AS type_description,
    NULL::text AS type_comment,
    NULL::boolean AS type_is_approved,
    NULL::bigint AS total_required,
    NULL::bigint AS ordered_count,
    NULL::bigint AS to_order_count,
    NULL::bigint AS received_count,
    NULL::bigint AS installed_count,
    NULL::integer AS lead_time_days;
 "   DROP VIEW public.type_purchasing;
       public          michaelm    false    6    2    2    6    6    2    6    2    6    2    6            �           0    0    VIEW type_purchasing    COMMENT     �   COMMENT ON VIEW public.type_purchasing IS 'Displays the calculated aggregated information for all equipment with commercial (purchasing) information recorded.';
          public          michaelm    false    296                       1259    17655    type_resource_id_seq    SEQUENCE     }   CREATE SEQUENCE public.type_resource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.type_resource_id_seq;
       public          postgres    false    222    6            �           0    0    type_resource_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.type_resource_id_seq OWNED BY public.type_resource.id;
          public          postgres    false    281                       1259    17656    user    TABLE     �   CREATE TABLE public."user" (
    id bigint NOT NULL,
    full_name text NOT NULL,
    os_username text NOT NULL,
    os_user_id text,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
    DROP TABLE public."user";
       public         heap    postgres    false    6            �           0    0    COLUMN "user".os_username    COMMENT     W   COMMENT ON COLUMN public."user".os_username IS 'the username in the operating system';
          public          postgres    false    282            �           0    0    COLUMN "user".os_user_id    COMMENT     \   COMMENT ON COLUMN public."user".os_user_id IS 'the unique user id in the operating system';
          public          postgres    false    282                       1259    17661    user_authority    TABLE     �   CREATE TABLE public.user_authority (
    id bigint NOT NULL,
    user_id bigint,
    authority_id bigint,
    comment text,
    modified_at timestamp(0) with time zone NOT NULL
);
 "   DROP TABLE public.user_authority;
       public         heap    postgres    false    6                       1259    17666    user_authority_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.user_authority_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.user_authority_id_seq;
       public          postgres    false    283    6            �           0    0    user_authority_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.user_authority_id_seq OWNED BY public.user_authority.id;
          public          postgres    false    284                       1259    17667    user_id_seq    SEQUENCE     t   CREATE SEQUENCE public.user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE public.user_id_seq;
       public          postgres    false    6    282            �           0    0    user_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;
          public          postgres    false    285                       1259    17668    view_report_connection    VIEW     I  CREATE VIEW public.view_report_connection AS
 SELECT connection.id,
    connection.path,
    connection.connection_type_id,
    connection.start_equipment_id,
    connection.start_interface_id,
    connection.end_equipment_id,
    connection.end_interface_id,
    connection.identifier,
    connection.description,
    connection.comment,
    connection.length,
    connection.is_approved,
    public.fn_hierarchy_path_check('connection'::text, connection.path) AS hierarchy_valid,
    public.fn_reference_path_check('connection'::text, connection.path, connection.id) AS reference_valid,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'equipment_id'::text, connection.start_equipment_id) AS start_equipment_valid,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'equipment_id'::text, connection.end_equipment_id) AS end_equipment_valid,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'interface_id'::text, connection.start_interface_id) AS start_interface_valid,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'interface_id'::text, connection.end_interface_id) AS end_interface_valid,
    public.fn_table_column_id_check('all_connection_detail'::text, 'connection_id'::text, connection.id) AS used_valid,
    public.fn_table_column_id_check('all_permitted_interface_connection'::text, 'connection_id'::text, connection.id) AS interface_class_valid,
    public.fn_connection_ids_check(connection.path, connection.start_interface_id, connection.end_interface_id) AS equipment_interface_ids_valid
   FROM public.connection;
 )   DROP VIEW public.view_report_connection;
       public          postgres    false    471    215    215    215    215    215    215    215    215    215    215    215    415    408    215    407    6    2    2    6    6    2    6    2    6    2    6                       1259    17673    view_report_connection_type    VIEW     <  CREATE VIEW public.view_report_connection_type AS
 SELECT connection_type.id,
    connection_type.path,
    connection_type.label,
    connection_type.model,
    connection_type.modifier,
    connection_type.manufacturer,
    connection_type.description,
    connection_type.comment,
    connection_type.is_approved,
    public.fn_hierarchy_path_check('connection_type'::text, connection_type.path) AS hierarchy_valid,
    public.fn_reference_path_check('connection_type'::text, connection_type.path, connection_type.id) AS reference_valid
   FROM public.connection_type;
 .   DROP VIEW public.view_report_connection_type;
       public          postgres    false    218    218    218    218    218    218    218    415    471    218    218    2    2    6    6    2    6    2    6    2    6    6                        1259    17677    view_report_equipment    VIEW     Q  CREATE VIEW public.view_report_equipment AS
 SELECT equipment.id,
    equipment.path,
    equipment.location_path,
    equipment.type_id,
    equipment.identifier,
    equipment.description,
    equipment.is_approved,
    equipment.comment,
    public.fn_hierarchy_path_check('equipment'::text, equipment.path) AS hierarchy_valid,
    public.fn_reference_path_check('equipment'::text, equipment.path, equipment.id) AS reference_valid,
    public.fn_table_column_id_check('all_equipment_resource'::text, 'equipment_id'::text, equipment.id) AS resource_exist_valid,
    public.fn_table_column_id_check('all_equipment_property'::text, 'equipment_id'::text, equipment.id) AS property_exist_valid,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'equipment_id'::text, equipment.id) AS interface_exist_valid
   FROM public.equipment;
 (   DROP VIEW public.view_report_equipment;
       public          postgres    false    219    219    219    415    471    408    219    219    219    219    219    2    2    6    6    2    6    2    6    2    6    6    2    2    6    6    2    6    2    6    2    6            !           1259    17681    view_report_equipment_type    VIEW     �  CREATE VIEW public.view_report_equipment_type AS
 SELECT equipment_type.id,
    equipment_type.path,
    equipment_type.label,
    equipment_type.model,
    equipment_type.modifier,
    equipment_type.manufacturer,
    equipment_type.description,
    equipment_type.comment,
    equipment_type.is_approved,
    public.fn_hierarchy_path_check('equipment_type'::text, equipment_type.path) AS hierarchy_valid,
    public.fn_reference_path_check('equipment_type'::text, equipment_type.path, equipment_type.id) AS reference_valid,
    public.fn_table_column_id_check('all_type_resource'::text, 'type_id'::text, equipment_type.id) AS resource_exist_valid,
    public.fn_table_column_id_check('all_equipment_property'::text, 'type_id'::text, equipment_type.id) AS property_exist_valid,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'type_id'::text, equipment_type.id) AS interface_exist_valid
   FROM public.equipment_type;
 -   DROP VIEW public.view_report_equipment_type;
       public          postgres    false    221    221    471    408    221    221    221    221    221    221    415    221    6    2    2    6    6    2    6    2    6    2    6            "           1259    17685    view_report_interface    VIEW     �  CREATE VIEW public.view_report_interface AS
 SELECT interface.id,
    interface.attribute_class_id AS interface_class_id,
    interface.connecting_attribute_class_id AS connecting_interface_class_id,
    interface.identifier,
    interface.description,
    interface.comment,
    interface.is_intermediate,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'interface_id'::text, interface.id) AS used_valid
   FROM public.interface;
 (   DROP VIEW public.view_report_interface;
       public          postgres    false    224    224    224    224    408    224    224    224    6            #           1259    17689    view_report_interface_class    VIEW     J  CREATE VIEW public.view_report_interface_class AS
 SELECT attribute_class.id,
    attribute_class.label,
    attribute_class.description,
    attribute_class.comment,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'interface_class_id'::text, attribute_class.id) AS used_valid
   FROM public.attribute_class;
 .   DROP VIEW public.view_report_interface_class;
       public          postgres    false    225    408    225    225    225    6            $           1259    17693    view_report_property    VIEW     n  CREATE VIEW public.view_report_property AS
 SELECT property.id,
    property.modifier,
    property.description,
    property.default_value,
    property.default_datatype_id,
    property.comment,
    property.is_reportable,
    public.fn_table_column_id_check('all_equipment_property'::text, 'property_id'::text, property.id) AS used_valid
   FROM public.property;
 '   DROP VIEW public.view_report_property;
       public          postgres    false    232    232    232    232    232    232    408    232    6            %           1259    17697    view_report_resource    VIEW     /  CREATE VIEW public.view_report_resource AS
 SELECT resource.id,
    resource.resource_group_id,
    resource.modifier,
    resource.description,
    resource.comment,
    public.fn_table_column_id_check('all_type_resource'::text, 'resource_id'::text, resource.id) AS used_valid,
    public.fn_table_column_id_check('all_equipment_property'::text, 'resource_id'::text, resource.id) AS property_exist_valid,
    public.fn_table_column_id_check('all_equipment_interface'::text, 'resource_id'::text, resource.id) AS interface_exist_valid
   FROM public.resource;
 '   DROP VIEW public.view_report_resource;
       public          postgres    false    226    226    408    226    226    226    6            �           2604    17715    attribute_class id    DEFAULT     x   ALTER TABLE ONLY public.attribute_class ALTER COLUMN id SET DEFAULT nextval('public.interface_class_id_seq'::regclass);
 A   ALTER TABLE public.attribute_class ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    264    225            �           2604    17701    authority id    DEFAULT     l   ALTER TABLE ONLY public.authority ALTER COLUMN id SET DEFAULT nextval('public.authority_id_seq'::regclass);
 ;   ALTER TABLE public.authority ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    240    239            {           2604    17702    connection id    DEFAULT     n   ALTER TABLE ONLY public.connection ALTER COLUMN id SET DEFAULT nextval('public.connection_id_seq'::regclass);
 <   ALTER TABLE public.connection ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    247    215            �           2604    17861    connection_commercial id    DEFAULT     �   ALTER TABLE ONLY public.connection_commercial ALTER COLUMN id SET DEFAULT nextval('public.connection_commerical_id_seq'::regclass);
 G   ALTER TABLE public.connection_commercial ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    295    294            �           2604    17704    connection_history id    DEFAULT     ~   ALTER TABLE ONLY public.connection_history ALTER COLUMN id SET DEFAULT nextval('public.connection_history_id_seq'::regclass);
 D   ALTER TABLE public.connection_history ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    246    245            �           2604    17705    connection_state id    DEFAULT     z   ALTER TABLE ONLY public.connection_state ALTER COLUMN id SET DEFAULT nextval('public.connection_state_id_seq'::regclass);
 B   ALTER TABLE public.connection_state ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    249    248            ~           2604    17706    connection_type id    DEFAULT     x   ALTER TABLE ONLY public.connection_type ALTER COLUMN id SET DEFAULT nextval('public.connection_type_id_seq'::regclass);
 A   ALTER TABLE public.connection_type ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    250    218            �           2604    17707    datatype id    DEFAULT     j   ALTER TABLE ONLY public.datatype ALTER COLUMN id SET DEFAULT nextval('public.datatype_id_seq'::regclass);
 :   ALTER TABLE public.datatype ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    251    231            �           2604    17708    equipment id    DEFAULT     l   ALTER TABLE ONLY public.equipment ALTER COLUMN id SET DEFAULT nextval('public.equipment_id_seq'::regclass);
 ;   ALTER TABLE public.equipment ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    256    219            �           2604    17709    equipment_commercial id    DEFAULT     �   ALTER TABLE ONLY public.equipment_commercial ALTER COLUMN id SET DEFAULT nextval('public.equipment_commercial_id_seq'::regclass);
 F   ALTER TABLE public.equipment_commercial ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    253    252            �           2604    17710    equipment_history id    DEFAULT     |   ALTER TABLE ONLY public.equipment_history ALTER COLUMN id SET DEFAULT nextval('public.equipment_history_id_seq'::regclass);
 C   ALTER TABLE public.equipment_history ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    255    254            �           2604    17711    equipment_state id    DEFAULT     x   ALTER TABLE ONLY public.equipment_state ALTER COLUMN id SET DEFAULT nextval('public.equipment_state_id_seq'::regclass);
 A   ALTER TABLE public.equipment_state ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    258    257            �           2604    17712    equipment_type id    DEFAULT     v   ALTER TABLE ONLY public.equipment_type ALTER COLUMN id SET DEFAULT nextval('public.equipment_type_id_seq'::regclass);
 @   ALTER TABLE public.equipment_type ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    259    221            �           2604    17713    general_history id    DEFAULT     x   ALTER TABLE ONLY public.general_history ALTER COLUMN id SET DEFAULT nextval('public.general_history_id_seq'::regclass);
 A   ALTER TABLE public.general_history ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    263    262            �           2604    17714    interface id    DEFAULT     l   ALTER TABLE ONLY public.interface ALTER COLUMN id SET DEFAULT nextval('public.interface_id_seq'::regclass);
 ;   ALTER TABLE public.interface ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    265    224            �           2604    17716 !   permitted_interface_connection id    DEFAULT     �   ALTER TABLE ONLY public.permitted_interface_connection ALTER COLUMN id SET DEFAULT nextval('public.permitted_interface_connection_id_seq'::regclass);
 P   ALTER TABLE public.permitted_interface_connection ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    266    238            �           2604    17717    possible_state id    DEFAULT     v   ALTER TABLE ONLY public.possible_state ALTER COLUMN id SET DEFAULT nextval('public.possible_state_id_seq'::regclass);
 @   ALTER TABLE public.possible_state ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    268    267            �           2604    17718    property id    DEFAULT     j   ALTER TABLE ONLY public.property ALTER COLUMN id SET DEFAULT nextval('public.property_id_seq'::regclass);
 :   ALTER TABLE public.property ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    269    232            �           2604    17719    property_value id    DEFAULT     v   ALTER TABLE ONLY public.property_value ALTER COLUMN id SET DEFAULT nextval('public.property_value_id_seq'::regclass);
 @   ALTER TABLE public.property_value ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    270    233            �           2604    17720    resource id    DEFAULT     j   ALTER TABLE ONLY public.resource ALTER COLUMN id SET DEFAULT nextval('public.resource_id_seq'::regclass);
 :   ALTER TABLE public.resource ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    272    226            �           2604    17721    resource_group id    DEFAULT     v   ALTER TABLE ONLY public.resource_group ALTER COLUMN id SET DEFAULT nextval('public.resource_group_id_seq'::regclass);
 @   ALTER TABLE public.resource_group ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    271    227            �           2604    17722    resource_property id    DEFAULT     |   ALTER TABLE ONLY public.resource_property ALTER COLUMN id SET DEFAULT nextval('public.resource_property_id_seq'::regclass);
 C   ALTER TABLE public.resource_property ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    273    234            �           2604    17723    system_settings id    DEFAULT     x   ALTER TABLE ONLY public.system_settings ALTER COLUMN id SET DEFAULT nextval('public.system_settings_id_seq'::regclass);
 A   ALTER TABLE public.system_settings ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    275    274            �           2604    17724    type_detail id    DEFAULT     p   ALTER TABLE ONLY public.type_detail ALTER COLUMN id SET DEFAULT nextval('public.type_detail_id_seq'::regclass);
 =   ALTER TABLE public.type_detail ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    277    276            �           2604    17725    type_history id    DEFAULT     r   ALTER TABLE ONLY public.type_history ALTER COLUMN id SET DEFAULT nextval('public.type_history_id_seq'::regclass);
 >   ALTER TABLE public.type_history ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    279    278            �           2604    17726    type_interface id    DEFAULT     v   ALTER TABLE ONLY public.type_interface ALTER COLUMN id SET DEFAULT nextval('public.type_interface_id_seq'::regclass);
 @   ALTER TABLE public.type_interface ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    280    228            �           2604    17727    type_resource id    DEFAULT     t   ALTER TABLE ONLY public.type_resource ALTER COLUMN id SET DEFAULT nextval('public.type_resource_id_seq'::regclass);
 ?   ALTER TABLE public.type_resource ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    281    222            �           2604    17728    user id    DEFAULT     d   ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);
 8   ALTER TABLE public."user" ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    285    282            �           2604    17729    user_authority id    DEFAULT     v   ALTER TABLE ONLY public.user_authority ALTER COLUMN id SET DEFAULT nextval('public.user_authority_id_seq'::regclass);
 @   ALTER TABLE public.user_authority ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    284    283            �          0    17458    attribute_class 
   TABLE DATA           W   COPY public.attribute_class (id, label, description, comment, modified_at) FROM stdin;
    public          postgres    false    225   j}      �          0    17541 	   authority 
   TABLE DATA           Q   COPY public.authority (id, label, description, comment, modified_at) FROM stdin;
    public          postgres    false    239   b~      �          0    17393 
   connection 
   TABLE DATA           �   COPY public.connection (id, path, use_parent_identifier, connection_type_id, start_equipment_id, start_interface_id, end_equipment_id, end_interface_id, identifier, description, comment, length, is_approved, modified_at, origin_path) FROM stdin;
    public          postgres    false    215   �~      �          0    17855    connection_commercial 
   TABLE DATA           M  COPY public.connection_commercial (id, connection_id, quote_reference, quote_price, lead_time_days, purchase_order_date, purchase_order_reference, due_date, received_date, location, unique_code, installed_date, warranty_end_date, comment, modified_at, design_approved, fat_complete, sat_complete, commissioning_complete) FROM stdin;
    public          postgres    false    294   �      �          0    17571    connection_history 
   TABLE DATA           w   COPY public.connection_history (id, connection_id, description, reason, comment, modified_by, modified_at) FROM stdin;
    public          postgres    false    245   f�      �          0    17578    connection_state 
   TABLE DATA           p   COPY public.connection_state (id, connection_id, possible_state_id, is_state, comment, modified_at) FROM stdin;
    public          postgres    false    248   ��      �          0    17410    connection_type 
   TABLE DATA           �   COPY public.connection_type (id, path, label, model, modifier, manufacturer, description, comment, is_approved, modified_at, is_hidden) FROM stdin;
    public          postgres    false    218   ��      �          0    17495    datatype 
   TABLE DATA           �   COPY public.datatype (id, label, scada_1, scada_2, scada_3, scada_4, scada_5, control_1, control_2, control_3, control_4, control_5, comment, modified_at, description) FROM stdin;
    public          postgres    false    231   E�      �          0    17420 	   equipment 
   TABLE DATA           �   COPY public.equipment (id, path, use_parent_identifier, location_path, type_id, identifier, description, is_approved, comment, modified_at, origin_path) FROM stdin;
    public          postgres    false    219   b�      �          0    17586    equipment_commercial 
   TABLE DATA           Z  COPY public.equipment_commercial (id, equipment_id, quote_reference, quote_price, lead_time_days, purchase_order_date, purchase_order_reference, due_date, received_date, location, unique_code, installed_date, warranty_end_date, comment, modified_at, design_approved, ready_for_fat, fat_complete, sat_complete, commissioning_complete) FROM stdin;
    public          postgres    false    252   ��      �          0    17592    equipment_history 
   TABLE DATA           u   COPY public.equipment_history (id, equipment_id, description, reason, comment, modified_by, modified_at) FROM stdin;
    public          postgres    false    254   8�      �          0    17599    equipment_state 
   TABLE DATA           n   COPY public.equipment_state (id, equipment_id, possible_state_id, is_state, comment, modified_at) FROM stdin;
    public          postgres    false    257   U�      �          0    17436    equipment_type 
   TABLE DATA           �   COPY public.equipment_type (id, path, label, model, modifier, manufacturer, description, comment, is_approved, modified_at, origin_path) FROM stdin;
    public          postgres    false    221   r�      �          0    17616    general_history 
   TABLE DATA           {   COPY public.general_history (id, table_name, table_id, description, reason, comment, modified_by, modified_at) FROM stdin;
    public          postgres    false    262   �      �          0    17452 	   interface 
   TABLE DATA           �   COPY public.interface (id, attribute_class_id, connecting_attribute_class_id, identifier, description, comment, modified_at, is_intermediate) FROM stdin;
    public          postgres    false    224   !�      �          0    17531    permitted_interface_connection 
   TABLE DATA           z   COPY public.permitted_interface_connection (id, interface_class_id, connection_type_id, comment, modified_at) FROM stdin;
    public          postgres    false    238   ��      �          0    17625    possible_state 
   TABLE DATA           �   COPY public.possible_state (id, label, description, valid_for_connection, valid_for_equipment, comment, authority_id, modified_at) FROM stdin;
    public          postgres    false    267   ��      �          0    17500    property 
   TABLE DATA           �   COPY public.property (id, modifier, description, default_value, default_datatype_id, comment, is_reportable, modified_at, attribute_class_id) FROM stdin;
    public          postgres    false    232         �          0    17506    property_value 
   TABLE DATA           z   COPY public.property_value (id, equipment_id, resource_property_id, value, datatype_id, comment, modified_at) FROM stdin;
    public          postgres    false    233   ��      �          0    17463    resource 
   TABLE DATA           f   COPY public.resource (id, resource_group_id, modifier, description, comment, modified_at) FROM stdin;
    public          postgres    false    226   B�      �          0    17468    resource_group 
   TABLE DATA           e   COPY public.resource_group (id, label, description, comment, is_reportable, modified_at) FROM stdin;
    public          postgres    false    227   �      �          0    17511    resource_property 
   TABLE DATA           �   COPY public.resource_property (id, resource_id, property_id, default_value, default_datatype_id, comment, modified_at) FROM stdin;
    public          postgres    false    234   ��      �          0    17636    system_settings 
   TABLE DATA           Q   COPY public.system_settings (id, label, value, comment, modified_at) FROM stdin;
    public          postgres    false    274   ��      �          0    17642    type_detail 
   TABLE DATA             COPY public.type_detail (id, type_id, width, height, depth, top_clearance, bottom_clearance, left_clearance, right_clearance, front_clearance, rear_clearance, installation_method, process_interface, control_interface, energy_supply, energy_use, comment, modified_at) FROM stdin;
    public          postgres    false    276   .�      �          0    17648    type_history 
   TABLE DATA           k   COPY public.type_history (id, type_id, description, reason, comment, modified_by, modified_at) FROM stdin;
    public          postgres    false    278   K�      �          0    17474    type_interface 
   TABLE DATA           m   COPY public.type_interface (id, type_resource_id, interface_id, comment, is_active, modified_at) FROM stdin;
    public          postgres    false    228   h�      �          0    17442    type_resource 
   TABLE DATA           W   COPY public.type_resource (id, type_id, resource_id, comment, modified_at) FROM stdin;
    public          postgres    false    222   ��      �          0    17656    user 
   TABLE DATA           ^   COPY public."user" (id, full_name, os_username, os_user_id, comment, modified_at) FROM stdin;
    public          postgres    false    282   \�      �          0    17661    user_authority 
   TABLE DATA           Y   COPY public.user_authority (id, user_id, authority_id, comment, modified_at) FROM stdin;
    public          postgres    false    283   ��      �           0    0    authority_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.authority_id_seq', 2, true);
          public          postgres    false    240            �           0    0    connection_commerical_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.connection_commerical_id_seq', 8, true);
          public          postgres    false    295            �           0    0    connection_history_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.connection_history_id_seq', 1, false);
          public          postgres    false    246            �           0    0    connection_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.connection_id_seq', 18, true);
          public          postgres    false    247            �           0    0    connection_state_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.connection_state_id_seq', 1, false);
          public          postgres    false    249            �           0    0    connection_type_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.connection_type_id_seq', 5, true);
          public          postgres    false    250            �           0    0    datatype_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.datatype_id_seq', 2, true);
          public          postgres    false    251            �           0    0    equipment_commercial_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.equipment_commercial_id_seq', 5, true);
          public          postgres    false    253            �           0    0    equipment_history_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.equipment_history_id_seq', 1, false);
          public          postgres    false    255            �           0    0    equipment_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.equipment_id_seq', 22, true);
          public          postgres    false    256            �           0    0    equipment_state_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.equipment_state_id_seq', 1, false);
          public          postgres    false    258            �           0    0    equipment_type_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.equipment_type_id_seq', 32, true);
          public          postgres    false    259            �           0    0    general_history_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.general_history_id_seq', 1, false);
          public          postgres    false    263            �           0    0    interface_class_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.interface_class_id_seq', 6, true);
          public          postgres    false    264            �           0    0    interface_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.interface_id_seq', 55, true);
          public          postgres    false    265            �           0    0 %   permitted_interface_connection_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.permitted_interface_connection_id_seq', 1, false);
          public          postgres    false    266            �           0    0    possible_state_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.possible_state_id_seq', 3, true);
          public          postgres    false    268            �           0    0    property_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.property_id_seq', 12, true);
          public          postgres    false    269            �           0    0    property_value_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.property_value_id_seq', 7, true);
          public          postgres    false    270            �           0    0    resource_group_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.resource_group_id_seq', 6, true);
          public          postgres    false    271            �           0    0    resource_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.resource_id_seq', 26, true);
          public          postgres    false    272            �           0    0    resource_property_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.resource_property_id_seq', 39, true);
          public          postgres    false    273            �           0    0    system_settings_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.system_settings_id_seq', 11, true);
          public          postgres    false    275            �           0    0    type_detail_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.type_detail_id_seq', 1, false);
          public          postgres    false    277            �           0    0    type_history_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.type_history_id_seq', 1, false);
          public          postgres    false    279            �           0    0    type_interface_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.type_interface_id_seq', 68, true);
          public          postgres    false    280            �           0    0    type_resource_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.type_resource_id_seq', 31, true);
          public          postgres    false    281            �           0    0    user_authority_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.user_authority_id_seq', 1, true);
          public          postgres    false    284            �           0    0    user_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('public.user_id_seq', 1, true);
          public          postgres    false    285            �           2606    17731     authority authority_label_unique 
   CONSTRAINT     \   ALTER TABLE ONLY public.authority
    ADD CONSTRAINT authority_label_unique UNIQUE (label);
 J   ALTER TABLE ONLY public.authority DROP CONSTRAINT authority_label_unique;
       public            postgres    false    239            �           2606    17733    authority authority_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.authority
    ADD CONSTRAINT authority_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.authority DROP CONSTRAINT authority_pkey;
       public            postgres    false    239                       2606    17863 0   connection_commercial connection_commerical_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.connection_commercial
    ADD CONSTRAINT connection_commerical_pkey PRIMARY KEY (id);
 Z   ALTER TABLE ONLY public.connection_commercial DROP CONSTRAINT connection_commerical_pkey;
       public            postgres    false    294            �           2606    17737 *   connection_history connection_history_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.connection_history
    ADD CONSTRAINT connection_history_pkey PRIMARY KEY (id);
 T   ALTER TABLE ONLY public.connection_history DROP CONSTRAINT connection_history_pkey;
       public            postgres    false    245            �           2606    17739    connection connection_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.connection
    ADD CONSTRAINT connection_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.connection DROP CONSTRAINT connection_pkey;
       public            postgres    false    215            �           2606    17741 &   connection_state connection_state_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.connection_state
    ADD CONSTRAINT connection_state_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.connection_state DROP CONSTRAINT connection_state_pkey;
       public            postgres    false    248            �           2606    17743 ,   connection_type connection_type_label_unique 
   CONSTRAINT     h   ALTER TABLE ONLY public.connection_type
    ADD CONSTRAINT connection_type_label_unique UNIQUE (label);
 V   ALTER TABLE ONLY public.connection_type DROP CONSTRAINT connection_type_label_unique;
       public            postgres    false    218            �           2606    17745 $   connection_type connection_type_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.connection_type
    ADD CONSTRAINT connection_type_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.connection_type DROP CONSTRAINT connection_type_pkey;
       public            postgres    false    218            �           2606    17747    datatype datatype_label_unique 
   CONSTRAINT     Z   ALTER TABLE ONLY public.datatype
    ADD CONSTRAINT datatype_label_unique UNIQUE (label);
 H   ALTER TABLE ONLY public.datatype DROP CONSTRAINT datatype_label_unique;
       public            postgres    false    231            �           2606    17749    datatype datatype_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.datatype
    ADD CONSTRAINT datatype_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.datatype DROP CONSTRAINT datatype_pkey;
       public            postgres    false    231            �           2606    17751 .   equipment_commercial equipment_commercial_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.equipment_commercial
    ADD CONSTRAINT equipment_commercial_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.equipment_commercial DROP CONSTRAINT equipment_commercial_pkey;
       public            postgres    false    252            �           2606    17753 (   equipment_history equipment_history_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.equipment_history
    ADD CONSTRAINT equipment_history_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.equipment_history DROP CONSTRAINT equipment_history_pkey;
       public            postgres    false    254            �           2606    17755    equipment equipment_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.equipment DROP CONSTRAINT equipment_pkey;
       public            postgres    false    219            �           2606    17757 $   equipment_state equipment_state_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.equipment_state
    ADD CONSTRAINT equipment_state_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.equipment_state DROP CONSTRAINT equipment_state_pkey;
       public            postgres    false    257            �           2606    17759 *   equipment_type equipment_type_label_unique 
   CONSTRAINT     f   ALTER TABLE ONLY public.equipment_type
    ADD CONSTRAINT equipment_type_label_unique UNIQUE (label);
 T   ALTER TABLE ONLY public.equipment_type DROP CONSTRAINT equipment_type_label_unique;
       public            postgres    false    221            �           2606    17761 "   equipment_type equipment_type_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.equipment_type
    ADD CONSTRAINT equipment_type_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.equipment_type DROP CONSTRAINT equipment_type_pkey;
       public            postgres    false    221            �           2606    17763 $   general_history general_history_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.general_history
    ADD CONSTRAINT general_history_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.general_history DROP CONSTRAINT general_history_pkey;
       public            postgres    false    262            �           2606    17765 ,   attribute_class interface_class_label_unique 
   CONSTRAINT     h   ALTER TABLE ONLY public.attribute_class
    ADD CONSTRAINT interface_class_label_unique UNIQUE (label);
 V   ALTER TABLE ONLY public.attribute_class DROP CONSTRAINT interface_class_label_unique;
       public            postgres    false    225            �           2606    17767 $   attribute_class interface_class_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.attribute_class
    ADD CONSTRAINT interface_class_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.attribute_class DROP CONSTRAINT interface_class_pkey;
       public            postgres    false    225            �           2606    17769    interface interface_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.interface
    ADD CONSTRAINT interface_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.interface DROP CONSTRAINT interface_pkey;
       public            postgres    false    224            �           2606    17771 *   possible_state possible_state_label_unique 
   CONSTRAINT     f   ALTER TABLE ONLY public.possible_state
    ADD CONSTRAINT possible_state_label_unique UNIQUE (label);
 T   ALTER TABLE ONLY public.possible_state DROP CONSTRAINT possible_state_label_unique;
       public            postgres    false    267            �           2606    17773 "   possible_state possible_state_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.possible_state
    ADD CONSTRAINT possible_state_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.possible_state DROP CONSTRAINT possible_state_pkey;
       public            postgres    false    267            �           2606    17775    property property_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.property
    ADD CONSTRAINT property_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.property DROP CONSTRAINT property_pkey;
       public            postgres    false    232            �           2606    17777 "   property_value property_value_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.property_value
    ADD CONSTRAINT property_value_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.property_value DROP CONSTRAINT property_value_pkey;
       public            postgres    false    233            �           2606    17779 *   resource_group resource_group_label_unique 
   CONSTRAINT     f   ALTER TABLE ONLY public.resource_group
    ADD CONSTRAINT resource_group_label_unique UNIQUE (label);
 T   ALTER TABLE ONLY public.resource_group DROP CONSTRAINT resource_group_label_unique;
       public            postgres    false    227            �           2606    17781 "   resource_group resource_group_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.resource_group
    ADD CONSTRAINT resource_group_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.resource_group DROP CONSTRAINT resource_group_pkey;
       public            postgres    false    227            �           2606    17783    resource resource_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.resource
    ADD CONSTRAINT resource_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.resource DROP CONSTRAINT resource_pkey;
       public            postgres    false    226            �           2606    17785 (   resource_property resource_property_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.resource_property
    ADD CONSTRAINT resource_property_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.resource_property DROP CONSTRAINT resource_property_pkey;
       public            postgres    false    234            �           2606    17787 ,   system_settings system_settings_label_unique 
   CONSTRAINT     h   ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_label_unique UNIQUE (label);
 V   ALTER TABLE ONLY public.system_settings DROP CONSTRAINT system_settings_label_unique;
       public            postgres    false    274            �           2606    17789 $   system_settings system_settings_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.system_settings DROP CONSTRAINT system_settings_pkey;
       public            postgres    false    274            �           2606    17791    type_detail type_detail_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.type_detail
    ADD CONSTRAINT type_detail_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.type_detail DROP CONSTRAINT type_detail_pkey;
       public            postgres    false    276            �           2606    17793    type_history type_history_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.type_history
    ADD CONSTRAINT type_history_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.type_history DROP CONSTRAINT type_history_pkey;
       public            postgres    false    278            �           2606    17795 "   type_interface type_interface_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.type_interface
    ADD CONSTRAINT type_interface_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.type_interface DROP CONSTRAINT type_interface_pkey;
       public            postgres    false    228            �           2606    17797     type_resource type_resource_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.type_resource
    ADD CONSTRAINT type_resource_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.type_resource DROP CONSTRAINT type_resource_pkey;
       public            postgres    false    222                       2606    17799 "   user_authority user_authority_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.user_authority
    ADD CONSTRAINT user_authority_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.user_authority DROP CONSTRAINT user_authority_pkey;
       public            postgres    false    283                       2606    17801    user user_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public."user" DROP CONSTRAINT user_pkey;
       public            postgres    false    282            �           1259    17802    authority_id_index    INDEX     F   CREATE INDEX authority_id_index ON public.authority USING btree (id);
 &   DROP INDEX public.authority_id_index;
       public            postgres    false    239                       1259    17864 ,   connection_commerical_id_connection_id_index    INDEX     {   CREATE INDEX connection_commerical_id_connection_id_index ON public.connection_commercial USING btree (id, connection_id);
 @   DROP INDEX public.connection_commerical_id_connection_id_index;
       public            postgres    false    294    294            �           1259    17804 )   connection_history_id_connection_id_index    INDEX     u   CREATE INDEX connection_history_id_connection_id_index ON public.connection_history USING btree (id, connection_id);
 =   DROP INDEX public.connection_history_id_connection_id_index;
       public            postgres    false    245    245            �           1259    17805    connection_id_index    INDEX     H   CREATE INDEX connection_id_index ON public.connection USING btree (id);
 '   DROP INDEX public.connection_id_index;
       public            postgres    false    215            �           1259    17806 '   connection_state_id_connection_id_index    INDEX     q   CREATE INDEX connection_state_id_connection_id_index ON public.connection_state USING btree (id, connection_id);
 ;   DROP INDEX public.connection_state_id_connection_id_index;
       public            postgres    false    248    248            �           1259    17807    connection_type_id_index    INDEX     R   CREATE INDEX connection_type_id_index ON public.connection_type USING btree (id);
 ,   DROP INDEX public.connection_type_id_index;
       public            postgres    false    218            �           1259    17808    datatype_id_index    INDEX     D   CREATE INDEX datatype_id_index ON public.datatype USING btree (id);
 %   DROP INDEX public.datatype_id_index;
       public            postgres    false    231            �           1259    17809 *   equipment_commercial_id_equipment_id_index    INDEX     w   CREATE INDEX equipment_commercial_id_equipment_id_index ON public.equipment_commercial USING btree (id, equipment_id);
 >   DROP INDEX public.equipment_commercial_id_equipment_id_index;
       public            postgres    false    252    252            �           1259    17810 '   equipment_history_id_equipment_id_index    INDEX     q   CREATE INDEX equipment_history_id_equipment_id_index ON public.equipment_history USING btree (id, equipment_id);
 ;   DROP INDEX public.equipment_history_id_equipment_id_index;
       public            postgres    false    254    254            �           1259    17811    equipment_id_type_id_index    INDEX     W   CREATE INDEX equipment_id_type_id_index ON public.equipment USING btree (id, type_id);
 .   DROP INDEX public.equipment_id_type_id_index;
       public            postgres    false    219    219            �           1259    17812 %   equipment_state_id_equipment_id_index    INDEX     m   CREATE INDEX equipment_state_id_equipment_id_index ON public.equipment_state USING btree (id, equipment_id);
 9   DROP INDEX public.equipment_state_id_equipment_id_index;
       public            postgres    false    257    257            �           1259    17813    equipment_type_id_index    INDEX     P   CREATE INDEX equipment_type_id_index ON public.equipment_type USING btree (id);
 +   DROP INDEX public.equipment_type_id_index;
       public            postgres    false    221            �           1259    17814    general_history_id_index    INDEX     R   CREATE INDEX general_history_id_index ON public.general_history USING btree (id);
 ,   DROP INDEX public.general_history_id_index;
       public            postgres    false    262            �           1259    17815    interface_class_id_index    INDEX     R   CREATE INDEX interface_class_id_index ON public.attribute_class USING btree (id);
 ,   DROP INDEX public.interface_class_id_index;
       public            postgres    false    225            �           1259    17816    interface_id_index    INDEX     F   CREATE INDEX interface_id_index ON public.interface USING btree (id);
 &   DROP INDEX public.interface_id_index;
       public            postgres    false    224            �           1259    17817 '   permitted_interface_connection_id_index    INDEX     p   CREATE INDEX permitted_interface_connection_id_index ON public.permitted_interface_connection USING btree (id);
 ;   DROP INDEX public.permitted_interface_connection_id_index;
       public            postgres    false    238            �           1259    17818    possible_state_id_index    INDEX     P   CREATE INDEX possible_state_id_index ON public.possible_state USING btree (id);
 +   DROP INDEX public.possible_state_id_index;
       public            postgres    false    267            �           1259    17819    property_id_index    INDEX     D   CREATE INDEX property_id_index ON public.property USING btree (id);
 %   DROP INDEX public.property_id_index;
       public            postgres    false    232            �           1259    17820 $   property_value_id_equipment_id_index    INDEX     k   CREATE INDEX property_value_id_equipment_id_index ON public.property_value USING btree (id, equipment_id);
 8   DROP INDEX public.property_value_id_equipment_id_index;
       public            postgres    false    233    233            �           1259    17821    resource_group_id_index    INDEX     P   CREATE INDEX resource_group_id_index ON public.resource_group USING btree (id);
 +   DROP INDEX public.resource_group_id_index;
       public            postgres    false    227            �           1259    17822    resource_id_index    INDEX     D   CREATE INDEX resource_id_index ON public.resource USING btree (id);
 %   DROP INDEX public.resource_id_index;
       public            postgres    false    226            �           1259    17823 /   resource_property_resource_id_property_id_index    INDEX     �   CREATE INDEX resource_property_resource_id_property_id_index ON public.resource_property USING btree (resource_id, property_id);
 C   DROP INDEX public.resource_property_resource_id_property_id_index;
       public            postgres    false    234    234            �           1259    17824    system_settings_id_index    INDEX     R   CREATE INDEX system_settings_id_index ON public.system_settings USING btree (id);
 ,   DROP INDEX public.system_settings_id_index;
       public            postgres    false    274            �           1259    17825    type_detail_id_type_id_index    INDEX     [   CREATE INDEX type_detail_id_type_id_index ON public.type_detail USING btree (id, type_id);
 0   DROP INDEX public.type_detail_id_type_id_index;
       public            postgres    false    276    276            �           1259    17826    type_history_id_type_id_index    INDEX     ]   CREATE INDEX type_history_id_type_id_index ON public.type_history USING btree (id, type_id);
 1   DROP INDEX public.type_history_id_type_id_index;
       public            postgres    false    278    278            �           1259    17827 2   type_interface_type_resource_id_interface_id_index    INDEX     �   CREATE INDEX type_interface_type_resource_id_interface_id_index ON public.type_interface USING btree (type_resource_id, interface_id);
 F   DROP INDEX public.type_interface_type_resource_id_interface_id_index;
       public            postgres    false    228    228            �           1259    17828 '   type_resource_type_id_resource_id_index    INDEX     q   CREATE INDEX type_resource_type_id_resource_id_index ON public.type_resource USING btree (type_id, resource_id);
 ;   DROP INDEX public.type_resource_type_id_resource_id_index;
       public            postgres    false    222    222                       1259    17829    user_authority_id_user_id_index    INDEX     a   CREATE INDEX user_authority_id_user_id_index ON public.user_authority USING btree (id, user_id);
 3   DROP INDEX public.user_authority_id_user_id_index;
       public            postgres    false    283    283            �           1259    17830    user_id_index    INDEX     >   CREATE INDEX user_id_index ON public."user" USING btree (id);
 !   DROP INDEX public.user_id_index;
       public            postgres    false    282            �           2618    17868    type_purchasing _RETURN    RULE       CREATE OR REPLACE VIEW public.type_purchasing AS
 SELECT et.path AS type_path,
    et.label AS type_label,
    et.model,
    et.modifier AS type_modifier,
    et.manufacturer,
    et.description AS type_description,
    et.comment AS type_comment,
    et.is_approved AS type_is_approved,
    count(ec.id) AS total_required,
    count(ec.purchase_order_reference) AS ordered_count,
    (count(ec.id) - count(ec.purchase_order_reference)) AS to_order_count,
    count(ec.received_date) AS received_count,
    count(ec.installed_date) AS installed_count,
    max(ec.lead_time_days) AS lead_time_days
   FROM ((public.equipment e
     JOIN public.equipment_commercial ec ON ((e.id = ec.equipment_id)))
     LEFT JOIN public.equipment_type et ON ((e.type_id = et.id)))
  GROUP BY et.id;
   CREATE OR REPLACE VIEW public.type_purchasing AS
SELECT
    NULL::public.ltree AS type_path,
    NULL::text AS type_label,
    NULL::text AS model,
    NULL::text AS type_modifier,
    NULL::text AS manufacturer,
    NULL::text AS type_description,
    NULL::text AS type_comment,
    NULL::boolean AS type_is_approved,
    NULL::bigint AS total_required,
    NULL::bigint AS ordered_count,
    NULL::bigint AS to_order_count,
    NULL::bigint AS received_count,
    NULL::bigint AS installed_count,
    NULL::integer AS lead_time_days;
       public          michaelm    false    221    219    221    221    221    221    221    252    252    252    252    252    252    3762    219    221    221    221    296            �           2618    17873 "   connection_type_purchasing _RETURN    RULE     �  CREATE OR REPLACE VIEW public.connection_type_purchasing AS
 SELECT ct.path AS type_path,
    ct.label AS type_label,
    ct.model,
    ct.modifier AS type_modifier,
    ct.manufacturer,
    ct.description AS type_description,
    ct.comment AS type_comment,
    ct.is_approved AS type_is_approved,
    count(cc.id) AS total_quantity,
    COALESCE(sum(cn.length), (0)::double precision) AS total_length,
    count(cc.purchase_order_reference) AS ordered_count,
    COALESCE(sum(cn.length) FILTER (WHERE (cc.purchase_order_reference IS NOT NULL)), (0)::double precision) AS ordered_length,
    (count(cc.id) - count(cc.purchase_order_reference)) AS to_order_count,
    (COALESCE(sum(cn.length), (0)::double precision) - COALESCE(sum(cn.length) FILTER (WHERE (cc.purchase_order_reference IS NOT NULL)), (0)::double precision)) AS to_order_length,
    count(cc.received_date) AS received_count,
    count(cc.installed_date) AS installed_count,
    max(cc.lead_time_days) AS lead_time_days
   FROM ((public.connection cn
     LEFT JOIN public.connection_commercial cc ON ((cn.id = cc.connection_id)))
     LEFT JOIN public.connection_type ct ON ((cn.connection_type_id = ct.id)))
  GROUP BY ct.id;
 �  CREATE OR REPLACE VIEW public.connection_type_purchasing AS
SELECT
    NULL::public.ltree AS type_path,
    NULL::text AS type_label,
    NULL::text AS model,
    NULL::text AS type_modifier,
    NULL::text AS manufacturer,
    NULL::text AS type_description,
    NULL::text AS type_comment,
    NULL::boolean AS type_is_approved,
    NULL::bigint AS total_quantity,
    NULL::double precision AS total_length,
    NULL::bigint AS ordered_count,
    NULL::double precision AS ordered_length,
    NULL::bigint AS to_order_count,
    NULL::double precision AS to_order_length,
    NULL::bigint AS received_count,
    NULL::bigint AS installed_count,
    NULL::integer AS lead_time_days;
       public          michaelm    false    218    218    218    218    218    218    218    215    215    218    3754    294    294    294    294    294    294    215    218    297                       2606    17831 Y   permitted_interface_connection permitted_interface_connection_connection_class_id_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY public.permitted_interface_connection
    ADD CONSTRAINT permitted_interface_connection_connection_class_id_foreign FOREIGN KEY (connection_type_id) REFERENCES public.connection_type(id);
 �   ALTER TABLE ONLY public.permitted_interface_connection DROP CONSTRAINT permitted_interface_connection_connection_class_id_foreign;
       public          postgres    false    3754    218    238            	           2606    17836 X   permitted_interface_connection permitted_interface_connection_interface_class_id_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY public.permitted_interface_connection
    ADD CONSTRAINT permitted_interface_connection_interface_class_id_foreign FOREIGN KEY (interface_class_id) REFERENCES public.attribute_class(id);
 �   ALTER TABLE ONLY public.permitted_interface_connection DROP CONSTRAINT permitted_interface_connection_interface_class_id_foreign;
       public          postgres    false    225    3773    238            �   �   x���1k�0�����R���v�zs�-�<e�p�T$����ip������;��Ix���pPΨ�������e]��p�Y�y�Fe�X!=`�p���m7�Y�;����y��7�t�JN��SA�"�u������v�L�������+`۲:r.s*ں��� +x�ښY��j/���}�8#�����W�6���k���2����h)�i���2�_$I�����      �   T   x�3�t���t+��QHLNN-.���4202�50�52U0��25�21�6��2��L-
�y9�:
y�
�)�%�y�x���qqq �{�      �     x����n�0���Q#�I��L�M<6@ ���ן��Q��ɪ�6��oࡅ����c���D�[}�7`d[�����5�(�+l��P��L�T�O��ݐ��Ÿ�h�J|_�?�i��'���q��͘��J�b�7�z<�/�iB+Cx������~�Q;2ͬAj� �n$Ԭ�j�`]3e��UŎ)%gq��g��B�4�� ��,'�l3�}c)Q���d$!)�W\R�4����+��Q�L6���?�^��      �   y   x�3�4�,�/I�50���42�4202�50�50���5�b"�"CsC#+ �6�@�5D6�D2܄ˌӒ�V��p�s�a�d#t���ۍ$�ɛ���P݆8|D��`J�b���� �X      �      x������ � �      �      x������ � �      �   �   x����
�0�ϛ�ػ��I
ⵧ�/�K�[	Ĥl[}}��� ���ƀ���tb���9:��"���i�|�!_Yпp��)�*�����dE�M�d>s���M��/[��@���[�qpA0_X\�8zaN|��q�t����TJ� �I�      �      x������ � �      �   (  x���]o� ��ɯ�~'v�H���U�zw�q)iXm� +��;Ӻ�M������'9a�0�v���9�n��/V>+�=�j���UNy6��)�1-�9]�����	�N���!���b������y�dy[k��w}�a�LS{c�l~f�Q�h�e�%��y�!fm�ҹ��^um�
���|
� ܌, ��e�n�9Q�~����i� ��)f�ed�H��m?mޗ|$Æd��ʓ�������=n�5;ې�d(9��ÌN�^�������Y~v%a���_���*�||a�� ��5hy��fH�q���5��!�1D���#��J��t� �m���Zd��art{͂i���`�+v��>�*T1V�/��v�m��^���O�{�Ue�#��ՠ�+ж�¢R���^�頌pz�QT��)��}���3�w]�"��}�5E17֘��J�����cn?/�f��p@]�e�b�6�!�ke�^y)��u�ֽj���
�``��oN�������\8��+M_$O�Oy�i�����G2�L~ ���      �   �   x��P�
1=�_�]Z�tҙ�p�ϵ�M���� �A/���Ӹz?¢��_p���2�
B�Z������A��:'�;�A�u�u��WM>314�d�Г��L�g�Lpڞ��1#^*�Ӯj�2}�K��ݘBg��a
      �      x������ � �      �      x������ � �      �   �  x��VKo�8>3���.��e�ћ�@v�X�K/�4���H-E6�ߡ�� RZ@�c8�8�'a$ȏ�ͷQ	7B�K�4-q	{�%2��тg�<�rǽ'�g�?�b�_#��$���q�"$�Ox�	+�_R�ϊ"ih���	Y�<�R���5e�k����X�Y�����J��a7!�p�ЦdJv�t�Mi
��	���x32ËJ�U�!ƕ-hR�qNfޜ�J�����R듍�����(��`@�NOCG,��|oA�
7�F��zkz+��M�0Y���Cc��e���H.j]��#3 lr�&=L7m�PN�\�`��A�'N�^�<�A^�歑�G�%���Z㌪:�NDd?��&��w@Y�I���.���v�yy}�Ժ5gw@�:E���AVH��\��0���;MI�as��ӛ����j�9��ټxQ ub�x����Re}��
iq�%н�2LgxS���ga���	����,��O���G��}�=;6D��J����2Hp-A57���o��� ��7m�s���(t�Z��>�$���a�r�v�9C'߮��u3v�*9H)FѺ�ɇ9�'�7qe��	�X#�����;Cy8	ْ��M�#���as����Fo�5��f�	QK04�K$襷���J?Ѳ�2�U���M|�H>�����Ӓ6�̹>?a���f�Y��b�z��f����E�\�]��w��<km��`\ɮJa����}].
.�,7���6^w �d)�������de��!���1s!yVR%���o�*���j���:�˦���(��hQ
��®�-��/��H�a@�[j�Ԛ@a܋ϕx�����/>��
��~��qU :���Q��ѶbL����������      �      x������ � �      �   W  x���M��0���G���q��(RYQ@ݏ����)�(8m������12G?��y=	�Ԛ-ה�������ʀ��5�Xc<��c?�4�3�{Ya�	YL�Z��_��)�_AF�����EW��n.�GQ;�Z[�����[4��=����'q.e��pz��}>~ 5�������� �'`����	y��X�(����Q���������d$=���T��R���5�z s�/�2$+!N���V����k���e Z�f�勗o�]���l��kH4D�+�05�k��~�\��1#X�*W���;��`g�_6n�5 [��$�`gF��0[�yɌ�Ό�������+�2o>|�yI ��X)���V������!@Лח�뢕M^����/l�y#n�'��-�s�W1�1\'sq���1m%�C~.F.)������ۉ��?�f�HF��YH梖�N�&���Ϣ����|l^_z�j��;p�$�H���Y'ë��1-8j�ȳT�T�9y%�i��Hz#}�)�o+���z'KQ�cY;S.'h��u�N�X�w��:~�ˬK�t����?И��      �      x������ � �      �      x������ � �      �   �   x���=�0���+�́��F��t��`\���֤�~�{A7�I/w��I�z�N����������w1��{�q�^C1{Pd��b���n�SJ�������LeKq����'G!���lX�\����7��F妀���BCX�[�,�����C��6*���[Vk7�a�n��M�s����a+�%�X�I~�7����,/����El�c�=���      �   �   x��˱
�0 ����K�]rI��:
␱K���V�)��K��oX���3�W!0��5�	�I�qȻ��!��VIi�V|�_؃� D���=�G|=�)�n]���k�y��Ͳ+w=o)���_��J)�W�E�      �   �  x����n! �3>���]�n����V���P�T����~a�jc�ы�a>ff�$!��!?��ґ߀3ੲ�]i��^[S��+L$M�6EFy��X���i"�����,JK�a�'}������{��6� ڧ��r��4��	� Y�	�w�V �KI�t�G@;�KI�A'�KI�A7����#8���[�DsFҸ<��V@�Qa�<L�?f�o�֮K���KOfDe���I�&V.�-}�Ǣ�S�6�ͱ�V(gZ�B9�w�Ю�6h�h����}�����I����t>�|k�p�
/=vnE�����mF�Z�C�ૄ��BTz^%��K�X~H��m�����D��HI��oMq�^m�Yc(��E}�<�7M�ΣZ�vϥQ��/�������F���L]      �   �   x���=�@���Wt���2�ՉY�X�x��q���K�i��M]q���UCX��<�{���
Oz�QG/7����{���+�5�5Hηu,��Z���Ŗ�I)ڑ���AE(��t�UL��PdSu��vfX�L���P�2\��]7�*;�b`תI��z�w�@d<�Y�����8�[5n�      �     x��Իq�0�����8�B�]��\�W�+�R�S3R�D
��&M���{��S����S����q@j��\v�gXH����52��g]Vb��&��Q�؞Orj-�o��)���r3���H9��rO�DʹJ��L�F��;�X�.8('�N�M�͡t%X���,5/X*���r�R� �/
p�T*����\{� ��|9s:,7c��%"�뎺#d�+����_� vN�=�������Ѻa��W9��*�      �   ]  x����j�@���S̱%�h�x3��@���
a�cܲٵ�I���Z	�Atg��?f�u�T�/7	��*�.x���a��OʏD3��T����X2]���z��lǷ� ]?t��	���@��i��l�[v�{�F��e��e�v]`&z�|���,�+]xGG�{^��v	�3��97��% URWJl\H������K�t��ݙ��]/t�&���P�,c�,��7s&q4��
���t�=X&u�nt�ÿFK�Cl�M�㭘�9ƅw�E���j�5?����i7���j� ¬tV�LЩ��zy�ӥ� VsJN���/��<X���d>b�M�+�chY�/cB�      �      x������ � �      �      x������ � �      �   >  x��ֽn�0 ��~
�����,�h�.���Bѐ��~��QHe2���Dޝx'K"�����C1�z�v(����n(��=���_�N��S��`��;�>P����ٞ�IE���RS��<���G�h
�W��7��A*p��,�dT0*��`t�)�)��	�$�*�*�@f q�������i^o����[�(ӡ� r�vA!�r}�r���8��;�s� Γ'O�HT.��7�� nҐ�	б����텬
���?V�FKCp)p��5r��+KT�N�D%�t��{��q:���|����VA�L��智$�����7�	\��P��n>����C�ӟ�k����5��5NQC��th5pa�4��ٰ$#�#����(w!P�@y;��70���9��f��[��j59�©D\M�η��	���<����#����-j��%j���qkc`��.b5X�6nXL�����֝?]"c&X�D�?���s�9"P���G��4���e	m"4��<Cl��<L}�[����w�"H"��G�B��� �H/ A%�r�2��������n���      �   �  x���=o�0�g�+n��'䃭�T��D�.&�H��vJ��{6EU�ܨY2$�s9�{�I��(!e�vЩ�ЄQOi2e3��9�s��|��HLJ�@+�r�k��w��"$�NLF��g#Ĉ:3cF��Ƙ̙�3vf1�L	��H���{{Z
d3�R��<�]���cl c�c�y,��!,�X1�%$��\�黮�<_P}p�l��ʩeP��fn���zS�V��>{R��T�� -�|/Z!-��&;^w�a�8JVF5�*U�n�N��WǠX�n������{-���eek%A퀃��]�^��ȫh;��ŭ#����ϫ`3$f����w.�.M⎋�?-0˵�H�I_� T�e��"�E\`�\J.3ڨ�1`Z���W���	�x��L&_>`�      �   <   x�3���L�HL�Q�M�N��̅�r9c�@����X��D��T��������T���+F��� �N�      �   +   x�3�4�?N##c]]#SK+S+Sm�=... z�^     