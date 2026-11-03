-- MySQL 8.0.16+ or a MariaDB version that enforces CHECK constraints.
-- Run this file in the intended database/schema.

DROP TRIGGER IF EXISTS bi_result_validate_offering;
DROP TRIGGER IF EXISTS bu_result_validate_offering;

-- Drop dependent tables before their parents so the script can be re-run.
DROP TABLE IF EXISTS result;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS enrollment;
DROP TABLE IF EXISTS class_subject_offering;
DROP TABLE IF EXISTS school_class;
DROP TABLE IF EXISTS subject;
DROP TABLE IF EXISTS term;
DROP TABLE IF EXISTS teacher;
DROP TABLE IF EXISTS student;

CREATE TABLE student (
    admission_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    guardian_name VARCHAR(120) NOT NULL,
    guardian_phone VARCHAR(20) NOT NULL,
    PRIMARY KEY (admission_number)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE teacher (
    staff_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(254) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL,
    PRIMARY KEY (staff_number),
    UNIQUE KEY uq_teacher_email (email)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE term (
    term_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    label VARCHAR(80) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    PRIMARY KEY (term_id),
    UNIQUE KEY uq_term_label (label),
    CONSTRAINT chk_term_dates CHECK (start_date <= end_date)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE subject (
    subject_code VARCHAR(12) NOT NULL,
    subject_name VARCHAR(80) NOT NULL,
    PRIMARY KEY (subject_code),
    UNIQUE KEY uq_subject_name (subject_name)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE school_class (
    class_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    class_name VARCHAR(30) NOT NULL,
    form_teacher_staff_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (class_id),
    UNIQUE KEY uq_school_class_name (class_name),
    KEY ix_school_class_form_teacher (form_teacher_staff_number),
    -- RESTRICT prevents deleting a teacher who is still assigned; CASCADE propagates a staff-number correction.
    CONSTRAINT fk_school_class_form_teacher
        FOREIGN KEY (form_teacher_staff_number) REFERENCES teacher (staff_number)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE enrollment (
    enrollment_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    admission_number VARCHAR(20) NOT NULL,
    term_id INT UNSIGNED NOT NULL,
    class_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (enrollment_id),
    -- One enrollment per student and term is needed for unambiguous results and class history.
    UNIQUE KEY uq_enrollment_student_term (admission_number, term_id),
    -- Supports the result-integrity trigger that verifies an offering is for the student's enrolled class and term.
    UNIQUE KEY uq_enrollment_id_class_term (enrollment_id, class_id, term_id),
    KEY ix_enrollment_class_term (class_id, term_id),
    -- RESTRICT preserves student records; CASCADE keeps changed admission numbers consistent.
    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (admission_number) REFERENCES student (admission_number)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT prevents removing a term that has enrollment history; CASCADE propagates a term-key correction.
    CONSTRAINT fk_enrollment_term
        FOREIGN KEY (term_id) REFERENCES term (term_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT protects enrollment history from class deletion; CASCADE propagates a class-key correction.
    CONSTRAINT fk_enrollment_class
        FOREIGN KEY (class_id) REFERENCES school_class (class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE class_subject_offering (
    offering_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    term_id INT UNSIGNED NOT NULL,
    class_id INT UNSIGNED NOT NULL,
    subject_code VARCHAR(12) NOT NULL,
    teacher_staff_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (offering_id),
    -- A class has at most one instance of a subject in a term.
    UNIQUE KEY uq_offering_class_subject_term (class_id, subject_code, term_id),
    -- Supports the result-integrity trigger that compares the offering with an enrollment.
    UNIQUE KEY uq_offering_id_class_term (offering_id, class_id, term_id),
    KEY ix_offering_term_subject (term_id, subject_code),
    KEY ix_offering_teacher (teacher_staff_number),
    -- RESTRICT prevents deleting a term with scheduled subjects; CASCADE propagates a term-key correction.
    CONSTRAINT fk_offering_term
        FOREIGN KEY (term_id) REFERENCES term (term_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT preserves class schedules; CASCADE propagates a class-key correction.
    CONSTRAINT fk_offering_class
        FOREIGN KEY (class_id) REFERENCES school_class (class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT prevents deleting a subject still on a schedule; CASCADE propagates a subject-code correction.
    CONSTRAINT fk_offering_subject
        FOREIGN KEY (subject_code) REFERENCES subject (subject_code)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- RESTRICT requires reassigning classes before a teacher is deleted; CASCADE propagates a staff-number correction.
    CONSTRAINT fk_offering_teacher
        FOREIGN KEY (teacher_staff_number) REFERENCES teacher (staff_number)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE result (
    enrollment_id INT UNSIGNED NOT NULL,
    offering_id INT UNSIGNED NOT NULL,
    ca_score DECIMAL(5,2) NOT NULL,
    exam_score DECIMAL(5,2) NOT NULL,
    CONSTRAINT pk_result_student_subject_term PRIMARY KEY (enrollment_id, offering_id),
    -- The composite key gives one result per student/subject/term: enrollment is unique per student/term,
    -- and an offering is unique per class/subject/term. This avoids copying those attributes into this table.
    -- CASCADE removes scores that have no meaning after their enrollment or offering is removed;
    -- CASCADE on update keeps the referenced surrogate keys aligned.
    CONSTRAINT fk_result_enrollment
        FOREIGN KEY (enrollment_id) REFERENCES enrollment (enrollment_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_result_offering
        FOREIGN KEY (offering_id) REFERENCES class_subject_offering (offering_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_result_ca_score CHECK (ca_score >= 0 AND ca_score <= 40),
    CONSTRAINT chk_result_exam_score CHECK (exam_score >= 0 AND exam_score <= 60)
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE attendance (
    admission_number VARCHAR(20) NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM('present', 'absent', 'late') NOT NULL,
    PRIMARY KEY (admission_number, attendance_date),
    -- CASCADE deletes attendance when its student is removed; CASCADE on update follows admission-number corrections.
    CONSTRAINT fk_attendance_student
        FOREIGN KEY (admission_number) REFERENCES student (admission_number)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- The two result foreign keys alone cannot express that enrollment and offering must share
-- the same class and term. Enforce that cross-table business rule at write time.
DELIMITER //
CREATE TRIGGER bi_result_validate_offering
BEFORE INSERT ON result
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM enrollment e
        JOIN class_subject_offering o
          ON o.offering_id = NEW.offering_id
         AND o.class_id = e.class_id
         AND o.term_id = e.term_id
        WHERE e.enrollment_id = NEW.enrollment_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Result enrollment and subject offering must have the same class and term';
    END IF;
END//

CREATE TRIGGER bu_result_validate_offering
BEFORE UPDATE ON result
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM enrollment e
        JOIN class_subject_offering o
          ON o.offering_id = NEW.offering_id
         AND o.class_id = e.class_id
         AND o.term_id = e.term_id
        WHERE e.enrollment_id = NEW.enrollment_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Result enrollment and subject offering must have the same class and term';
    END IF;
END//
DELIMITER ;
