# Список таблиц БД и их описание

## Список таблиц

| № | Сущность          | Назначение                                              |
|---|-------------------|---------------------------------------------------------|
| 1 | users             | Пользователи системы                                    |
| 2 | user_profiles     | Дополнительные данные профиля (1:1 с users)             |
| 3 | roles             | Роли (client, manager, admin)                           |
| 4 | permissions       | Права доступа                                           |
| 5 | role_permissions  | M:N связь ролей и прав                                  |
| 6 | user_roles        | M:N связь пользователей и ролей                         |
| 7 | audit_log         | Журнал действий пользователей                           |
| 8 | locations         | Локации коворкинга                                      |
| 9 | rooms             | Переговорные комнаты                                    |
|10 | workspace_types   | Типы рабочих мест                                       |
|11 | workspaces        | Конкретные бронируемые рабочие места/комнаты            |
|12 | tariffs           | Тарифы (цена за час)                                    |
|13 | booking_statuses  | Справочник статусов брони                               |
|14 | bookings          | Брони клиентов                                          |
|15 | payment_methods   | Справочник способов оплаты                              |
|16 | payments          | Платежи по броням                                       |
|17 | reviews           | Отзывы клиентов                                         |

---

## 1. users

**Назначение:** учётные записи всех пользователей системы.

| Поле          | Тип         | Ограничения                                       |
|---------------|-------------|---------------------------------------------------|
| id            | BIGSERIAL   | PK                                                |
| email         | CITEXT      | NOT NULL, UNIQUE                                  |
| password_hash | TEXT        | NOT NULL                                          |
| first_name    | TEXT        | NOT NULL                                          |
| last_name     | TEXT        | NOT NULL                                          |
| phone         | TEXT        | NULL, CHECK (phone ~ '^\+?[0-9]{7,15}$')          |
| is_active     | BOOLEAN     | NOT NULL DEFAULT TRUE                             |
| last_login_at | TIMESTAMPTZ | NULL                                              |
| created_at    | TIMESTAMPTZ | NOT NULL DEFAULT now()                            |
| updated_at    | TIMESTAMPTZ | NOT NULL DEFAULT now()                            |
| deleted_at    | TIMESTAMPTZ | NULL                                              |

**Связи:** M:N с `roles` через `user_roles`; 1:1 с `user_profiles`; 1:N с `bookings`, `reviews`, `audit_log`.

---

## 2. user_profiles

**Назначение:** дополнительные данные профиля.

| Поле       | Тип         | Ограничения                                   |
|------------|-------------|-----------------------------------------------|
| user_id    | BIGINT      | PK, FK → users(id) ON DELETE CASCADE          |
| avatar_url | TEXT        | NULL                                          |
| bio        | TEXT        | NULL, CHECK (char_length(bio) <= 500)         |
| company    | TEXT        | NULL                                          |
| timezone   | TEXT        | NOT NULL DEFAULT 'UTC'                        |

**Связи:** 1:1 с `users` (PK = FK).

---

## 3. roles

**Назначение:** справочник ролей RBAC.

| Поле        | Тип         | Ограничения                          |
|-------------|-------------|--------------------------------------|
| id          | SMALLSERIAL | PK                                   |
| code        | TEXT        | NOT NULL, UNIQUE                     |
| name        | TEXT        | NOT NULL                             |
| description | TEXT        | NULL                                 |

**Связи:** M:N с `users` через `user_roles`; M:N с `permissions` через `role_permissions`.

---

## 4. permissions

**Назначение:** атомарные права доступа.

| Поле        | Тип         | Ограничения           |
|-------------|-------------|-----------------------|
| id          | SMALLSERIAL | PK                    |
| code        | TEXT        | NOT NULL, UNIQUE      |
| description | TEXT        | NULL                  |

**Связи:** M:N с `roles` через `role_permissions`.

---

## 5. role_permissions

**Назначение:** M:N между ролями и правами.

| Поле          | Тип         | Ограничения                                   |
|---------------|-------------|-----------------------------------------------|
| role_id       | SMALLINT    | NOT NULL, FK → roles(id) ON DELETE CASCADE    |
| permission_id | SMALLINT    | NOT NULL, FK → permissions(id) ON DELETE CASCADE |
| granted_at    | TIMESTAMPTZ | NOT NULL DEFAULT now()                        |
|               |             | PRIMARY KEY (role_id, permission_id)          |

**Связи:** N:1 `roles`, N:1 `permissions`.

---

## 6. user_roles

**Назначение:** M:N между пользователями и ролями, с аудитом выдачи.

| Поле       | Тип         | Ограничения                                   |
|------------|-------------|-----------------------------------------------|
| user_id    | BIGINT      | NOT NULL, FK → users(id) ON DELETE CASCADE    |
| role_id    | SMALLINT    | NOT NULL, FK → roles(id) ON DELETE RESTRICT   |
| granted_by | BIGINT      | NULL, FK → users(id) ON DELETE SET NULL       |
| granted_at | TIMESTAMPTZ | NOT NULL DEFAULT now()                        |
|            |             | PRIMARY KEY (user_id, role_id)                |

**Связи:** N:1 `users`, N:1 `roles`, self-ref через `granted_by`.

---

## 7. audit_log

**Назначение:** журнал действий пользователей.

| Поле        | Тип         | Ограничения                                       |
|-------------|-------------|---------------------------------------------------|
| id          | BIGSERIAL   | PK                                                |
| user_id     | BIGINT      | NULL, FK → users(id) ON DELETE SET NULL           |
| action      | TEXT        | NOT NULL                                          |
| entity_type | TEXT        | NULL                                              |
| entity_id   | BIGINT      | NULL                                              |
| old_value   | JSONB       | NULL                                              |
| new_value   | JSONB       | NULL                                              |
| ip          | INET        | NULL                                              |
| result      | TEXT        | NOT NULL DEFAULT 'success'                        |
| created_at  | TIMESTAMPTZ | NOT NULL DEFAULT now()                            |

**Связи:** N:1 `users`.

---

## 8. locations

**Назначение:** физические локации коворкинга.

| Поле      | Тип         | Ограничения                                    |
|-----------|-------------|------------------------------------------------|
| id        | BIGSERIAL   | PK                                             |
| parent_id | BIGINT      | NULL, FK → locations(id) ON DELETE SET NULL    |
| name      | TEXT        | NOT NULL                                       |
| address   | TEXT        | NOT NULL                                       |
| city      | TEXT        | NOT NULL                                       |
| is_active | BOOLEAN     | NOT NULL DEFAULT TRUE                          |

**Связи:** self-ref `parent_id`; 1:N `rooms`, `workspaces`.

---

## 9. rooms

**Назначение:** переговорные комнаты внутри локации.

| Поле          | Тип         | Ограничения                                    |
|---------------|-------------|------------------------------------------------|
| id            | BIGSERIAL   | PK                                             |
| location_id   | BIGINT      | NOT NULL, FK → locations(id) ON DELETE CASCADE |
| name          | TEXT        | NOT NULL                                       |
| capacity      | SMALLINT    | NOT NULL, CHECK (capacity > 0)                 |
| has_projector | BOOLEAN     | NOT NULL DEFAULT FALSE                         |
| has_whiteboard| BOOLEAN     | NOT NULL DEFAULT FALSE                         |
| is_active     | BOOLEAN     | NOT NULL DEFAULT TRUE                          |
|               |             | UNIQUE (location_id, name)                     |

**Связи:** N:1 `locations`; 1:N `workspaces`.

---

## 10. workspace_types

**Назначение:** справочник типов рабочих мест.

| Поле        | Тип         | Ограничения           |
|-------------|-------------|-----------------------|
| id          | SMALLSERIAL | PK                    |
| code        | TEXT        | NOT NULL, UNIQUE      |
| name        | TEXT        | NOT NULL              |
| description | TEXT        | NULL                  |

**Связи:** 1:N `workspaces`, `tariffs`.

---

## 11. workspaces

**Назначение:** конкретные бронируемые рабочие места/комнаты.

| Поле        | Тип         | Ограничения                                       |
|-------------|-------------|---------------------------------------------------|
| id          | BIGSERIAL   | PK                                                |
| location_id | BIGINT      | NOT NULL, FK → locations(id) ON DELETE CASCADE    |
| room_id     | BIGINT      | NULL, FK → rooms(id) ON DELETE SET NULL           |
| type_id     | SMALLINT    | NOT NULL, FK → workspace_types(id) ON DELETE RESTRICT |
| parent_id   | BIGINT      | NULL, FK → workspaces(id) ON DELETE SET NULL      |
| code        | TEXT        | NOT NULL, UNIQUE                                  |
| capacity    | SMALLINT    | NOT NULL DEFAULT 1, CHECK (capacity > 0)          |
| is_active   | BOOLEAN     | NOT NULL DEFAULT TRUE                             |

**Связи:** N:1 `locations`, `rooms`, `workspace_types`; self-ref `parent_id`; 1:N `bookings`, `tariffs`.

---

## 12. tariffs

**Назначение:** тарифы (цена за час) для типа ресурса или конкретного ресурса.

| Поле           | Тип           | Ограничения                                       |
|----------------|---------------|---------------------------------------------------|
| id             | BIGSERIAL     | PK                                                |
| type_id        | SMALLINT      | NULL, FK → workspace_types(id) ON DELETE CASCADE  |
| workspace_id   | BIGINT        | NULL, FK → workspaces(id) ON DELETE CASCADE       |
| price_per_hour | NUMERIC(10,2) | NOT NULL, CHECK (price_per_hour >= 0)             |
| currency       | CHAR(3)       | NOT NULL DEFAULT 'USD'                            |
| valid_from     | DATE          | NOT NULL DEFAULT CURRENT_DATE                     |
| valid_to       | DATE          | NULL                                              |
|                |               | CHECK (type_id IS NOT NULL OR workspace_id IS NOT NULL) |

**Связи:** N:1 `workspace_types` ИЛИ N:1 `workspaces`.

---

## 13. booking_statuses

**Назначение:** справочник статусов брони.

| Поле | Тип         | Ограничения           |
|------|-------------|-----------------------|
| id   | SMALLSERIAL | PK                    |
| code | TEXT        | NOT NULL, UNIQUE      |
| name | TEXT        | NOT NULL              |

Значения: `pending`, `confirmed`, `cancelled`, `completed`, `no_show`.

**Связи:** 1:N `bookings`.

---

## 14. bookings

**Назначение:** брони клиентов.

| Поле          | Тип           | Ограничения                                       |
|---------------|---------------|---------------------------------------------------|
| id            | BIGSERIAL     | PK                                                |
| user_id       | BIGINT        | NOT NULL, FK → users(id) ON DELETE RESTRICT       |
| workspace_id  | BIGINT        | NOT NULL, FK → workspaces(id) ON DELETE RESTRICT  |
| status_id     | SMALLINT      | NOT NULL, FK → booking_statuses(id) ON DELETE RESTRICT |
| start_at      | TIMESTAMPTZ   | NOT NULL                                          |
| end_at        | TIMESTAMPTZ   | NOT NULL, CHECK (end_at > start_at)               |
| total_price   | NUMERIC(10,2) | NOT NULL, CHECK (total_price >= 0)                |
| cancelled_at  | TIMESTAMPTZ   | NULL                                              |
| cancel_reason | TEXT          | NULL                                              |
| created_at    | TIMESTAMPTZ   | NOT NULL DEFAULT now()                            |
| updated_at    | TIMESTAMPTZ   | NOT NULL DEFAULT now()                            |
|               |               | CHECK (end_at - start_at <= INTERVAL '8 hours')   |

**Связи:** N:1 `users`, `workspaces`, `booking_statuses`; 1:1 `payments`, `reviews`.

---

## 15. payment_methods

**Назначение:** справочник способов оплаты.

| Поле | Тип         | Ограничения           |
|------|-------------|-----------------------|
| id   | SMALLSERIAL | PK                    |
| code | TEXT        | NOT NULL, UNIQUE      |
| name | TEXT        | NOT NULL              |

Значения: `card`, `cash`, `transfer`.

**Связи:** 1:N `payments`.

---

## 16. payments

**Назначение:** платежи по броням (1:1 с бронью).

| Поле        | Тип           | Ограничения                                       |
|-------------|---------------|---------------------------------------------------|
| id          | BIGSERIAL     | PK                                                |
| booking_id  | BIGINT        | NOT NULL, UNIQUE, FK → bookings(id) ON DELETE CASCADE |
| method_id   | SMALLINT      | NOT NULL, FK → payment_methods(id) ON DELETE RESTRICT |
| amount      | NUMERIC(10,2) | NOT NULL, CHECK (amount >= 0)                     |
| status      | TEXT          | NOT NULL, CHECK (status IN ('pending','paid','refunded','failed')) |
| paid_at     | TIMESTAMPTZ   | NULL                                              |
| refunded_at | TIMESTAMPTZ   | NULL                                              |
| created_at  | TIMESTAMPTZ   | NOT NULL DEFAULT now()                            |

**Связи:** 1:1 `bookings` (UNIQUE FK); N:1 `payment_methods`.

---

## 17. reviews

**Назначение:** отзывы клиентов по завершённым броням.

| Поле       | Тип         | Ограничения                                       |
|------------|-------------|---------------------------------------------------|
| id         | BIGSERIAL   | PK                                                |
| booking_id | BIGINT      | NOT NULL, UNIQUE, FK → bookings(id) ON DELETE CASCADE |
| user_id    | BIGINT      | NOT NULL, FK → users(id) ON DELETE CASCADE        |
| rating     | SMALLINT    | NOT NULL, CHECK (rating BETWEEN 1 AND 5)          |
| comment    | TEXT        | NULL, CHECK (char_length(comment) <= 1000)        |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now()                            |

**Связи:** 1:1 `bookings` (UNIQUE FK); N:1 `users`.

---

## Сводка связей (покрытие требований ЛР1)

| Вид связи        | Где реализована                                  |
|------------------|--------------------------------------------------|
| 1:1              | users ↔ user_profiles                            |
| 1:1              | bookings ↔ payments                              |
| 1:1              | bookings ↔ reviews                               |
| 1:N              | locations → rooms, locations → workspaces        |
| 1:N              | users → bookings, reviews, audit_log             |
| 1:N              | bookings → booking_statuses                      |
| M:N              | users ↔ roles (через user_roles)                 |
| M:N              | roles ↔ permissions (через role_permissions)     |
| self-referencing | locations.parent_id → locations.id               |
| self-referencing | workspaces.parent_id → workspaces.id             |