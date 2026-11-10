/* ==========================================================================
   lab5h_starter.sql
   CIS 4720 Database Management and SQL
   In Class Lab 5h, Variables and Decisions

   WHAT THIS FILE IS
   Lab 5g finished, plus a numbered heading for every step of Lab 5h waiting
   to be filled in. Starting from this file means it does not matter how
   Lab 5g went. Everyone begins from the same place.

   WHAT IT ALREADY BUILDS
     1. students, test_scores, attendance, the student_scores view
     2. The calculate_gpa function and the two Lab 5e triggers
     3. The Lab 5f procedures: list_students, student_report, scores_for_test
     4. The Lab 5g procedures: add_score, record_attendance, remove_score,
        and every call you made in Lab 5g that worked

   HOW TO RUN IT
   One statement at a time. Put the cursor on it and press Ctrl + E twice.
   Anything that runs from CREATE down to END (a function, a trigger or a
   procedure) is ONE statement, however many semicolons are inside it.
   Select the whole block and run the selection. No DELIMITER lines.

   LABELING AND COMMENTING IS REQUIRED
   Above every statement you write, put a short comment in your own words
   saying what it does. The comments are graded.

   SESSION VARIABLES (the ones that start with @)
   A session variable lasts only as long as your connection. When a step
   has a CALL followed by SELECT @something, select BOTH lines and run them
   together as one selection, so they are sure to use the same connection.
   ========================================================================== */


-- =================================================================
-- SETUP. Run these three first, one at a time, while you are still
-- connected to information_schema.
-- =================================================================

-- every schema on this server. cis_students_db will not be in the list yet.
show databases;

-- make yours. IF NOT EXISTS means it is safe to run twice.
create database if not exists cis_students_db;

-- switch into it, so everything below lands in the right place.
use cis_students_db;


-- ==================================================================
-- FROM LAB 5D. students. student_id is a surrogate key the server fills in.
-- ==================================================================
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(40) NOT NULL,
    last_name  VARCHAR(40) NOT NULL,
    gpa        FLOAT(4,2)
);
INSERT INTO students VALUES (NULL,'Jenna','Wilson',NULL);
INSERT INTO students VALUES (NULL,'Robert','Reese',NULL);
INSERT INTO students VALUES (NULL,'Maria Elena','Jimenez',NULL);
INSERT INTO students VALUES (NULL,'Inder','Singh',NULL);
INSERT INTO students (first_name,last_name) VALUES ('Rita','Nunez');
INSERT INTO students (first_name,last_name) VALUES ('James','Toor');

-- ==================================================================
-- James was student 6. Deleting him is why the counter says 7.
-- ==================================================================
DELETE FROM students WHERE first_name = 'James' AND last_name = 'Toor';

-- ==================================================================
-- FROM LAB 5D. test_scores, linked to students by a foreign key.
-- ==================================================================
CREATE TABLE test_scores (
    test_score_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name     VARCHAR(20) NOT NULL,
    student_id    INT NOT NULL,
    score         FLOAT,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);
INSERT INTO test_scores VALUES (NULL,'quiz1',1,90),(NULL,'quiz1',2,85),(NULL,'quiz1',3,95),
 (NULL,'quiz2',1,80),(NULL,'quiz2',2,72),(NULL,'quiz2',3,88),(NULL,'quiz2',4,91),
 (NULL,'quiz3',2,95),(NULL,'quiz3',3,94),(NULL,'quiz3',4,74);

-- ==================================================================
-- FROM LAB 5D. The student_scores view.
-- ==================================================================
CREATE VIEW student_scores AS
SELECT s.student_id,
       CONCAT(s.first_name, ' ', s.last_name) AS student_name,
       t.test_name,
       t.score
FROM students s
LEFT OUTER JOIN test_scores t ON s.student_id = t.student_id;

-- ==================================================================
-- FROM LAB 5D. The calculate_gpa function. Select the whole block from
-- CREATE FUNCTION down to END and run the selection.
-- ==================================================================
CREATE FUNCTION calculate_gpa(p_student_id INT)
RETURNS DECIMAL(4,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gpa DECIMAL(4,2);

    SELECT ROUND(AVG(score), 2)
    INTO v_gpa
    FROM test_scores
    WHERE student_id = p_student_id
      AND score IS NOT NULL;

    RETURN IFNULL(v_gpa, 0.00);
END;

-- ==================================================================
-- Fill in every gpa using the function.
-- ==================================================================
UPDATE students SET gpa = calculate_gpa(student_id);

-- ==================================================================
-- FROM LAB 5E. attendance, with its surrogate key starting at 500.
-- ==================================================================
CREATE TABLE attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id    INT NOT NULL,
    attended_on   DATE,
    status        VARCHAR(10),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
) AUTO_INCREMENT = 500;
INSERT INTO attendance (student_id, attended_on, status) VALUES (1,'2026-10-05','present');
INSERT INTO attendance (student_id, attended_on, status) VALUES (2,'2026-10-05','absent');
INSERT INTO attendance (student_id, attended_on, status) VALUES (3,'2026-10-06','present');

-- ==================================================================
-- FROM LAB 5E. The BEFORE INSERT trigger. Select the whole block and run the selection.
-- ==================================================================
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    IF NEW.attended_on IS NULL THEN
        SET NEW.attended_on = CURDATE();
    END IF;
    SET NEW.status = UPPER(NEW.status);
END;

-- ==================================================================
-- FROM LAB 5E. The AFTER DELETE trigger. Select the whole block and run the selection.
-- ==================================================================
CREATE TRIGGER trg_scores_after_delete
AFTER DELETE ON test_scores
FOR EACH ROW
BEGIN
    UPDATE students
    SET gpa = calculate_gpa(OLD.student_id)
    WHERE student_id = OLD.student_id;
END;

-- ==================================================================
-- FROM LAB 5E Step 9. The row the BEFORE trigger filled in. It becomes 503.
-- ==================================================================
INSERT INTO attendance (student_id, status) VALUES (4,'present');

-- ==================================================================
-- FROM LAB 5F Step 6. list_students, highest gpa first.
-- ==================================================================
CREATE PROCEDURE list_students()
BEGIN
    SELECT student_id, first_name, last_name, gpa
    FROM students
    ORDER BY gpa DESC;
END;

-- ==================================================================
-- FROM LAB 5F Step 4. student_report.
-- ==================================================================
CREATE PROCEDURE student_report(IN p_student_id INT)
BEGIN
    SELECT student_name, test_name, score
    FROM student_scores
    WHERE student_id = p_student_id;
END;

-- ==================================================================
-- FROM LAB 5F Step 7. scores_for_test.
-- ==================================================================
CREATE PROCEDURE scores_for_test(IN p_test_name VARCHAR(20))
BEGIN
    SELECT student_name, score
    FROM student_scores
    WHERE test_name = p_test_name
    ORDER BY score DESC;
END;

-- ==================================================================
-- FROM LAB 5G Step 3. add_score. Select the whole block.
-- ==================================================================
CREATE PROCEDURE add_score(IN p_test_name VARCHAR(20),
                           IN p_student_id INT,
                           IN p_score FLOAT)
BEGIN
    INSERT INTO test_scores (test_name, student_id, score)
    VALUES (p_test_name, p_student_id, p_score);

    UPDATE students
    SET gpa = calculate_gpa(p_student_id)
    WHERE student_id = p_student_id;
END;

-- ==================================================================
-- FROM LAB 5G Step 4. Rita's first score and Jenna's quiz4.
-- ==================================================================
CALL add_score('quiz4', 5, 88);
CALL add_score('quiz4', 1, 100);

-- ==================================================================
-- FROM LAB 5G Step 5. record_attendance. Select the whole block.
-- ==================================================================
CREATE PROCEDURE record_attendance(IN p_student_id INT,
                                   IN p_status VARCHAR(10))
BEGIN
    INSERT INTO attendance (student_id, status)
    VALUES (p_student_id, p_status);
END;

-- ==================================================================
-- FROM LAB 5G Step 6. Becomes attendance row 504.
-- ==================================================================
CALL record_attendance(2, 'absent');

-- ==================================================================
-- FROM LAB 5G Step 7. remove_score. Select the whole block.
-- ==================================================================
CREATE PROCEDURE remove_score(IN p_student_id INT,
                              IN p_test_name VARCHAR(20))
BEGIN
    DELETE FROM test_scores
    WHERE student_id = p_student_id
      AND test_name = p_test_name;
END;

-- ==================================================================
-- FROM LAB 5G Step 8. Jenna back to 85.00.
-- ==================================================================
CALL remove_score(1, 'quiz4');

-- ==================================================================
-- FROM LAB 5G Step 9. The minus 20 that got in, and the cleanup.
-- ==================================================================
CALL add_score('quiz5', 4, -20);
CALL remove_score(4, 'quiz5');


-- ======================================================================
-- CHECKS. These only read, so they are safe to run again any time.
-- Highest gpa first: 92.33, 88.00, 85.00, 84.00, 82.50.
-- attendance should show ids 500 to 504.
-- ======================================================================

CALL list_students();
SELECT * FROM attendance;


-- ######################################################################
-- YOUR LAB 5H WORK STARTS BELOW THIS LINE
--
-- LABELING AND COMMENTING IS REQUIRED. It is worth a full point.
--
-- You write Steps 4, 7 and 10 yourself. Steps 6, 8 and 9 are skeletons
-- with gaps for you to fill. Steps 3 and 5 are printed in the handout.
-- ######################################################################


-- =================================================================
-- STEP 3. Session variables
--
-- Copy these from the handout and run them.
-- =================================================================

-- Create a session variable with the passing score.
SET @passing = 80;

-- Display the passing score.
SELECT @passing;

-- Find students who scored below 80.
SELECT student_name, test_name, score
FROM student_scores
WHERE score < @passing;

-- Show what happens when a variable has not been set.
SELECT @never_set;

-- Count the total number of students.
SELECT COUNT(*) INTO @how_many FROM students;

-- Display the total number of students.
SELECT @how_many;


-- =================================================================
-- STEP 4. Session variables on your own
-- =================================================================

-- Find the highest score on quiz3 and store it in @top.
SELECT MAX(score) INTO @top
FROM test_scores
WHERE test_name = 'quiz3';

-- Display the highest quiz3 score.
SELECT @top;

-- Store quiz3 in a session variable.
SET @test = 'quiz3';

-- Show all scores for the test stored in @test.
CALL scores_for_test(@test);

-- Store student ID 3 in a session variable.
SET @who = 3;

-- Display the report for student 3.
CALL student_report(@who);


-- =================================================================
-- STEP 5. Local variables, class_stats
--
-- Copy this one from the handout. Then try the SELECT that fails.
-- =================================================================

-- Create a procedure to calculate class statistics.
CREATE PROCEDURE class_stats()
BEGIN
    -- Create local variables to store class information.
    DECLARE v_students INT DEFAULT 0;
    DECLARE v_scores INT DEFAULT 0;
    DECLARE v_average DECIMAL(5,2);

    -- Count the total number of students.
    SELECT COUNT(*) INTO v_students FROM students;

    -- Calculate the total scores and average score.
    SELECT COUNT(*), ROUND(AVG(score), 2)
    INTO v_scores, v_average
    FROM test_scores;

    -- Display the class statistics.
    SELECT v_students AS students,
           v_scores AS scores,
           v_average AS class_average;
END;

-- Display the class statistics.
CALL class_stats();
-- Test whether a local variable can be used outside its procedure.
SELECT v_students;
x-- ERROR 1054 is expected because v_students is a local variable
-- and cannot be accessed outside the class_stats procedure.

-- =================================================================
-- STEP 6. An OUT parameter, count_scores
--
-- Copy the skeleton and write the SELECT ... INTO.
-- =================================================================

-- Create a procedure to count a student's test scores.
CREATE PROCEDURE count_scores(IN p_student_id INT, OUT p_count INT)
BEGIN
    -- Count the student's scores and store the result.
    SELECT COUNT(*) INTO p_count
    FROM test_scores
    WHERE student_id = p_student_id;
END;
-- Count the scores for student 3.
CALL count_scores(3, @n);
SELECT @n;

-- Count the scores for student 5.
CALL count_scores(5, @n);
SELECT @n;

-- Count the scores for student 9.
CALL count_scores(9, @n);
SELECT @n;
-- Test what happens when an OUT parameter is not a variable.
CALL count_scores(3, 5);
-- ERROR 1414 is expected because an OUT parameter
-- needs a variable to store the returned value.
-- =================================================================
-- STEP 7. When a local variable is too small
--
-- Most of this step is yours. Put each error number in a comment.
-- =================================================================
-- Add Ana Lopez as a new student.
INSERT INTO students (first_name, last_name)
VALUES ('Ana', 'Lopez');
-- Give Ana a score of 100 on quiz1.
CALL add_score('quiz1', 7, 100);
-- Check if Ana's score was saved.
SELECT * FROM test_scores
WHERE student_id = 7;

-- Check Ana's current GPA.
SELECT * FROM students
WHERE student_id = 7;
-- Delete the old calculate_gpa function.
DROP FUNCTION calculate_gpa;
-- Recreate calculate_gpa with a larger decimal type.
CREATE FUNCTION calculate_gpa(p_student_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gpa DECIMAL(5,2);

    SELECT ROUND(AVG(score), 2)
    INTO v_gpa
    FROM test_scores
    WHERE student_id = p_student_id
      AND score IS NOT NULL;

    RETURN IFNULL(v_gpa, 0.00);
END;
-- Try to update Ana's GPA using the corrected function.
UPDATE students
SET gpa = calculate_gpa(7)
WHERE student_id = 7;
--ERROR 1264: Out of range value for column 'gpa'
-- Change the GPA column to allow 100.00.
ALTER TABLE students
MODIFY gpa DECIMAL(5,2);
-- Update Ana's GPA after fixing the column.
UPDATE students
SET gpa = calculate_gpa(7)
WHERE student_id = 7;
-- Display all students ordered by GPA.
CALL list_students();
-- ERROR 1264 occurred because the original gpa column
-- could not store a value of 100.00.
-- =================================================================
-- STEP 8. IF, ELSEIF and ELSE, student_standing
--
-- Copy the skeleton and write the IF block.
-- =================================================================

-- Create a procedure to determine a student's academic standing.
CREATE PROCEDURE student_standing(
    IN p_student_id INT,
    OUT p_standing VARCHAR(20)
)
BEGIN
    -- Store the student's GPA in a local variable.
    DECLARE v_gpa DECIMAL(5,2);

    -- Find the GPA for the selected student.
    SELECT gpa INTO v_gpa
    FROM students
    WHERE student_id = p_student_id;

    -- Determine the student's standing based on GPA.
    IF v_gpa IS NULL THEN
        SET p_standing = 'No such student';
    ELSEIF v_gpa >= 90 THEN
        SET p_standing = 'Honors';
    ELSEIF v_gpa >= 85 THEN
        SET p_standing = 'Good standing';
    ELSE
        SET p_standing = 'Needs support';
    END IF;
END;
-- Check Ana Lopez's academic standing.
CALL student_standing(7, @standing);
SELECT @standing;

-- Check Maria Elena Jimenez's academic standing.
CALL student_standing(3, @standing);
SELECT @standing;

-- Check Jenna Wilson's academic standing.
CALL student_standing(1, @standing);
SELECT @standing;

-- Check Inder Singh's academic standing.
CALL student_standing(4, @standing);
SELECT @standing;

-- Check a student ID that does not exist.
CALL student_standing(9, @standing);
SELECT @standing;

-- =================================================================
-- STEP 9. Rebuild add_score so it checks the score
--
-- Write the DROP. Copy the skeleton and fill the two gaps.
-- =================================================================
-- Remove the old add_score procedure.
DROP PROCEDURE add_score;
-- Create a procedure that only accepts scores from 0 to 100.
CREATE PROCEDURE add_score(
    IN p_test_name VARCHAR(20),
    IN p_student_id INT,
    IN p_score FLOAT
)
BEGIN
    -- Check whether the score is outside the allowed range.
    IF p_score < 0 OR p_score > 100 THEN

        -- Show a message when the score is invalid.
        SELECT 'Score must be between 0 and 100' AS message;

    ELSE

        -- Insert the valid score into the test_scores table.
        INSERT INTO test_scores (test_name, student_id, score)
        VALUES (p_test_name, p_student_id, p_score);

        -- Update the student's GPA after adding the score.
        UPDATE students
        SET gpa = calculate_gpa(p_student_id)
        WHERE student_id = p_student_id;

    END IF;
END;
-- Test an invalid negative score.
CALL add_score('quiz5', 4, -20);

-- Test a score greater than 100.
CALL add_score('quiz5', 4, 120);

-- Test a valid score of 91 for Robert Reese.
CALL add_score('quiz5', 2, 91);
-- Check that invalid quiz5 scores were not saved.
SELECT * FROM test_scores
WHERE student_id = 4
AND test_name = 'quiz5';

-- Check Robert Reese's updated GPA.
SELECT student_id, first_name, last_name, gpa
FROM students
WHERE student_id = 2;
-- =================================================================
-- STEP 10. Rebuild record_attendance so it checks the student
--
-- Yours from start to finish. The handout walks you through it.
-- =================================================================

-- Remove the old record_attendance procedure.
DROP PROCEDURE record_attendance;
-- Create a procedure to record attendance for existing students.
CREATE PROCEDURE record_attendance(
    IN p_student_id INT,
    IN p_status VARCHAR(10)
)
BEGIN
    -- Create a variable to check whether the student exists.
    DECLARE v_found INT DEFAULT 0;

    -- Count students matching the given student ID.
    SELECT COUNT(*) INTO v_found
    FROM students
    WHERE student_id = p_student_id;

    -- Check whether the student exists.
    IF v_found = 0 THEN

        -- Display a message if the student does not exist.
        SELECT 'No such student' AS message;

    ELSE

        -- Record attendance for an existing student.
        INSERT INTO attendance (student_id, status)
        VALUES (p_student_id, p_status);

    END IF;
END;
-- Try to record attendance for student 9, who does not exist.
CALL record_attendance(9, 'present');

-- Record student 3 as late.
CALL record_attendance(3, 'late');

-- Display all attendance records.
SELECT * FROM attendance;
-- =================================================================
-- STEP 11 and 12. Push to GitHub and submit the URL
--
-- Nothing to write here. Follow the handout.
-- =================================================================

-- your comment goes here
-- your statements go here
