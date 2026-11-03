-- EXPLAIN comparison for queries 3, 5, and 7 in queries.sql.
-- Run this file once against a database loaded with schema.sql.
-- Capture the first three plans before adding indexes, then compare with the last three.
-- `rows` is an optimizer estimate, not the actual number of rows returned.

-- BEFORE INDEXES: Query 3 (class average and RANK position).
EXPLAIN
WITH student_averages AS (
    SELECT
        e.enrollment_id,
        e.admission_number,
        e.class_id,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM enrollment e
    JOIN term t ON t.term_id = e.term_id
    JOIN result r ON r.enrollment_id = e.enrollment_id
    WHERE t.label = '2026/2027 First Term'
    GROUP BY e.enrollment_id, e.admission_number, e.class_id
)
SELECT
    c.class_name,
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    ROUND(sa.average_score, 2) AS average_score,
    RANK() OVER (PARTITION BY sa.class_id ORDER BY sa.average_score DESC) AS class_position
FROM student_averages sa
JOIN student s ON s.admission_number = sa.admission_number
JOIN school_class c ON c.class_id = sa.class_id
ORDER BY c.class_name, class_position, s.last_name, s.first_name;

-- BEFORE INDEXES: Query 5 (students failing at least two subjects).
EXPLAIN
SELECT
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    COUNT(*) AS failed_subject_count
FROM result r
JOIN enrollment e ON e.enrollment_id = r.enrollment_id
JOIN student s ON s.admission_number = e.admission_number
JOIN school_class c ON c.class_id = e.class_id
JOIN term t ON t.term_id = e.term_id
WHERE t.label = '2026/2027 First Term'
  AND r.ca_score + r.exam_score < 40
GROUP BY s.admission_number, s.first_name, s.middle_name, s.last_name, c.class_id, c.class_name
HAVING COUNT(*) >= 2;

-- BEFORE INDEXES: Query 7 (attendance percentage below 80% in the term).
EXPLAIN
WITH attendance_by_student AS (
    SELECT
        a.admission_number,
        COUNT(*) AS recorded_days,
        SUM(CASE WHEN a.status IN ('present', 'late') THEN 1 ELSE 0 END) AS attended_days
    FROM attendance a
    JOIN term t
      ON t.label = '2026/2027 First Term'
     AND a.attendance_date BETWEEN t.start_date AND t.end_date
    GROUP BY a.admission_number
)
SELECT
    s.admission_number,
    a.recorded_days,
    a.attended_days,
    ROUND(100.0 * a.attended_days / a.recorded_days, 2) AS attendance_percentage
FROM attendance_by_student a
JOIN student s ON s.admission_number = a.admission_number
WHERE 100.0 * a.attended_days / a.recorded_days < 80;

-- The first two indexes let MySQL find a term's enrollments without scanning enrollment.
-- The attendance index supports a date-range scan and covers the attendance aggregate.
CREATE INDEX ix_enrollment_term_class_student
    ON enrollment (term_id, class_id, admission_number, enrollment_id);

CREATE INDEX ix_attendance_date_student_status
    ON attendance (attendance_date, admission_number, status);

-- AFTER INDEXES: Repeat Query 3.
EXPLAIN
WITH student_averages AS (
    SELECT
        e.enrollment_id,
        e.admission_number,
        e.class_id,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM enrollment e
    JOIN term t ON t.term_id = e.term_id
    JOIN result r ON r.enrollment_id = e.enrollment_id
    WHERE t.label = '2026/2027 First Term'
    GROUP BY e.enrollment_id, e.admission_number, e.class_id
)
SELECT
    c.class_name,
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    ROUND(sa.average_score, 2) AS average_score,
    RANK() OVER (PARTITION BY sa.class_id ORDER BY sa.average_score DESC) AS class_position
FROM student_averages sa
JOIN student s ON s.admission_number = sa.admission_number
JOIN school_class c ON c.class_id = sa.class_id
ORDER BY c.class_name, class_position, s.last_name, s.first_name;

-- AFTER INDEXES: Repeat Query 5.
EXPLAIN
SELECT
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    COUNT(*) AS failed_subject_count
FROM result r
JOIN enrollment e ON e.enrollment_id = r.enrollment_id
JOIN student s ON s.admission_number = e.admission_number
JOIN school_class c ON c.class_id = e.class_id
JOIN term t ON t.term_id = e.term_id
WHERE t.label = '2026/2027 First Term'
  AND r.ca_score + r.exam_score < 40
GROUP BY s.admission_number, s.first_name, s.middle_name, s.last_name, c.class_id, c.class_name
HAVING COUNT(*) >= 2;

-- AFTER INDEXES: Repeat Query 7.
EXPLAIN
WITH attendance_by_student AS (
    SELECT
        a.admission_number,
        COUNT(*) AS recorded_days,
        SUM(CASE WHEN a.status IN ('present', 'late') THEN 1 ELSE 0 END) AS attended_days
    FROM attendance a
    JOIN term t
      ON t.label = '2026/2027 First Term'
     AND a.attendance_date BETWEEN t.start_date AND t.end_date
    GROUP BY a.admission_number
)
SELECT
    s.admission_number,
    a.recorded_days,
    a.attended_days,
    ROUND(100.0 * a.attended_days / a.recorded_days, 2) AS attendance_percentage
FROM attendance_by_student a
JOIN student s ON s.admission_number = a.admission_number
WHERE 100.0 * a.attended_days / a.recorded_days < 80;
