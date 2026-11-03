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

### Relationships and cardinalities

- **Teacher → Class (form teacher): 1:N.** Each class has exactly one form teacher; a teacher may form-teach multiple classes unless the school enforces a one-class limit.
- **Student → Enrollment: 1:N**, **Class → Enrollment: 1:N**, and **Term → Enrollment: 1:N**. Enrollment records which class a student belongs to in each term.
- **Class, Subject, and Term → ClassSubjectOffering: 1:N each.** This resolves the **M:N relationship between classes and subjects** and records the teacher assigned to each offering. A class takes many subjects, and a subject can be taken by many classes.
- **Teacher → ClassSubjectOffering: 1:N.** Each offering has one teacher; a teacher may teach multiple offerings.
- **Enrollment → Result: 1:N** and **ClassSubjectOffering → Result: 1:N.** Together these represent the **M:N relationship between enrolled students and subject offerings**, with CA and exam scores as attributes of that relationship.
- **Student → Attendance: 1:N.** Each attendance record belongs to one student, and the composite key permits at most one record per student per day.

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
```

CA scores range from **0–40**, and exam scores from **0–60**. These are validation rules for results.

The MySQL/MariaDB implementation is in [`schema.sql`](./schema.sql), with example records in [`seed.sql`](./seed.sql) and reporting examples/views in [`queries.sql`](./queries.sql).
