SELECT id, email, first_name, last_name 
FROM users 
WHERE is_active = TRUE;

SELECT id, user_id, workspace_id, status, start_at 
FROM bookings 
ORDER BY created_at DESC 
LIMIT 5;

SELECT id, email, first_name 
FROM users 
WHERE is_active = TRUE AND email LIKE '%@mail.com';

SELECT id, status, total_price 
FROM bookings 
WHERE status IN ('completed', 'confirmed');

SELECT id, email 
FROM users 
WHERE id NOT IN (SELECT user_id FROM bookings);

SELECT id, total_price
FROM bookings
WHERE total_price > (SELECT AVG(total_price) FROM bookings);

SELECT * 
FROM users u
ORDER BY u.last_login_at DESC
LIMIT 10;

SELECT status, COUNT(*) AS count
FROM bookings
GROUP BY status
ORDER BY count DESC;


SELECT method, COUNT(*) AS payments_count, SUM(amount) AS total_sum
FROM payments
WHERE status = 'paid'
GROUP BY method;