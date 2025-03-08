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
