-- 1. Карточки невозвращённых выдач через представление lib.v_loan_card
SELECT loan_id, reader, title, inventory_number, due_at, status
FROM lib.v_loan_card
WHERE status <> 'возвращена'
ORDER BY due_at;

-- 2. У кого книги на руках и сколько ещё можно взять (представление lib.v_reader_load)
SELECT * FROM lib.v_reader_load WHERE active_loans > 0 ORDER BY active_loans DESC, reader_id;

-- 3. Функции: свободные экземпляры книги 1 и число книг на руках у читателя 3
SELECT lib.book_free_copies(1) AS free_copies, lib.reader_active_loans(3) AS reader3_on_hand;

-- 4. Бизнес-операция: выдаём читателю 1 экземпляр 11, до и после (issue_book)
BEGIN;
SELECT reader_id, active_loans, slots_left FROM lib.v_reader_load WHERE reader_id = 1;
SELECT lib.issue_book(1, 11) AS new_loan_id;
SELECT reader_id, active_loans, slots_left FROM lib.v_reader_load WHERE reader_id = 1;
ROLLBACK;

-- 5. Бизнес-операция: принимаем просроченную книгу по выдаче 3, считается штраф (return_book)
BEGIN;
SELECT loan_id, status, fine FROM lib.v_loan_card WHERE loan_id = 3;
SELECT lib.return_book(3) AS fine_charged;
SELECT loan_id, status, returned_at, fine FROM lib.v_loan_card WHERE loan_id = 3;
ROLLBACK;

-- 6. Экземпляр 3 уже на руках у другого читателя: ошибка функции
-- expect: error "уже выдан"
SELECT lib.issue_book(2, 3);

-- 7. Шестая книга одному читателю: триггер отклоняет операцию, все шесть выдач откатываются
-- expect: error "книг на руках"
SELECT lib.issue_book(1, c) FROM unnest(ARRAY[11, 12, 13, 14, 15, 1]) AS c;

-- 8. Журнал: изменение штрафа попадает в lib.loans_audit (старое и новое значение, кто)
BEGIN;
UPDATE loans SET fine = 10 WHERE id = 3;
SELECT row_key, op, old_row->>'fine' AS old_fine, new_row->>'fine' AS new_fine, changed_by
FROM lib.loans_audit WHERE row_key = 3 ORDER BY id;
ROLLBACK;

-- 9. Материализованное представление: после выдачи оно устарело, после REFRESH стало верным
BEGIN;
SELECT title, on_hand FROM lib.mv_book_report WHERE book_id = 1;
SELECT lib.issue_book(1, 1) AS new_loan_id;
SELECT title, on_hand AS on_hand_stale FROM lib.mv_book_report WHERE book_id = 1;
REFRESH MATERIALIZED VIEW lib.mv_book_report;
SELECT title, on_hand AS on_hand_fresh FROM lib.mv_book_report WHERE book_id = 1;
ROLLBACK;

-- 10. Поиск выдач читателя 1 (остальные фильтры не переданы)
SELECT * FROM lib.search_loans(p_reader_id => 1);

-- 11. Поиск только невозвращённых выдач по всем читателям
SELECT * FROM lib.search_loans(p_only_active => true);

-- 12. Состояние выдачи 3 на текущий момент по журналу (после двух изменений штрафа)
BEGIN;
UPDATE loans SET fine = 10 WHERE id = 3;
UPDATE loans SET fine = 20 WHERE id = 3;
SELECT lib.loan_state_at(3, clock_timestamp()) ->> 'fine' AS fine_now;
ROLLBACK;

-- 13. Служебный триггер: при изменении выдачи updated_at обновляется сам
BEGIN;
SELECT id, updated_at FROM loans WHERE id = 4;
UPDATE loans SET fine = 5 WHERE id = 4;
SELECT id, updated_at, updated_at >= now() AS updated_now FROM loans WHERE id = 4;
ROLLBACK;