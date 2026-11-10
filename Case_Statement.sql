
CREATE DATABASE college_db;

USE college_db;

CREATE TABLE IF NOT EXISTS student(
    s_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    score FLOAT(5,2)
);

INSERT INTO student VALUE(NULL, "Leyla", "Garcia", 42);
INSERT INTO student VALUE(NULL, "David", "Freitas", 99);
INSERT INTO student VALUE(NULL, "Eli", "Jarvis", 75);

SELECT * FROM student;


-- alter table student add grade char(1);
-- insert into student value(null, "Martin", "Fernandez", 81,null);

CREATE PROCEDURE IF NOT EXISTS update_student_grade(IN p_id INT)
BEGIN
    UPDATE student
    SET grade = CASE
        WHEN score >= 90 THEN 'A'
        WHEN score >= 80 THEN 'B'
        WHEN score >= 70 THEN 'C'
        WHEN score >= 60 THEN 'D'
        ELSE 'F'
    END
    WHERE s_id = p_id;
END;

CALL update_student_grade(2);
SELECT * FROM student;



