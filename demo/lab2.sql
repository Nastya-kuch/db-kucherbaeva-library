-- 1. Какие книги сейчас на руках, у кого и до какого срока? (JOIN 4 таблиц)
SELECT r.full_name AS reader, b.title, c.inventory_number, l.due_at
FROM loans l
JOIN readers r ON r.id = l.reader_id
JOIN copies c ON c.id = l.copy_id
JOIN books b ON b.id = c.book_id
WHERE l.returned_at IS NULL
ORDER BY l.due_at;

-- 2. Какие у книг авторы? (JOIN через связующую таблицу N:M)
SELECT b.title, a.full_name AS author
FROM books b
JOIN book_authors ba ON ba.book_id = b.id
JOIN authors a ON a.id = ba.author_id
ORDER BY b.title, a.full_name;

-- 3. Какие экземпляры изношены или повреждены и что это за книги?
SELECT c.inventory_number, c.condition, b.title
FROM copies c
JOIN books b ON b.id = c.book_id
WHERE c.condition IN ('worn', 'damaged')
ORDER BY c.condition, c.inventory_number;

-- 4. Сколько экземпляров у каждой книги? (GROUP BY по id книги)
SELECT b.id, b.title, count(c.id) AS copies_count
FROM books b
LEFT JOIN copies c ON c.book_id = b.id
GROUP BY b.id, b.title
ORDER BY copies_count DESC, b.title;

-- 5. Какие читатели брали книги 4 раза и больше? (GROUP BY + HAVING)
SELECT r.id, r.full_name, count(*) AS loans_count
FROM readers r
JOIN loans l ON l.reader_id = r.id
GROUP BY r.id, r.full_name
HAVING count(*) >= 4
ORDER BY loans_count DESC, r.id
LIMIT 20;

-- 6. Какие читатели ни разу не брали книгу? («сироты»: LEFT JOIN + IS NULL)
SELECT r.id, r.full_name
FROM readers r
LEFT JOIN loans l ON l.reader_id = r.id
WHERE l.id IS NULL
ORDER BY r.id
LIMIT 20;

-- 7. Какие книги сейчас выданы хотя бы одним экземпляром? (подзапрос IN)
SELECT b.id, b.title
FROM books b
WHERE b.id IN (
    SELECT c.book_id
    FROM copies c
    JOIN loans l ON l.copy_id = c.id
    WHERE l.returned_at IS NULL
)
ORDER BY b.title;

-- 8. Какие возвращённые выдачи были дольше среднего срока? (скалярный подзапрос)
SELECT l.id, l.copy_id, l.reader_id, l.returned_at - l.loaned_at AS held_for
FROM loans l
WHERE l.returned_at IS NOT NULL
AND (l.returned_at - l.loaned_at) > (
    SELECT avg(returned_at - loaned_at) FROM loans WHERE returned_at IS NOT NULL
)
ORDER BY held_for DESC
LIMIT 20;

-- 9. Выдаём читателю 1 экземпляр INV-011: число его выдач до и после (INSERT)
BEGIN;
SELECT count(*) AS loans_before FROM loans WHERE reader_id = 1;
INSERT INTO loans (copy_id, reader_id, due_at)
VALUES (11, 1, now() + interval '14 days');
SELECT count(*) AS loans_after FROM loans WHERE reader_id = 1;
ROLLBACK;

-- 10. Читатель вернул книгу по выдаче 4: состояние до и после (UPDATE)
BEGIN;
SELECT id, returned_at FROM loans WHERE id = 4;
UPDATE loans SET returned_at = now() WHERE id = 4 AND returned_at IS NULL;
SELECT id, returned_at FROM loans WHERE id = 4;
ROLLBACK;

-- 11. Начисляем штраф 5 за каждый день просрочки по невозвращённым книгам (UPDATE)
BEGIN;
SELECT id, due_at, fine FROM loans WHERE returned_at IS NULL AND due_at < now();
UPDATE loans
SET fine = 5 * greatest(1, ceil(extract(epoch FROM now() - due_at) / 86400))
WHERE returned_at IS NULL AND due_at < now();
SELECT id, due_at, fine FROM loans WHERE returned_at IS NULL AND due_at < now();
ROLLBACK;

-- 12. Удаляем читателей, у которых нет ни одной выдачи: число читателей до и после (DELETE)
BEGIN;
SELECT count(*) AS readers_before FROM readers;
DELETE FROM readers r
WHERE NOT EXISTS (SELECT 1 FROM loans l WHERE l.reader_id = r.id);
SELECT count(*) AS readers_after FROM readers;
ROLLBACK;

-- 13. Топ-3 самых выдаваемых книги в каждой категории состояния экземпляров (CTE + ROW_NUMBER)
WITH stats AS (
    SELECT c.condition, b.id AS book_id, b.title, count(l.id) AS loans_count
    FROM books b
    JOIN copies c ON c.book_id = b.id
    LEFT JOIN loans l ON l.copy_id = c.id
    GROUP BY c.condition, b.id, b.title
),
ranked AS (
    SELECT stats.*, ROW_NUMBER() OVER (PARTITION BY condition ORDER BY loans_count DESC, book_id) AS rn
    FROM stats
)
SELECT condition, rn, title, loans_count
FROM ranked
WHERE rn <= 3
ORDER BY condition, rn;

-- 14. Сколько выдач было в каждом месяце и накопительным итогом (SUM OVER)
SELECT date_trunc('month', loaned_at)::date AS month, count(*) AS loans_count, sum(count(*)) OVER (ORDER BY date_trunc('month', loaned_at)) AS running_total
FROM loans
GROUP BY date_trunc('month', loaned_at)
ORDER BY month;

-- 15. Помесячная динамика выдач: прошлый месяц и % изменения (LAG)
WITH monthly AS (
    SELECT date_trunc('month', loaned_at)::date AS month, count(*) AS n
    FROM loans
    GROUP BY 1
)
SELECT month,
    n,
    LAG(n) OVER (ORDER BY month) AS prev_n,
       round(100.0 * (n - LAG(n) OVER (ORDER BY month))
        / NULLIF(LAG(n) OVER (ORDER BY month), 0), 1) AS change_pct
FROM monthly
ORDER BY month;

-- 16. Сколько выдач было в каждый из последних 14 дней, включая дни без выдач (WITH RECURSIVE)
WITH RECURSIVE days(d) AS (
    SELECT current_date - 13
    UNION ALL
    SELECT d + 1 FROM days WHERE d < current_date
)
SELECT days.d AS day, count(l.id) AS loans_count
FROM days
LEFT JOIN loans l ON l.loaned_at::date = days.d
GROUP BY days.d
ORDER BY days.d;