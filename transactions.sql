-- Class-move audit and transaction examples.
-- Run after schema.sql. The example transaction is intentionally commented out
-- so importing this file does not change a student's enrollment.

CREATE TABLE IF NOT EXISTS class_transfers (
    transfer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    enrollment_id INT UNSIGNED NOT NULL,
    term_id INT UNSIGNED NOT NULL,
    from_class_id INT UNSIGNED NOT NULL,
    to_class_id INT UNSIGNED NOT NULL,
    transferred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (transfer_id),
    KEY ix_class_transfers_enrollment (enrollment_id),
    KEY ix_class_transfers_term (term_id),
    KEY ix_class_transfers_from_class (from_class_id),
    KEY ix_class_transfers_to_class (to_class_id),
    -- RESTRICT preserves audit history; CASCADE follows corrections to surrogate keys.
    CONSTRAINT fk_class_transfers_enrollment
        FOREIGN KEY (enrollment_id) REFERENCES enrollment (enrollment_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_class_transfers_term
        FOREIGN KEY (term_id) REFERENCES term (term_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_class_transfers_from_class
        FOREIGN KEY (from_class_id) REFERENCES school_class (class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_class_transfers_to_class
        FOREIGN KEY (to_class_id) REFERENCES school_class (class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Basic transaction pattern. Replace the sample values and run only for an
-- enrollment that has no results yet. Moving a scored enrollment requires a
-- deliberate score-transfer policy so results remain attached to the correct
-- class subject offerings.
--
-- SET @move_admission_number = 'STU-001';
-- SET @move_term_id = (SELECT term_id FROM term WHERE label = '2026/2027 First Term');
-- SET @move_target_class_name = 'JSS2 A';
--
-- START TRANSACTION;
--
-- Statement 1: record the old and new class before changing the enrollment.
-- INSERT INTO class_transfers
--     (enrollment_id, term_id, from_class_id, to_class_id)
-- SELECT e.enrollment_id, e.term_id, e.class_id, target.class_id
-- FROM enrollment e
-- JOIN school_class target ON target.class_name = @move_target_class_name
-- WHERE e.admission_number = @move_admission_number
--   AND e.term_id = @move_term_id
--   AND e.class_id <> target.class_id
--   AND NOT EXISTS (
--       SELECT 1 FROM result r WHERE r.enrollment_id = e.enrollment_id
--   );
--
-- Statement 2: perform the move; its predicate must match the audit insert.
-- UPDATE enrollment e
-- JOIN school_class target ON target.class_name = @move_target_class_name
-- SET e.class_id = target.class_id
-- WHERE e.admission_number = @move_admission_number
--   AND e.term_id = @move_term_id
--   AND e.class_id <> target.class_id
--   AND NOT EXISTS (
--       SELECT 1 FROM result r WHERE r.enrollment_id = e.enrollment_id
--   );
--
-- COMMIT;
--
-- The guarded version below raises an error and rolls back if the target class
-- does not exist (or if the student/term enrollment is invalid). It also locks
-- the enrollment and rejects moves that would detach existing results.
DROP PROCEDURE IF EXISTS sp_move_student;

DELIMITER //
CREATE PROCEDURE sp_move_student(
    IN p_admission_number VARCHAR(20),
    IN p_term_id INT UNSIGNED,
    IN p_target_class_name VARCHAR(30)
)
BEGIN
    DECLARE v_enrollment_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_from_class_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_to_class_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_result_count INT UNSIGNED DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT enrollment_id, class_id
      INTO v_enrollment_id, v_from_class_id
    FROM enrollment
    WHERE admission_number = p_admission_number
      AND term_id = p_term_id
    LIMIT 1
    FOR UPDATE;

    IF v_enrollment_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No enrollment exists for this student and term';
    END IF;

    SELECT class_id
      INTO v_to_class_id
    FROM school_class
    WHERE class_name = p_target_class_name
    LIMIT 1
    FOR UPDATE;

    IF v_to_class_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Target class does not exist; transaction rolled back';
    END IF;

    IF v_to_class_id = v_from_class_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is already enrolled in the target class';
    END IF;

    SELECT COUNT(*)
      INTO v_result_count
    FROM result
    WHERE enrollment_id = v_enrollment_id;

    IF v_result_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Enrollment already has results; resolve score transfer before moving';
    END IF;

    INSERT INTO class_transfers
        (enrollment_id, term_id, from_class_id, to_class_id)
    VALUES
        (v_enrollment_id, p_term_id, v_from_class_id, v_to_class_id);

    UPDATE enrollment
    SET class_id = v_to_class_id
    WHERE enrollment_id = v_enrollment_id;

    COMMIT;
END//
DELIMITER ;

-- Example call (succeeds only for an enrollment without results):
-- CALL sp_move_student('STU-001', 1, 'JSS2 A');
--
-- Missing-target rollback example:
-- CALL sp_move_student('STU-001', 1, 'CLASS DOES NOT EXIST');
-- The procedure raises SQLSTATE 45000; its exception handler runs ROLLBACK.
