-- Reporting queries for schema.sql.
-- These examples use the sample term; change the label in the filters for another term.

-- 1. Business question: Which students are in JSS1 A for 2026/2027 First Term, and who is their form teacher?
-- Technique: JOINs connect class enrollment to students, the class, term, and form teacher.
SELECT
    s.admission_number,
    s.first_name,
    s.middle_name,
    s.last_name,
    c.class_name,
    CONCAT(ft.first_name, ' ', ft.last_name) AS form_teacher_name
FROM enrollment e
JOIN student s ON s.admission_number = e.admission_number
JOIN school_class c ON c.class_id = e.class_id
JOIN term t ON t.term_id = e.term_id
JOIN teacher ft ON ft.staff_number = c.form_teacher_staff_number
WHERE c.class_name = 'JSS1 A'
  AND t.label = '2026/2027 First Term'
ORDER BY s.last_name, s.first_name, s.admission_number;

-- 2. Business question: What is each student's total score and letter grade in each subject this term?
-- Technique: CASE maps the CA + exam total to a grade band. Thresholds: A >= 80, B >= 70,
-- C >= 60, D >= 50, E >= 40, and F < 40.
SELECT
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    sub.subject_code,
    sub.subject_name,
    r.ca_score,
    r.exam_score,
    r.ca_score + r.exam_score AS total_score,
    CASE
        WHEN r.ca_score + r.exam_score >= 80 THEN 'A'
        WHEN r.ca_score + r.exam_score >= 70 THEN 'B'
        WHEN r.ca_score + r.exam_score >= 60 THEN 'C'
        WHEN r.ca_score + r.exam_score >= 50 THEN 'D'
        WHEN r.ca_score + r.exam_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
FROM result r
JOIN enrollment e ON e.enrollment_id = r.enrollment_id
JOIN student s ON s.admission_number = e.admission_number
JOIN school_class c ON c.class_id = e.class_id
JOIN term t ON t.term_id = e.term_id
JOIN class_subject_offering o ON o.offering_id = r.offering_id
JOIN subject sub ON sub.subject_code = o.subject_code
WHERE t.label = '2026/2027 First Term'
ORDER BY c.class_name, s.last_name, s.first_name, sub.subject_name;

-- 3. Business question: What is each student's average subject score and class position this term?
-- Technique: First aggregate each student's subject scores, then use RANK() partitioned by class.
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
    RANK() OVER (
        PARTITION BY sa.class_id
        ORDER BY sa.average_score DESC
    ) AS class_position
FROM student_averages sa
JOIN student s ON s.admission_number = sa.admission_number
JOIN school_class c ON c.class_id = sa.class_id
ORDER BY c.class_name, class_position, s.last_name, s.first_name;

-- Query 3 fallback for MySQL versions without window functions (for example MySQL 5.7).
-- It assigns tied averages the same rank, as RANK() does. Run this instead of Query 3.
-- The self-join counts students with a strictly higher average in the same class.
/*
SELECT
    c.class_name,
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    ROUND(current_average.average_score, 2) AS average_score,
    COUNT(other_average.enrollment_id) + 1 AS class_position
FROM (
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
) AS current_average
LEFT JOIN (
    SELECT
        e.enrollment_id,
        e.class_id,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM enrollment e
    JOIN term t ON t.term_id = e.term_id
    JOIN result r ON r.enrollment_id = e.enrollment_id
    WHERE t.label = '2026/2027 First Term'
    GROUP BY e.enrollment_id, e.class_id
) AS other_average
  ON other_average.class_id = current_average.class_id
 AND other_average.average_score > current_average.average_score
JOIN student s ON s.admission_number = current_average.admission_number
JOIN school_class c ON c.class_id = current_average.class_id
GROUP BY
    current_average.enrollment_id,
    current_average.admission_number,
    current_average.class_id,
    current_average.average_score,
    s.first_name,
    s.middle_name,
    s.last_name,
    c.class_name
ORDER BY c.class_name, class_position, s.last_name, s.first_name;
*/

-- 4. Business question: What are the average, highest, and lowest student totals for each subject in each class?
-- Technique: GROUP BY groups result rows by class and subject; AVG, MAX, and MIN summarize each group.
SELECT
    c.class_name,
    sub.subject_code,
    sub.subject_name,
    ROUND(AVG(r.ca_score + r.exam_score), 2) AS average_score,
    MAX(r.ca_score + r.exam_score) AS highest_score,
    MIN(r.ca_score + r.exam_score) AS lowest_score
FROM result r
JOIN enrollment e ON e.enrollment_id = r.enrollment_id
JOIN school_class c ON c.class_id = e.class_id
JOIN term t ON t.term_id = e.term_id
JOIN class_subject_offering o ON o.offering_id = r.offering_id
JOIN subject sub ON sub.subject_code = o.subject_code
WHERE t.label = '2026/2027 First Term'
GROUP BY c.class_id, c.class_name, sub.subject_code, sub.subject_name
ORDER BY c.class_name, sub.subject_name;

-- 5. Business question: Which students scored below 40 in at least two subjects this term?
-- Technique: GROUP BY collects each student's failed subjects; HAVING filters the groups by their count.
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
HAVING COUNT(*) >= 2
ORDER BY failed_subject_count DESC, c.class_name, s.last_name, s.first_name;

-- 6. Business question: How many distinct subjects and classes is each teacher assigned this term?
-- Technique: LEFT JOIN retains teachers without offerings; conditional term filtering stays in the JOIN.
SELECT
    t.staff_number,
    CONCAT(t.first_name, ' ', t.last_name) AS teacher_name,
    COUNT(DISTINCT o.subject_code) AS subject_count,
    COUNT(DISTINCT o.class_id) AS class_count
FROM teacher t
LEFT JOIN class_subject_offering o
    ON o.teacher_staff_number = t.staff_number
   AND o.term_id = (
       SELECT term_id
       FROM term
       WHERE label = '2026/2027 First Term'
   )
GROUP BY t.staff_number, t.first_name, t.last_name
ORDER BY teacher_name;

-- 7. Business question: What percentage of recorded school days did each student attend, and who is below 80%?
-- Technique: A CTE scans attendance in the term's date range once, aggregates by student,
-- then LEFT JOIN preserves students with no attendance; present and late count as attended.
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
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    a.recorded_days,
    a.attended_days,
    ROUND(100.0 * a.attended_days / a.recorded_days, 2) AS attendance_percentage
FROM attendance_by_student a
JOIN student s ON s.admission_number = a.admission_number
WHERE 100.0 * a.attended_days / a.recorded_days < 80
ORDER BY attendance_percentage, s.last_name, s.first_name;

-- 8. Business question: Who is the top-scoring student or students in each class this term?
-- Technique: A correlated subquery compares each student's total with every other total in that class;
-- >= ALL includes ties for the highest total.
SELECT
    c.class_name,
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    SUM(r.ca_score + r.exam_score) AS total_score
FROM enrollment e
JOIN result r ON r.enrollment_id = e.enrollment_id
JOIN term t ON t.term_id = e.term_id
JOIN school_class c ON c.class_id = e.class_id
JOIN student s ON s.admission_number = e.admission_number
WHERE t.label = '2026/2027 First Term'
GROUP BY
    e.enrollment_id,
    e.admission_number,
    e.class_id,
    e.term_id,
    c.class_name,
    s.first_name,
    s.middle_name,
    s.last_name
HAVING SUM(r.ca_score + r.exam_score) >= ALL (
    SELECT SUM(r2.ca_score + r2.exam_score)
    FROM enrollment e2
    JOIN result r2 ON r2.enrollment_id = e2.enrollment_id
    WHERE e2.class_id = e.class_id
      AND e2.term_id = e.term_id
    GROUP BY e2.enrollment_id
)
ORDER BY c.class_name, s.last_name, s.first_name;

-- View: one row per student/subject result, including term, class, total, and grade.
CREATE OR REPLACE VIEW v_student_results AS
SELECT
    s.admission_number,
    CONCAT_WS(' ', s.first_name, s.middle_name, s.last_name) AS student_name,
    c.class_name,
    t.term_id,
    t.label AS term_label,
    sub.subject_code,
    sub.subject_name,
    r.ca_score,
    r.exam_score,
    r.ca_score + r.exam_score AS total_score,
    CASE
        WHEN r.ca_score + r.exam_score >= 80 THEN 'A'
        WHEN r.ca_score + r.exam_score >= 70 THEN 'B'
        WHEN r.ca_score + r.exam_score >= 60 THEN 'C'
        WHEN r.ca_score + r.exam_score >= 50 THEN 'D'
        WHEN r.ca_score + r.exam_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
FROM result r
JOIN enrollment e ON e.enrollment_id = r.enrollment_id
JOIN student s ON s.admission_number = e.admission_number
JOIN school_class c ON c.class_id = e.class_id
JOIN term t ON t.term_id = e.term_id
JOIN class_subject_offering o ON o.offering_id = r.offering_id
JOIN subject sub ON sub.subject_code = o.subject_code;

-- View: one row per class and term, including classes with no enrollments or results.
-- Average/high/low are computed over recorded student-subject totals.
CREATE OR REPLACE VIEW v_class_summary AS
SELECT
    c.class_id,
    c.class_name,
    t.term_id,
    t.label AS term_label,
    CONCAT(ft.first_name, ' ', ft.last_name) AS form_teacher_name,
    COALESCE(enrollment_counts.student_count, 0) AS student_count,
    COALESCE(offering_summary.subject_count, 0) AS subject_count,
    result_summary.average_score,
    result_summary.highest_score,
    result_summary.lowest_score
FROM school_class c
CROSS JOIN term t
JOIN teacher ft ON ft.staff_number = c.form_teacher_staff_number
LEFT JOIN (
    SELECT
        class_id,
        term_id,
        COUNT(DISTINCT admission_number) AS student_count
    FROM enrollment
    GROUP BY class_id, term_id
) AS enrollment_counts
    ON enrollment_counts.class_id = c.class_id
   AND enrollment_counts.term_id = t.term_id
LEFT JOIN (
    SELECT
        class_id,
        term_id,
        COUNT(DISTINCT subject_code) AS subject_count
    FROM class_subject_offering
    GROUP BY class_id, term_id
) AS offering_summary
    ON offering_summary.class_id = c.class_id
   AND offering_summary.term_id = t.term_id
LEFT JOIN (
    SELECT
        e.class_id,
        e.term_id,
        ROUND(AVG(r.ca_score + r.exam_score), 2) AS average_score,
        MAX(r.ca_score + r.exam_score) AS highest_score,
        MIN(r.ca_score + r.exam_score) AS lowest_score
    FROM result r
    JOIN enrollment e ON e.enrollment_id = r.enrollment_id
    GROUP BY e.class_id, e.term_id
) AS result_summary
    ON result_summary.class_id = c.class_id
   AND result_summary.term_id = t.term_id;
