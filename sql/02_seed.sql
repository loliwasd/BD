INSERT INTO roles (code, name, description) VALUES
    ('client',  'Клиент',        'Бронирует рабочие места и комнаты'),
    ('manager', 'Менеджер',      'Управляет бронями клиентов и видит отчёты'),
    ('admin',   'Администратор', 'Полный доступ, управление системой');


INSERT INTO users (email, password_hash, first_name, last_name, phone) VALUES
    ('admin@coworking.com',   '$2a$10$hash_admin',   'Александр', 'Админов',    '+375291000001'),
    ('manager1@coworking.com','$2a$10$hash_mgr1',    'Мария',     'Менеджерова','+375291000002'),
    ('manager2@coworking.com','$2a$10$hash_mgr2',    'Дмитрий',   'Управляев',  '+375291000003'),
    ('anna@mail.com',         '$2a$10$hash_anna',    'Анна',      'Иванова',    '+375291000004'),
    ('ivan@mail.com',         '$2a$10$hash_ivan',    'Иван',      'Петров',     '+375291000005'),
    ('petr@mail.com',         '$2a$10$hash_petr',    'Пётр',      'Сидоров',    '+375291000006'),
    ('elena@mail.com',        '$2a$10$hash_elena',   'Елена',     'Козлова',    '+375291000007'),
    ('sergey@mail.com',       '$2a$10$hash_sergey',  'Сергей',    'Морозов',    '+375291000008'),
    ('olga@mail.com',         '$2a$10$hash_olga',    'Ольга',     'Новикова',   '+375291000009'),
    ('michael@mail.com',      '$2a$10$hash_michael', 'Михаил',    'Волков',     '+375291000010');

INSERT INTO user_profiles (user_id, bio, company, timezone) 
SELECT id, 
       'Пользователь коворкинга', 
       CASE 
           WHEN id % 2 = 0 THEN 'ООО "Ромашка"'
           ELSE 'ИП Иванов'
       END,
       'Europe/Minsk'
FROM users 
WHERE email LIKE '%@mail.com';


INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT u.id, r.id, NULL
FROM users u, roles r
WHERE u.email = 'admin@coworking.com' AND r.code = 'admin';

INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT u.id, r.id, (SELECT id FROM users WHERE email = 'admin@coworking.com')
FROM users u, roles r
WHERE u.email IN ('manager1@coworking.com', 'manager2@coworking.com') 
  AND r.code = 'manager';

INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT u.id, r.id, (SELECT id FROM users WHERE email = 'admin@coworking.com')
FROM users u, roles r
WHERE u.email LIKE '%@mail.com' AND r.code = 'client';

INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT u.id, r.id, (SELECT id FROM users WHERE email = 'admin@coworking.com')
FROM users u, roles r
WHERE u.email = 'anna@mail.com' AND r.code = 'manager';


INSERT INTO locations (name, address, city) VALUES
    ('Кампус Минск-Сити',       'ул. Ленина, 1',     'Минск'),
    ('Кампус Гомель-Центр',     'пр. Победы, 10',    'Гомель');

INSERT INTO locations (parent_id, name, address, city) VALUES
    (1, 'Здание А', 'ул. Ленина, 1',  'Минск'),
    (1, 'Здание Б', 'ул. Ленина, 3',  'Минск');

INSERT INTO locations (parent_id, name, address, city) VALUES
    (2, 'Этаж 1', 'пр. Победы, 10', 'Гомель');

INSERT INTO locations (parent_id, name, address, city) VALUES
    (3, 'Этаж 1', 'ул. Ленина, 1', 'Минск'),
    (3, 'Этаж 2', 'ул. Ленина, 1', 'Минск');


INSERT INTO rooms (location_id, name, capacity, has_projector, has_whiteboard) VALUES
    (3, 'Байкал',    10, TRUE,  TRUE),
    (3, 'Селигер',    6, FALSE, TRUE),
    (4, 'Наррочь',    8, TRUE,  FALSE),
    (5, 'Гомельская', 4, FALSE, FALSE);


INSERT INTO workspaces (location_id, room_id, type, parent_id, code, capacity) VALUES
    (3, NULL, 'hot_desk', NULL, 'OS-MINSK', 20);

INSERT INTO workspaces (location_id, room_id, type, parent_id, code, capacity) VALUES
    (3, NULL, 'fixed_desk', NULL, 'FD-MINSK', 10);

INSERT INTO workspaces (location_id, room_id, type, parent_id, code, capacity) VALUES
    (3, 1, 'meeting_room', NULL, 'MR-BAIKAL', 10);

INSERT INTO workspaces (location_id, room_id, type, parent_id, code, capacity) VALUES
    (3, NULL, 'hot_desk', 1, 'OS-MINSK-01', 1),
    (3, NULL, 'hot_desk', 1, 'OS-MINSK-02', 1),
    (3, NULL, 'hot_desk', 1, 'OS-MINSK-03', 1),
    (3, NULL, 'hot_desk', 1, 'OS-MINSK-04', 1),
    (3, NULL, 'hot_desk', 1, 'OS-MINSK-05', 1);

INSERT INTO workspaces (location_id, room_id, type, parent_id, code, capacity) VALUES
    (3, NULL, 'fixed_desk', 2, 'FD-MINSK-01', 1),
    (3, NULL, 'fixed_desk', 2, 'FD-MINSK-02', 1),
    (3, NULL, 'fixed_desk', 2, 'FD-MINSK-03', 1);

INSERT INTO workspaces (location_id, room_id, type, parent_id, code, capacity) VALUES
    (5, NULL, 'hot_desk', NULL, 'OS-GOMEL', 15),
    (5, NULL, 'hot_desk', 12, 'OS-GOMEL-01', 1),
    (5, NULL, 'hot_desk', 12, 'OS-GOMEL-02', 1);


INSERT INTO type_tariffs (type, price_per_hour, currency, valid_from) VALUES
    ('hot_desk',     5.00,  'USD', '2024-01-01'),
    ('fixed_desk',   8.00,  'USD', '2024-01-01'),
    ('meeting_room', 15.00, 'USD', '2024-01-01');


INSERT INTO workspace_tariffs (workspace_id, price_per_hour, currency, valid_from)
SELECT id, 7.00, 'USD', '2024-01-01' FROM workspaces WHERE code = 'OS-MINSK-01';

INSERT INTO workspace_tariffs (workspace_id, price_per_hour, currency, valid_from)
SELECT id, 12.00, 'USD', '2024-01-01' FROM workspaces WHERE code = 'FD-MINSK-01';

INSERT INTO workspace_tariffs (workspace_id, price_per_hour, currency, valid_from)
SELECT id, 20.00, 'USD', '2024-01-01' FROM workspaces WHERE code = 'MR-BAIKAL';



INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price)
SELECT u.id, w.id, 'completed', 
       now() - INTERVAL '7 days', 
       now() - INTERVAL '7 days' + INTERVAL '2 hours', 
       10.00
FROM users u, workspaces w
WHERE u.email = 'anna@mail.com' AND w.code = 'OS-MINSK-01';

INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price)
SELECT u.id, w.id, 'completed', 
       now() - INTERVAL '5 days', 
       now() - INTERVAL '5 days' + INTERVAL '3 hours', 
       24.00
FROM users u, workspaces w
WHERE u.email = 'ivan@mail.com' AND w.code = 'FD-MINSK-01';

INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price)
SELECT u.id, w.id, 'completed', 
       now() - INTERVAL '3 days', 
       now() - INTERVAL '3 days' + INTERVAL '1 hour', 
       15.00
FROM users u, workspaces w
WHERE u.email = 'petr@mail.com' AND w.code = 'MR-BAIKAL';


INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price, cancelled_at, cancel_reason)
SELECT u.id, w.id, 'cancelled', 
       now() - INTERVAL '2 days', 
       now() - INTERVAL '2 days' + INTERVAL '2 hours', 
       14.00,
       now() - INTERVAL '2 days' - INTERVAL '3 hours',
       'Планы изменились'
FROM users u, workspaces w
WHERE u.email = 'elena@mail.com' AND w.code = 'OS-MINSK-01';

INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price)
SELECT u.id, w.id, 'confirmed', 
       now() + INTERVAL '1 day', 
       now() + INTERVAL '1 day' + INTERVAL '4 hours', 
       32.00
FROM users u, workspaces w
WHERE u.email = 'sergey@mail.com' AND w.code = 'FD-MINSK-01';

INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price)
SELECT u.id, w.id, 'pending', 
       now() + INTERVAL '2 days', 
       now() + INTERVAL '2 days' + INTERVAL '2 hours', 
       30.00
FROM users u, workspaces w
WHERE u.email = 'olga@mail.com' AND w.code = 'MR-BAIKAL';

INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price)
SELECT u.id, w.id, 'no_show', 
       now() - INTERVAL '1 day', 
       now() - INTERVAL '1 day' + INTERVAL '2 hours', 
       10.00
FROM users u, workspaces w
WHERE u.email = 'michael@mail.com' AND w.code = 'OS-MINSK-02';

INSERT INTO bookings (user_id, workspace_id, status, start_at, end_at, total_price)
SELECT 
    u.id, 
    w.id, 
    'completed',
    x.start_at,
    x.start_at + INTERVAL '2 hours',
    (w.capacity * 5.0)::numeric(10,2)
FROM users u, workspaces w
CROSS JOIN LATERAL (
    SELECT now() - (random() * 30 || ' days')::interval AS start_at
) AS x
WHERE u.email = 'anna@mail.com' 
  AND w.code IN ('OS-MINSK-03', 'OS-MINSK-04', 'FD-MINSK-02', 'OS-GOMEL-01');



INSERT INTO payments (booking_id, method, amount, status, paid_at)
SELECT id, 'card', total_price, 'paid', created_at + INTERVAL '5 minutes'
FROM bookings WHERE status = 'completed';

INSERT INTO payments (booking_id, method, amount, status, paid_at)
SELECT id, 'transfer', total_price, 'paid', created_at + INTERVAL '10 minutes'
FROM bookings WHERE status = 'confirmed';

INSERT INTO payments (booking_id, method, amount, status)
SELECT id, 'cash', total_price, 'pending'
FROM bookings WHERE status = 'pending';

INSERT INTO payments (booking_id, method, amount, status, paid_at, refunded_at)
SELECT id, 'card', total_price, 'refunded', 
       created_at + INTERVAL '5 minutes',
       cancelled_at
FROM bookings WHERE status = 'cancelled';

INSERT INTO payments (booking_id, method, amount, status, paid_at)
SELECT id, 'card', total_price, 'paid', created_at + INTERVAL '5 minutes'
FROM bookings WHERE status = 'no_show';


INSERT INTO reviews (booking_id, user_id, rating, comment)
SELECT b.id, b.user_id, 5, 'Отличное место, всё чисто и удобно!'
FROM bookings b
WHERE b.status = 'completed' 
  AND b.user_id = (SELECT id FROM users WHERE email = 'anna@mail.com')
LIMIT 1;

INSERT INTO reviews (booking_id, user_id, rating, comment)
SELECT b.id, b.user_id, 4, 'Хорошо, но немного шумно'
FROM bookings b
WHERE b.status = 'completed' 
  AND b.user_id = (SELECT id FROM users WHERE email = 'ivan@mail.com')
LIMIT 1;

INSERT INTO reviews (booking_id, user_id, rating, comment)
SELECT b.id, b.user_id, 5, 'Переговорка супер, проектор работает'
FROM bookings b
WHERE b.status = 'completed' 
  AND b.user_id = (SELECT id FROM users WHERE email = 'petr@mail.com')
LIMIT 1;


INSERT INTO audit_log (user_id, action, entity_type, entity_id, result, ip)
SELECT id, 'login', 'users', id, 'success', '192.168.1.10'
FROM users WHERE email = 'anna@mail.com';

INSERT INTO audit_log (user_id, action, entity_type, entity_id, result, ip)
SELECT id, 'login', 'users', id, 'success', '192.168.1.20'
FROM users WHERE email = 'ivan@mail.com';

INSERT INTO audit_log (user_id, action, entity_type, entity_id, old_value, new_value, result, ip)
SELECT u.id, 'create_booking', 'bookings', b.id, NULL, 
       jsonb_build_object('status', b.status, 'workspace_id', b.workspace_id),
       'success', '192.168.1.30'
FROM users u, bookings b
WHERE u.email = 'anna@mail.com' AND b.user_id = u.id
LIMIT 1;

INSERT INTO audit_log (user_id, action, entity_type, entity_id, result, ip)
SELECT id, 'logout', 'users', id, 'success', '192.168.1.10'
FROM users WHERE email = 'anna@mail.com';







