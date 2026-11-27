INSERT INTO readers (full_name, email)
SELECT 'Читатель ' || g, 'reader' || g || '@example.com'
FROM generate_series(1, 1000) AS g;

INSERT INTO loans (copy_id, reader_id, loaned_at, due_at, returned_at)
SELECT c, r, t, t + interval '14 days', t + interval '7 days'
FROM (
    SELECT 1 + floor(random() * 15)::int   AS c,
           11 + floor(random() * 1000)::int AS r,
           now() - make_interval(days => 20 + floor(random() * 340)::int) AS t
    FROM generate_series(1, 2000)
) s;