-- Лаба 4 ★★. Row Level Security: читатель видит только свои выдачи.
-- Приложение после входа читателя сообщает базе его номер: SELECT set_config('app.reader_id', '1', false);
-- Если номер не сообщён, политика не пропускает ни одной строки.

-- Роль «читатель в приложении». Входить под ней не нужно, в демо работаем через SET ROLE.
CREATE ROLE app_member NOLOGIN;
GRANT SELECT ON loans TO app_member;

ALTER TABLE loans ENABLE ROW LEVEL SECURITY;

CREATE POLICY loans_own_rows ON loans
    FOR SELECT
    TO app_member
    USING (reader_id = nullif(current_setting('app.reader_id', true), '')::integer);

-- Владелец таблицы и суперпользователь политики не замечают, поэтому лабы 1-3,
-- функции SECURITY DEFINER и представления работают как раньше.