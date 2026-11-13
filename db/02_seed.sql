
INSERT INTO authors (full_name, birth_year) VALUES
('Лев Толстой', 1828), ('Фёдор Достоевский', 1821), ('Антон Чехов', 1860),
('Михаил Булгаков', 1891), ('Аркадий Стругацкий', 1925), ('Борис Стругацкий', 1933),
('Александр Пушкин', 1799), ('Николай Гоголь', 1809), ('Михаил Лермонтов', 1814),
('Иван Тургенев', 1818);

INSERT INTO books (title, published_year, pages, isbn) VALUES
('Война и мир', 2018, 1300, '978-5-0000-0001-1'),
('Преступление и наказание', 2019, 600, '978-5-0000-0002-8'),
('Вишнёвый сад', 2015, 120, '978-5-0000-0003-5'),
('Мастер и Маргарита', 2020, 480, '978-5-0000-0004-2'),
('Пикник на обочине', 2017, 224, '978-5-0000-0005-9'),
('Трудно быть богом', 2016, 256, '978-5-0000-0006-6'),
('Евгений Онегин', 2014, 240, '978-5-0000-0007-3'),
('Мёртвые души', 2013, 400, '978-5-0000-0008-0'),
('Герой нашего времени', 2012, 220, '978-5-0000-0009-7'),
('Отцы и дети', 2011, 300, '978-5-0000-0010-3');

INSERT INTO book_authors (book_id, author_id) VALUES
(1,1), (2,2), (3,3), (4,4), (5,5), (5,6), (6,5), (6,6),
(7,7), (8,8), (9,9), (10,10);

INSERT INTO copies (book_id, inventory_number, condition) VALUES
(1,'INV-001','good'), (2,'INV-002','good'), (3,'INV-003','worn'),
(4,'INV-004','good'), (5,'INV-005','good'), (6,'INV-006','good'),
(7,'INV-007','worn'), (8,'INV-008','good'), (9,'INV-009','good'),
(10,'INV-010','damaged'),
(1,'INV-011','good'), (2,'INV-012','good'), (3,'INV-013','good'),
(4,'INV-014','worn'), (5,'INV-015','good');

INSERT INTO readers (full_name, email) VALUES
('Иван Петров', 'ivan@example.com'), ('Мария Сидорова', 'maria@example.com'),
('Олег Смирнов', 'oleg@example.com'), ('Анна Кузнецова', 'anna@example.com'),
('Дмитрий Попов', 'dmitry@example.com'), ('Елена Волкова', 'elena@example.com'),
('Сергей Морозов', 'sergey@example.com'), ('Ольга Новикова', 'olga@example.com'),
('Павел Фёдоров', 'pavel@example.com'), ('Наталья Лебедева', 'natalia@example.com');

INSERT INTO loans (copy_id, reader_id, loaned_at, due_at, returned_at, fine) VALUES
(1, 1,  now() - interval '30 days', now() - interval '16 days', now() - interval '20 days', 0),
(2, 2,  now() - interval '25 days', now() - interval '11 days', now() - interval '12 days', 0),
(3, 3,  now() - interval '20 days', now() - interval '6 days',  NULL, 30.00),
(4, 4,  now() - interval '10 days', now() + interval '4 days',  NULL, 0),
(5, 5,  now() - interval '9 days',  now() + interval '5 days',  NULL, 0),
(6, 6,  now() - interval '8 days',  now() + interval '6 days',  NULL, 0),
(7, 7,  now() - interval '40 days', now() - interval '26 days', now() - interval '25 days', 0),
(8, 8,  now() - interval '3 days',  now() + interval '11 days', NULL, 0),
(9, 9,  now() - interval '2 days',  now() + interval '12 days', NULL, 0),
(10, 10, now() - interval '1 day',  now() + interval '13 days', NULL, 0);