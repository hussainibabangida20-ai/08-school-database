-- Sample data for schema.sql. Run after creating the schema.

INSERT INTO teacher
    (staff_number, first_name, last_name, email, phone, hire_date)
VALUES
    ('TCH-001', 'Adaeze', 'Okafor', 'adaeze.okafor@unityschool.ng', '+2348035550101', '2018-09-03'),
    ('TCH-002', 'Chinedu', 'Bello', 'chinedu.bello@unityschool.ng', '+2348035550102', '2019-01-14'),
    ('TCH-003', 'Fatima', 'Musa', 'fatima.musa@unityschool.ng', '+2348035550103', '2017-09-11'),
    ('TCH-004', 'Tunde', 'Adebayo', 'tunde.adebayo@unityschool.ng', '+2348035550104', '2020-02-03'),
    ('TCH-005', 'Ngozi', 'Eze', 'ngozi.eze@unityschool.ng', '+2348035550105', '2016-09-05'),
    ('TCH-006', 'Samuel', 'Ojo', 'samuel.ojo@unityschool.ng', '+2348035550106', '2021-01-18');

INSERT INTO subject (subject_code, subject_name)
VALUES
    ('BASIC-SCI', 'Basic Science'),
    ('BASIC-TECH', 'Basic Technology'),
    ('BUS-STUD', 'Business Studies'),
    ('CIVIC', 'Civic Education'),
    ('ENGLISH', 'English Studies'),
    ('FRENCH', 'French'),
    ('MATHEMATICS', 'Mathematics'),
    ('SOCIAL-STUD', 'Social Studies');

INSERT INTO term (label, start_date, end_date)
VALUES ('2026/2027 First Term', '2026-09-07', '2026-12-11');

INSERT INTO school_class (class_name, form_teacher_staff_number)
VALUES
    ('JSS1 A', 'TCH-001'),
    ('JSS2 A', 'TCH-002'),
    ('JSS3 A', 'TCH-003');

INSERT INTO student
    (admission_number, first_name, middle_name, last_name, date_of_birth, gender, guardian_name, guardian_phone)
VALUES
    ('STU-001', 'Amara', 'Chidinma', 'Okonkwo', '2013-04-12', 'Female', 'Emeka Okonkwo', '+2348035551001'),
    ('STU-002', 'Ibrahim', 'Sani', 'Abubakar', '2013-08-21', 'Male', 'Aisha Abubakar', '+2348035551002'),
    ('STU-003', 'Yetunde', 'Morenike', 'Afolabi', '2013-02-09', 'Female', 'Kunle Afolabi', '+2348035551003'),
    ('STU-004', 'David', 'Chukwudi', 'Nwosu', '2013-11-03', 'Male', 'Grace Nwosu', '+2348035551004'),
    ('STU-005', 'Zainab', 'Hauwa', 'Yusuf', '2013-06-17', 'Female', 'Musa Yusuf', '+2348035551005'),
    ('STU-006', 'Oluwaseun', 'Damilola', 'Adeyemi', '2013-01-28', 'Male', 'Bisi Adeyemi', '+2348035551006'),
    ('STU-007', 'Chiamaka', 'Ngozi', 'Eze', '2013-09-14', 'Female', 'Ifeanyi Eze', '+2348035551007'),
    ('STU-008', 'Tobi', 'Oluwatobi', 'Balogun', '2013-05-06', 'Male', 'Kemi Balogun', '+2348035551008'),
    ('STU-009', 'Maryam', 'Amina', 'Bello', '2013-12-19', 'Female', 'Salihu Bello', '+2348035551009'),
    ('STU-010', 'Chisom', 'Obinna', 'Ibe', '2013-03-30', 'Male', 'Ngozi Ibe', '+2348035551010'),
    ('STU-011', 'Fiyinfoluwa', 'Grace', 'Ojo', '2012-07-11', 'Female', 'Samuel Ojo', '+2348035551011'),
    ('STU-012', 'Mustapha', 'Bashir', 'Sule', '2012-10-25', 'Male', 'Hadiza Sule', '+2348035551012'),
    ('STU-013', 'Nneka', 'Ihuoma', 'Okafor', '2012-02-16', 'Female', 'Chuka Okafor', '+2348035551013'),
    ('STU-014', 'Ayomide', 'Joseph', 'Ogunleye', '2012-05-22', 'Male', 'Mojisola Ogunleye', '+2348035551014'),
    ('STU-015', 'Safiya', 'Bilkisu', 'Garba', '2012-09-08', 'Female', 'Abubakar Garba', '+2348035551015'),
    ('STU-016', 'Ebuka', 'Daniel', 'Umeh', '2012-01-13', 'Male', 'Ada Umeh', '+2348035551016'),
    ('STU-017', 'Temiloluwa', 'Eniola', 'Akinyemi', '2012-11-29', 'Female', 'Femi Akinyemi', '+2348035551017'),
    ('STU-018', 'Yusuf', 'Kabir', 'Mohammed', '2012-04-04', 'Male', 'Rabi Mohammed', '+2348035551018'),
    ('STU-019', 'Precious', 'Ifeoma', 'Onyeka', '2012-06-26', 'Female', 'Chinedu Onyeka', '+2348035551019'),
    ('STU-020', 'Babatunde', 'Ayo', 'Lawal', '2012-12-02', 'Male', 'Ronke Lawal', '+2348035551020'),
    ('STU-021', 'Olamide', 'Zainab', 'Bakare', '2011-03-18', 'Female', 'Tunde Bakare', '+2348035551021'),
    ('STU-022', 'Peter', 'Chibueze', 'Anyanwu', '2011-08-07', 'Male', 'Ngozi Anyanwu', '+2348035551022'),
    ('STU-023', 'Aisha', 'Mariam', 'Tanko', '2011-01-24', 'Female', 'Salisu Tanko', '+2348035551023'),
    ('STU-024', 'Oluwatobi', 'Emmanuel', 'Fashola', '2011-10-12', 'Male', 'Folake Fashola', '+2348035551024'),
    ('STU-025', 'Adaobi', 'Chiamaka', 'Nnamdi', '2011-05-31', 'Female', 'Ikenna Nnamdi', '+2348035551025'),
    ('STU-026', 'Abdullahi', 'Ibrahim', 'Danladi', '2011-07-15', 'Male', 'Fatima Danladi', '+2348035551026'),
    ('STU-027', 'Kehinde', 'Taiwo', 'Olawale', '2011-02-03', 'Female', 'Akin Olawale', '+2348035551027'),
    ('STU-028', 'Chukwuma', 'Kelechi', 'Obi', '2011-09-20', 'Male', 'Ngozi Obi', '+2348035551028'),
    ('STU-029', 'Hafsat', 'Maimuna', 'Shehu', '2011-04-27', 'Female', 'Ismail Shehu', '+2348035551029'),
    ('STU-030', 'Oluwadamilare', 'Femi', 'Adebisi', '2011-12-10', 'Male', 'Sade Adebisi', '+2348035551030');

-- Assign each student to one class for the sample term; the admission-number ranges
-- only determine sample grouping and are not a production assignment rule.
INSERT INTO enrollment (admission_number, term_id, class_id)
SELECT s.admission_number, t.term_id, c.class_id
FROM student s
CROSS JOIN term t
JOIN school_class c
  ON c.class_name = CASE
       WHEN CAST(SUBSTRING(s.admission_number, 5) AS UNSIGNED) BETWEEN 1 AND 10 THEN 'JSS1 A'
       WHEN CAST(SUBSTRING(s.admission_number, 5) AS UNSIGNED) BETWEEN 11 AND 20 THEN 'JSS2 A'
       ELSE 'JSS3 A'
     END
WHERE t.label = '2026/2027 First Term';

-- Each class takes all eight sample subjects. Teacher assignments are repeated
-- consistently across classes for compact, deterministic sample data.
INSERT INTO class_subject_offering (term_id, class_id, subject_code, teacher_staff_number)
SELECT t.term_id, c.class_id, s.subject_code,
       CASE s.subject_code
           WHEN 'ENGLISH' THEN 'TCH-001'
           WHEN 'MATHEMATICS' THEN 'TCH-002'
           WHEN 'BASIC-SCI' THEN 'TCH-003'
           WHEN 'BASIC-TECH' THEN 'TCH-004'
           WHEN 'CIVIC' THEN 'TCH-005'
           WHEN 'SOCIAL-STUD' THEN 'TCH-006'
           WHEN 'BUS-STUD' THEN 'TCH-004'
           WHEN 'FRENCH' THEN 'TCH-005'
       END
FROM term t
CROSS JOIN school_class c
CROSS JOIN subject s
WHERE t.label = '2026/2027 First Term';

-- Generate one result for every enrolled student and every subject offered
-- to that student's class in the term (30 students x 8 subjects = 240 rows).
INSERT INTO result (enrollment_id, offering_id, ca_score, exam_score)
SELECT e.enrollment_id,
       o.offering_id,
       25 + MOD(e.enrollment_id * 3 + o.offering_id, 16),
       42 + MOD(e.enrollment_id * 5 + o.offering_id, 19)
FROM enrollment e
JOIN class_subject_offering o
  ON o.class_id = e.class_id
 AND o.term_id = e.term_id;

-- Generate five consecutive attendance days for all 30 students (150 rows).
INSERT INTO attendance (admission_number, attendance_date, status)
SELECT s.admission_number,
       d.attendance_date,
       CASE MOD(CAST(SUBSTRING(s.admission_number, 5) AS UNSIGNED) + d.day_number, 20)
           WHEN 0 THEN 'absent'
           WHEN 1 THEN 'late'
           ELSE 'present'
       END
FROM student s
CROSS JOIN (
    SELECT 1 AS day_number, DATE('2026-09-07') AS attendance_date
    UNION ALL SELECT 2, DATE('2026-09-08')
    UNION ALL SELECT 3, DATE('2026-09-09')
    UNION ALL SELECT 4, DATE('2026-09-10')
    UNION ALL SELECT 5, DATE('2026-09-11')
) AS d;
