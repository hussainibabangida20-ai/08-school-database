-- MySQL 8.0+ / compatible MariaDB stored procedure for recording a subject result.
DROP PROCEDURE IF EXISTS sp_record_result;

DELIMITER //
CREATE PROCEDURE sp_record_result(
    IN p_admission_number VARCHAR(20),
    IN p_subject_code VARCHAR(12),
    IN p_term_id INT UNSIGNED,
    IN p_ca_score DECIMAL(5,2),
    IN p_exam_score DECIMAL(5,2)
)
BEGIN
    DECLARE v_enrollment_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_offering_id INT UNSIGNED DEFAULT NULL;

    IF p_admission_number IS NULL OR TRIM(p_admission_number) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Admission number is required';
    END IF;

    IF p_subject_code IS NULL OR TRIM(p_subject_code) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Subject code is required';
    END IF;

    IF p_term_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Term ID is required';
    END IF;

    IF p_ca_score IS NULL OR p_ca_score < 0 OR p_ca_score > 40 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CA score must be between 0 and 40';
    END IF;

    IF p_exam_score IS NULL OR p_exam_score < 0 OR p_exam_score > 60 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Exam score must be between 0 and 60';
    END IF;

    -- Aggregate SELECT always returns one row; NULL IDs mean the student is not
    -- enrolled in the term, or the subject is not offered to that student's class.
    SELECT MAX(e.enrollment_id), MAX(o.offering_id)
      INTO v_enrollment_id, v_offering_id
    FROM enrollment e
    JOIN class_subject_offering o
      ON o.class_id = e.class_id
     AND o.term_id = e.term_id
     AND o.subject_code = p_subject_code
    WHERE e.admission_number = p_admission_number
      AND e.term_id = p_term_id;

    IF v_enrollment_id IS NULL OR v_offering_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student enrollment or class subject offering was not found for this term';
    END IF;

    INSERT INTO result (enrollment_id, offering_id, ca_score, exam_score)
    VALUES (v_enrollment_id, v_offering_id, p_ca_score, p_exam_score)
    ON DUPLICATE KEY UPDATE
        ca_score = VALUES(ca_score),
        exam_score = VALUES(exam_score);
END//
DELIMITER ;

-- Example:
-- p_term_id is term.term_id; look it up by label if you do not know the ID.
-- SELECT term_id FROM term WHERE label = '2026/2027 First Term';
-- CALL sp_record_result('STU-001', 'ENGLISH', 1, 32.50, 51.00);
