-- Лаба 4. Исправление гонки.
-- Триггер из лабы 3 считает книги на руках, но не видит незафиксированную вставку
-- другой сессии. Поэтому выдачу делаем под блокировкой общей строки: читателя.
-- Функция заменяется целиком (CREATE OR REPLACE), скрипты лаб 1-3 не меняются.

CREATE OR REPLACE FUNCTION lib.issue_book(p_reader_id integer, p_copy_id integer, p_days integer DEFAULT 14)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_id integer;
BEGIN
    IF p_days <= 0 THEN
        RAISE EXCEPTION 'Срок выдачи должен быть положительным: % дн.', p_days;
    END IF;

    -- Блокируем строку читателя до конца транзакции: вторая выдача этому же читателю
    -- будет ждать здесь, а потом триггер увидит уже зафиксированную первую.
    PERFORM 1 FROM readers WHERE id = p_reader_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Читатель % не найден', p_reader_id;
    END IF;

    -- Блокируем экземпляр: одну книгу не выдадут двум читателям сразу.
    -- Порядок блокировок всегда один (читатель, потом экземпляр), чтобы не было взаимоблокировки.
    PERFORM 1 FROM copies WHERE id = p_copy_id FOR UPDATE;
    IF EXISTS (SELECT 1 FROM loans WHERE copy_id = p_copy_id AND returned_at IS NULL) THEN
        RAISE EXCEPTION 'Экземпляр % уже выдан', p_copy_id;
    END IF;

    INSERT INTO loans (copy_id, reader_id, due_at)
    VALUES (p_copy_id, p_reader_id, now() + make_interval(days => p_days))
    RETURNING id INTO v_id;

    RETURN v_id;
END $$;

-- Возврат тоже работает от имени владельца, чтобы его мог вызвать app_writer.
ALTER FUNCTION lib.return_book(integer) SECURITY DEFINER SET search_path = public, pg_temp;