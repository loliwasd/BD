--select

SELECT * FROM users;

SELECT id, email, first_name, last_name 
FROM users 
WHERE is_active = TRUE;

SELECT id, last_name, first_name, email 
FROM users 
ORDER BY last_name, first_name;

SELECT id, user_id, workspace_id, status, start_at 
FROM bookings 
ORDER BY created_at DESC 
LIMIT 5;

SELECT * FROM bookings WHERE status = 'confirmed';

SELECT id, start_at, end_at, total_price 
FROM bookings 
WHERE start_at BETWEEN now() - INTERVAL '7 days' AND now() + INTERVAL '7 days';


--conditions

SELECT id, email, first_name 
FROM users 
WHERE is_active = TRUE AND email LIKE '%@mail.com';

SELECT id, status, total_price 
FROM bookings 
WHERE status IN ('completed', 'confirmed');

SELECT id, first_name, last_name 
FROM users 
WHERE first_name LIKE 'А%' OR first_name LIKE 'И%';

SELECT id, created_at, total_price 
FROM bookings 
WHERE created_at > now() - INTERVAL '3 days' AND total_price > 20;


--join

SELECT 
    b.id AS booking_id,
    u.first_name || ' ' || u.last_name AS client_name,
    w.code AS workspace_code,
    b.status,
    b.start_at,
    b.end_at,
    b.total_price
FROM bookings b
JOIN users u ON u.id = b.user_id
JOIN workspaces w ON w.id = b.workspace_id
ORDER BY b.created_at DESC;

SELECT 
    u.id,
    u.first_name || ' ' || u.last_name AS name,
    u.email,
    COUNT(b.id) AS bookings_count
FROM users u
LEFT JOIN bookings b ON b.user_id = u.id
GROUP BY u.id, u.first_name, u.last_name, u.email
ORDER BY bookings_count DESC;

SELECT 
    p.id AS payment_id,
    p.amount,
    p.method,
    p.status AS payment_status,
    b.id AS booking_id,
    u.email AS client_email
FROM payments p
JOIN bookings b ON b.id = p.booking_id
JOIN users u ON u.id = b.user_id
WHERE p.status = 'paid';

SELECT 
    child.id,
    child.name AS location_name,
    parent.name AS parent_name
FROM locations child
LEFT JOIN locations parent ON parent.id = child.parent_id
ORDER BY child.id;


--group by

SELECT status, COUNT(*) AS count
FROM bookings
GROUP BY status
ORDER BY count DESC;

SELECT 
    method, 
    COUNT(*) AS payments_count,
    SUM(amount) AS total_sum,
    AVG(amount) AS avg_amount
FROM payments
WHERE status = 'paid'
GROUP BY method;

SELECT 
    COUNT(*) AS reviews_count,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    ROUND(AVG(rating), 2) AS avg_rating
FROM reviews;

SELECT 
    w.code AS workspace_code,
    w.type,
    COUNT(b.id) AS bookings_count
FROM workspaces w
LEFT JOIN bookings b ON b.workspace_id = w.id
GROUP BY w.id, w.code, w.type
ORDER BY bookings_count DESC;

SELECT 
    l.name AS location,
    COUNT(b.id) AS bookings_count,
    SUM(b.total_price) AS total_revenue
FROM locations l
JOIN workspaces w ON w.location_id = l.id
JOIN bookings b ON b.workspace_id = w.id
WHERE b.status IN ('completed', 'confirmed')
GROUP BY l.id, l.name
ORDER BY total_revenue DESC;

--having

SELECT 
    u.id,
    u.first_name || ' ' || u.last_name AS name,
    COUNT(b.id) AS bookings_count
FROM users u
JOIN bookings b ON b.user_id = u.id
GROUP BY u.id, u.first_name, u.last_name
HAVING COUNT(b.id) > 1;

SELECT status, COUNT(*) AS count
FROM bookings
GROUP BY status
HAVING COUNT(*) > 1;

SELECT 
    l.name,
    SUM(b.total_price) AS revenue
FROM locations l
JOIN workspaces w ON w.location_id = l.id
JOIN bookings b ON b.workspace_id = w.id
WHERE b.status = 'completed'
GROUP BY l.id, l.name
HAVING SUM(b.total_price) > 30;


--subqueries

SELECT id, email, first_name 
FROM users 
WHERE id NOT IN (SELECT user_id FROM bookings);

SELECT u.id, u.email, u.first_name
FROM users u
WHERE EXISTS (
    SELECT 1 FROM bookings b WHERE b.user_id = u.id
);

SELECT u.id, u.email
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM reviews r WHERE r.user_id = u.id
);

SELECT id, total_price
FROM bookings
WHERE total_price > (SELECT AVG(total_price) FROM bookings);

SELECT * FROM payments 
WHERE amount = (SELECT MAX(amount) FROM payments);


--case

SELECT 
    id,
    status,
    CASE status
        WHEN 'pending' THEN 'Ожидает подтверждения'
        WHEN 'confirmed' THEN 'Подтверждена'
        WHEN 'cancelled' THEN 'Отменена'
        WHEN 'completed' THEN 'Завершена'
        WHEN 'no_show' THEN 'Клиент не пришёл'
        ELSE 'Неизвестно'
    END AS status_description
FROM bookings
ORDER BY id;

SELECT 
    id,
    total_price,
    CASE 
        WHEN total_price < 15 THEN 'Дешёвая'
        WHEN total_price BETWEEN 15 AND 30 THEN 'Средняя'
        ELSE 'Дорогая'
    END AS price_category
FROM bookings;

SELECT 
    u.id,
    u.first_name || ' ' || u.last_name AS name,
    COUNT(b.id) AS bookings_count,
    CASE 
        WHEN COUNT(b.id) = 0 THEN 'Нет броней'
        WHEN COUNT(b.id) <= 2 THEN 'Мало броней'
        ELSE 'Активный клиент'
    END AS activity_level
FROM users u
LEFT JOIN bookings b ON b.user_id = u.id
GROUP BY u.id, u.first_name, u.last_name
ORDER BY bookings_count DESC;


--data manipulation

INSERT INTO users (email, password_hash, first_name, last_name, phone)
VALUES ('test_user@mail.com', '$2a$10$hash_test', 'Тест', 'Тестов', '+375299999999')
RETURNING id, email;

UPDATE users 
SET is_active = FALSE 
WHERE email = 'test_user@mail.com'
RETURNING id, email, is_active;

UPDATE bookings 
SET status = 'confirmed', updated_at = now()
WHERE id = 1
RETURNING id, status, updated_at;

DELETE FROM users 
WHERE email = 'test_user@mail.com'
RETURNING id, email;

DELETE FROM audit_log 
WHERE created_at < now() - INTERVAL '1 year';


--explain

EXPLAIN SELECT * FROM bookings WHERE status = 'confirmed';

EXPLAIN SELECT * FROM bookings WHERE user_id = 4;

EXPLAIN 
SELECT b.id, u.email, w.code
FROM bookings b
JOIN users u ON u.id = b.user_id
JOIN workspaces w ON w.id = b.workspace_id
WHERE b.status = 'completed';

EXPLAIN ANALYZE SELECT * FROM bookings WHERE user_id = 4;


--additional agregates


SELECT 
    (SELECT COUNT(*) FROM users) AS users_count,
    (SELECT COUNT(*) FROM bookings) AS bookings_count,
    (SELECT COUNT(*) FROM payments WHERE status = 'paid') AS paid_payments,
    (SELECT COUNT(*) FROM reviews) AS reviews_count,
    (SELECT SUM(amount) FROM payments WHERE status = 'paid') AS total_revenue;

SELECT 
    TO_CHAR(start_at, 'Day') AS day_of_week,
    COUNT(*) AS bookings_count
FROM bookings
GROUP BY TO_CHAR(start_at, 'Day')
ORDER BY bookings_count DESC;

SELECT 
    u.email,
    STRING_AGG(r.code, ', ') AS roles
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
GROUP BY u.id, u.email
ORDER BY u.email;