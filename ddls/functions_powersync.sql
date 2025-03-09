CREATE OR REPLACE FUNCTION public.is_household_member(
    _household_id uuid,
    _user_id uuid
) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    member_exists boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM public.household_members hm
        WHERE hm.household_id = _household_id
          AND hm.user_id = _user_id
          AND hm.is_active = 1
    ) INTO member_exists;
    RETURN member_exists;
END;
$$;

CREATE OR REPLACE FUNCTION public.json_to_uuid_array(json_text text)
    RETURNS uuid[] AS $$
SELECT COALESCE(array_agg(value::uuid), '{}')
FROM jsonb_array_elements_text(json_text::jsonb) AS value;
$$ LANGUAGE sql IMMUTABLE STRICT;
