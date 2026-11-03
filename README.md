# Secondary School Database Design

## 1. Entities, keys, and relationships

A student's class is recorded **per term** through enrollment, rather than stored permanently on the student. This preserves class history as students advance.

| Entity | Attributes and keys |
|---|---|
| **Student** | **PK** admission number; first, middle, and last name; date of birth; gender; guardian name; guardian phone |
| **Teacher** | **PK** staff number; first and last name; email (**unique**); phone; hire date |
| **Class** | **PK** class ID; class name (**unique**, e.g. “JSS1 A”); form teacher staff number (**FK** → Teacher) |
| **Subject** | **PK** subject code; subject name |
| **Term** | **PK** term ID; label (**unique**, e.g. “2026/2027 First Term”); start date; end date |
| **Enrollment** | **PK** enrollment ID; student admission number (**FK**); term ID (**FK**); class ID (**FK**). Enforce one enrollment per student per term. |
| **ClassSubjectOffering** | **PK** offering ID; term ID (**FK**); class ID (**FK**); subject code (**FK**); teacher staff number (**FK**). Enforce one offering per class, subject, and term. |
| **Result** | **Composite PK** enrollment ID (**FK**) + offering ID (**FK**); CA score; exam score |
| **Attendance** | **Composite PK** student admission number (**FK**) + attendance date; status: present, absent, or late |
| **ClassTransfer** | **PK** transfer ID; enrollment ID, term ID, source class ID, destination class ID (**FKs**); transfer timestamp |

### Relationships and cardinalities

- **Teacher → Class (form teacher): 1:N.** Each class has exactly one form teacher; a teacher may form-teach multiple classes unless the school enforces a one-class limit.
- **Student → Enrollment: 1:N**, **Class → Enrollment: 1:N**, and **Term → Enrollment: 1:N**. Enrollment records which class a student belongs to in each term.
- **Class, Subject, and Term → ClassSubjectOffering: 1:N each.** This resolves the **M:N relationship between classes and subjects** and records the teacher assigned to each offering. A class takes many subjects, and a subject can be taken by many classes.
- **Teacher → ClassSubjectOffering: 1:N.** Each offering has one teacher; a teacher may teach multiple offerings.
- **Enrollment → Result: 1:N** and **ClassSubjectOffering → Result: 1:N.** Together these represent the **M:N relationship between enrolled students and subject offerings**, with CA and exam scores as attributes of that relationship.
- **Student → Attendance: 1:N.** Each attendance record belongs to one student, and the composite key permits at most one record per student per day.
- **Enrollment → ClassTransfer: 1:N.** Each transfer logs one enrollment's move from a source class to a destination class; both class references and the term are retained for audit history.

Business rules: a result's enrollment and offering must be for the **same term and class**; the schema trigger enforces this. Attendance dates should fall within the student's active enrollment term; this remains a date/business-rule validation because daily attendance is keyed directly by student and date.

## 2. Third normal form

- **First normal form (1NF):** Each field holds one value, with no repeating groups. For example, store one guardian phone number in a field, not a list of numbers in a single field.
- **Second normal form (2NF):** Non-key attributes depend on the *whole* key. In `Result`, CA and exam scores depend on both the enrollment and the offering, not just one of them.
- **Third normal form (3NF):** Non-key attributes depend on the key, the whole key, and nothing but the key. Student details belong to `Student`, subject details to `Subject`, and teacher details to `Teacher`; they are not copied into results or enrollments.

**Example of a 3NF violation:** Storing `subject_name` on each result duplicates subject data. The subject code determines the subject name, so that name belongs in `Subject`, not `Result`. Likewise, a teacher's email belongs with the teacher, not on each result.

## 3. ER diagram

```mermaid
erDiagram
    TEACHER {
        string staff_number PK
        string first_name
        string last_name
        string email UK
        string phone
        date hire_date
    }

    STUDENT {
        string admission_number PK
        string first_name
        string middle_name
        string last_name
        date date_of_birth
        string gender
        string guardian_name
        string guardian_phone
    }

    CLASS {
        int class_id PK
        string class_name UK
        string form_teacher_staff_number FK
    }

    SUBJECT {
        string subject_code PK
        string subject_name
    }

    TERM {
        int term_id PK
        string label UK
        date start_date
        date end_date
    }

    ENROLLMENT {
        int enrollment_id PK
        string admission_number FK
        int term_id FK
        int class_id FK
    }

    CLASS_SUBJECT_OFFERING {
        int offering_id PK
        int term_id FK
        int class_id FK
        string subject_code FK
        string teacher_staff_number FK
    }

    RESULT {
        int enrollment_id PK, FK
        int offering_id PK, FK
        decimal ca_score
        decimal exam_score
    }

    ATTENDANCE {
        string admission_number PK, FK
        date attendance_date PK
        string status
    }

    CLASS_TRANSFER {
        int transfer_id PK
        int enrollment_id FK
        int term_id FK
        int from_class_id FK
        int to_class_id FK
        datetime transferred_at
    }

    TEACHER ||--o{ CLASS : "form teaches"
    STUDENT ||--o{ ENROLLMENT : "has"
    CLASS ||--o{ ENROLLMENT : "contains"
    TERM ||--o{ ENROLLMENT : "records"
    CLASS ||--o{ CLASS_SUBJECT_OFFERING : "offers"
    SUBJECT ||--o{ CLASS_SUBJECT_OFFERING : "is offered as"
    TERM ||--o{ CLASS_SUBJECT_OFFERING : "schedules"
    TEACHER ||--o{ CLASS_SUBJECT_OFFERING : "teaches"
    ENROLLMENT ||--o{ RESULT : "earns"
    CLASS_SUBJECT_OFFERING ||--o{ RESULT : "has scores"
    STUDENT ||--o{ ATTENDANCE : "has daily records"
    ENROLLMENT ||--o{ CLASS_TRANSFER : "has transfer history"
    TERM ||--o{ CLASS_TRANSFER : "records"
    CLASS ||--o{ CLASS_TRANSFER : "is source class"
    CLASS ||--o{ CLASS_TRANSFER : "is destination class"
```

CA scores range from **0–40**, and exam scores from **0–60**. These are validation rules for results.

## Load the database

The scripts target MySQL 8.0.16+ (including enforced `CHECK` constraints) or a compatible MariaDB release. In phpMyAdmin, create/select a database using `utf8mb4`, then use **Import** to load the files in this order:

1. [`schema.sql`](./schema.sql) — creates the tables and result-integrity triggers. **It drops and recreates the tables**, so re-running it deletes existing data.
2. [`seed.sql`](./seed.sql) — inserts the Nigerian sample records.
3. [`indexes.sql`](./indexes.sql) — first prints three baseline `EXPLAIN` plans, adds two indexes, then prints the plans again. Run once; the `CREATE INDEX` statements are not intended to be repeated.
4. [`queries.sql`](./queries.sql) — contains the eight reports and creates the two views.
5. [`procedures.sql`](./procedures.sql) — creates `sp_record_result`.
6. [`transactions.sql`](./transactions.sql) — creates the transfer audit table and `sp_move_student`. The example transaction is commented out, so importing this file does not move a student.

Alternatively, create the database in the MySQL client, then run each script with `SOURCE`:

```sql
CREATE DATABASE school_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE school_db;
SOURCE C:/path/to/schema.sql;
SOURCE C:/path/to/seed.sql;
SOURCE C:/path/to/indexes.sql;
SOURCE C:/path/to/queries.sql;
SOURCE C:/path/to/procedures.sql;
SOURCE C:/path/to/transactions.sql;
```

Replace `C:/path/to/` with the directory containing the files. In phpMyAdmin, select `school_db` before importing each file.

## File guide

| File | Purpose |
|---|---|
| [`schema.sql`](./schema.sql) | InnoDB tables, keys, constraints, and triggers |
| [`seed.sql`](./seed.sql) | Sample teachers, students, classes, subjects, term, results, and attendance |
| [`queries.sql`](./queries.sql) | Eight numbered reports and the `v_student_results` / `v_class_summary` views |
| [`indexes.sql`](./indexes.sql) | Before/after `EXPLAIN` statements and reporting indexes |
| [`procedures.sql`](./procedures.sql) | Validated result upsert procedure |
| [`transactions.sql`](./transactions.sql) | Class-transfer audit table, transaction template, and guarded move procedure |

## Understanding the EXPLAIN plans

`indexes.sql` runs `EXPLAIN` on reports 3, 5, and 7 before and after creating indexes. The first columns to compare are:

- **`type`** — access method. `ALL` means a table scan; `range` scans a range of index values; `ref` is an indexed equality lookup; `eq_ref` finds at most one row through a unique key. Generally, avoid large-table `ALL` scans when a selective index can be used.
- **`key`** — the index MySQL chose. `NULL` means it chose no index for that table access. Check this alongside `possible_keys`; an index can exist without being selected.
- **`rows`** — estimated rows examined for that plan step, not the actual result count. Estimates depend on table size and statistics.

Expected change on a realistically sized database:

| Query | Before | After |
|---|---|---|
| 3 — averages and class rank | Enrollment may be scanned because existing enrollment indexes do not start with `term_id`. | `ix_enrollment_term_class_student` can support finding a term's enrollments and provide the class/student grouping columns. The result primary key already supports joining scores by enrollment. |
| 5 — two or more failed subjects | The same missing term-leading enrollment access can make enrollment scanning expensive. The score condition is an expression, so it is not directly searchable with an ordinary score-column index. | The term-leading enrollment index narrows enrolled students before looking up result rows by their existing primary key. |
| 7 — low attendance percentage | Attendance may be scanned to find dates in the selected term. | `ix_attendance_date_student_status` supports a date-range scan and covers the attendance aggregation's date, student, and status columns. |

For the relevant table access, a typical large-data plan would look roughly like this:

| Query | Before: `type` / `key` / `rows` | After: `type` / `key` / `rows` |
|---|---|---|
| 3 | Enrollment: `ALL` / `NULL` / about all enrollments | Enrollment: `ref` / `ix_enrollment_term_class_student` / about enrollments in the selected term |
| 5 | Enrollment: `ALL` / `NULL` / about all enrollments | Enrollment: `ref` / `ix_enrollment_term_class_student` / about enrollments in the selected term |
| 7 | Attendance: `ALL` / `NULL` / about all attendance rows | Attendance: `range` / `ix_attendance_date_student_status` / about attendance rows in the selected date range |

These are illustrative access patterns, **not measured output or guaranteed values**: the optimizer can choose another plan (especially for small sample tables). The `rows` column is an estimate. Run the statements in `indexes.sql` on your database to see actual output. I could not execute them in this workspace because no MySQL/MariaDB client is installed to connect to a database.

## Three reports worth studying

These examples use the seeded `2026/2027 First Term`; each technique is explained in the comments directly above its SQL in [`queries.sql`](./queries.sql).

1. **Query 3 — class average and position:** groups each student's subject totals to calculate an average, then applies `RANK() OVER (PARTITION BY class_id ...)`. Partitioning restarts the ranking for every class; `RANK()` gives tied averages equal positions. A MySQL 5.7 self-join fallback is included.
2. **Query 5 — students who failed multiple subjects:** filters individual results to totals below 40, groups the remaining rows by student, and uses `HAVING COUNT(*) >= 2`. `WHERE` filters rows before grouping; `HAVING` filters the grouped counts.
3. **Query 7 — attendance below 80%:** a CTE aggregates recorded dates and attended days per student for the term. It treats both `present` and `late` as attended, then filters percentages. The date-range index helps the CTE scan only term attendance.

## Export the full database in phpMyAdmin

To download a complete SQL backup named `database.sql`:

1. Open phpMyAdmin and select **`school_db`** in the left navigation. Select the database, not an individual table.
2. Open the **Export** tab.
3. Choose **Custom** so you can verify the backup contents.
4. Select all tables and include both **structure** and **data**. Include views, triggers, and stored routines/procedures when those options are shown; this database uses triggers and stored procedures.
5. Choose **SQL** as the format. Select **Add `CREATE DATABASE` / `USE`** if the backup should recreate/select the database when restored elsewhere.
6. Leave compression disabled for a plain `.sql` download, and set the output filename to **`database.sql`** if phpMyAdmin offers that field.
7. Click **Go** and save the downloaded file as `database.sql`.

Treat the export as sensitive: it contains student and guardian information. Store and share it only in an appropriately protected location.
