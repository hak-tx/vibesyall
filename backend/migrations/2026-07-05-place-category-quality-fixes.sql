UPDATE places
SET
  category = 'Entertainment',
  primary_category = 'Entertainment',
  provider_category = 'Movie Theater'
WHERE (
    lower(name) LIKE '%cinem%'
    OR lower(name) LIKE '%movie theater%'
    OR lower(name) LIKE '%movie theatre%'
  )
  AND (
    provider_category IS NULL
    OR provider_category = ''
    OR lower(provider_category) IN ('music venue', 'restaurant')
  );

UPDATE places
SET
  category = 'Entertainment',
  primary_category = 'Entertainment'
WHERE lower(primary_category) = 'music venue'
  AND lower(provider_category) IN ('movie theater', 'theater');
