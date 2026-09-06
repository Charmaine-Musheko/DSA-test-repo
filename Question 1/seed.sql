BEGIN;


-- ============================================================================
-- INSTITUTIONS
-- ============================================================================

INSERT INTO institutions(name)
VALUES
    ('Namibia University of Science and Technology'),
    ('University of Namibia')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SITES
-- ============================================================================

INSERT INTO institution_sites(institution_name, site)
VALUES
    (
        'Namibia University of Science and Technology',
        'Main Campus - Innovation Lab'
    ),
    (
        'Namibia University of Science and Technology',
        'Main Campus - Library'
    ),
    (
        'Namibia University of Science and Technology',
        'Faculty of Computing'
    ),
    (
        'University of Namibia',
        'Main Campus - Computer Lab 2'
    ),
    (
        'University of Namibia',
        'Khomasdal Campus'
    )
ON CONFLICT DO NOTHING;


-- ============================================================================
-- ASSETS
-- ============================================================================

INSERT INTO assets (
    asset_tag,
    name,
    description,
    institution_name,
    site,
    status,
    date_acquired
)
VALUES
(
    'NUST-LIB-3DP-001',
    'Pro-Series 3D Printer',
    'High-precision laboratory printer for simulation and prototype development.',
    'Namibia University of Science and Technology',
    'Main Campus - Innovation Lab',
    'AVAILABLE',
    '2024-03-10'
),
(
    'NUST-LIB-BK-045',
    'Introduction to Distributed Systems',
    'Core textbook, 4th edition.',
    'Namibia University of Science and Technology',
    'Main Campus - Library',
    'AVAILABLE',
    '2023-01-15'
),
(
    'UNAM-LAB-LP-012',
    'Dell Latitude 5440',
    'Loan laptop for postgraduate research.',
    'University of Namibia',
    'Main Campus - Computer Lab 2',
    'LOANED_OUT',
    '2025-02-20'
),
(
    'NUST-FAC-MR-007',
    'Faculty of Computing Meeting Room',
    '8-seat meeting room with projector.',
    'Namibia University of Science and Technology',
    'Faculty of Computing',
    'AVAILABLE',
    '2022-11-01'
),
(
    'UNAM-LAB-PC-030',
    'HP EliteDesk Thin Client',
    'Thin client, computer lab row 3.',
    'University of Namibia',
    'Main Campus - Computer Lab 2',
    'UNDER_MAINTENANCE',
    '2021-06-12'
)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- COMPONENTS
-- ============================================================================

INSERT INTO components (
    asset_tag,
    comp_id,
    name,
    description
)
VALUES
(
    'NUST-LIB-3DP-001',
    'C101',
    'High-Torque Stepper Motor',
    'Main motor for X-axis movement.'
)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- SCHEDULES
-- ============================================================================

INSERT INTO schedules (
    asset_tag,
    schedule_id,
    schedule_type,
    due_date,
    description,
    status
)
VALUES
(
    'NUST-LIB-3DP-001',
    'SCH-882',
    'MAINTENANCE',
    '2026-09-01',
    'Quarterly calibration and nozzle cleaning.',
    'PENDING'
),
(
    'UNAM-LAB-LP-012',
    'LN-001',
    'LOAN',
    '2026-08-05',
    'Loaned to J. Amutenya',
    'PENDING'
),
(
    'UNAM-LAB-PC-030',
    'SCH-100',
    'MAINTENANCE',
    '2026-06-01',
    'Replace failing power supply.',
    'PENDING'
)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- WORK ORDERS
-- ============================================================================

INSERT INTO work_orders (
    asset_tag,
    order_id,
    status,
    description
)
VALUES
(
    'NUST-LIB-3DP-001',
    'WO-554',
    'OPEN',
    'Nozzle heat-bed failure'
),
(
    'UNAM-LAB-PC-030',
    'WO-200',
    'OPEN',
    'Does not power on reliably'
)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- TASKS
-- ============================================================================

INSERT INTO work_tasks (
    asset_tag,
    order_id,
    task_id,
    description,
    completed
)
VALUES
(
    'NUST-LIB-3DP-001',
    'WO-554',
    'T1',
    'Check thermal sensor connectivity.',
    FALSE
),
(
    'UNAM-LAB-PC-030',
    'WO-200',
    'T1',
    'Test PSU voltage output.',
    FALSE
)
ON CONFLICT DO NOTHING;


COMMIT;

