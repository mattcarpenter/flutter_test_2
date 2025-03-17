((bucket_id = 'recipe_images'::text) AND (( SELECT (auth.uid())::text AS uid) = (storage.foldername(name))[1]))
