-- 1. Iniciar sesion con el usuario hr
SELECT user AS usuario_conectado FROM dual;

SELECT sys_context('USERENV','SESSION_USER') AS session_user,
       sys_context('USERENV','CURRENT_SCHEMA') AS current_schema
FROM dual;

-- 2. Consultar los indices de employees y departments
SELECT index_name, table_name, uniqueness, status
FROM user_indexes
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER BY table_name, index_name;

-- 3. Desactivar las restricciones de employees y departments
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER BY table_name, constraint_name;

ALTER TABLE employees DISABLE CONSTRAINT emp_emp_id_pk CASCADE DROP INDEX;
ALTER TABLE departments DISABLE CONSTRAINT dept_id_pk CASCADE DROP INDEX;
ALTER TABLE employees DISABLE CONSTRAINT emp_email_uk DROP INDEX;
ALTER TABLE departments DISABLE CONSTRAINT dept_loc_fk;
ALTER TABLE departments DISABLE CONSTRAINT dept_name_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_email_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_hire_date_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees DISABLE CONSTRAINT emp_job_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_last_name_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_salary_min;

SELECT table_name, constraint_name, status
FROM user_constraints
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS', 'JOB_HISTORY')
ORDER BY table_name, constraint_name;

-- 4. Insertar tuplas que no cumplen las restricciones
INSERT INTO employees (
  employee_id, first_name, last_name, email,
  hire_date, job_id, salary, manager_id, department_id
) VALUES (
  100, 'Invalido', NULL, 'SKING',
  NULL, 'NOJOB', -50, 99999, 9999
);

INSERT INTO departments (
  department_id, department_name, manager_id, location_id
) VALUES (
  10, NULL, 99999, 9999
);

COMMIT;

SELECT employee_id, first_name, last_name, email, hire_date,
       job_id, salary, manager_id, department_id
FROM employees
WHERE employee_id = 100
ORDER BY first_name;

SELECT department_id, department_name, manager_id, location_id
FROM departments
WHERE department_id = 10;

-- 5. Volver a establecer las restricciones
ALTER TABLE employees ENABLE CONSTRAINT emp_salary_min;
ALTER TABLE employees ENABLE CONSTRAINT emp_last_name_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_hire_date_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees ENABLE CONSTRAINT emp_manager_fk;
ALTER TABLE employees ENABLE CONSTRAINT emp_emp_id_pk;
ALTER TABLE employees ENABLE CONSTRAINT emp_email_uk;
ALTER TABLE departments ENABLE CONSTRAINT dept_name_nn;
ALTER TABLE departments ENABLE CONSTRAINT dept_loc_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_id_pk;

DELETE FROM employees
WHERE employee_id = 100
  AND first_name = 'Invalido';

DELETE FROM departments
WHERE department_id = 10
  AND department_name IS NULL;

COMMIT;

SELECT COUNT(*) AS empleados_de_prueba
FROM employees
WHERE first_name = 'Invalido';

SELECT COUNT(*) AS departamentos_de_prueba
FROM departments
WHERE department_name IS NULL;

ALTER TABLE employees ENABLE CONSTRAINT emp_emp_id_pk;
ALTER TABLE employees ENABLE CONSTRAINT emp_email_uk;
ALTER TABLE employees ENABLE CONSTRAINT emp_email_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_hire_date_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_job_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_last_name_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_salary_min;
ALTER TABLE employees ENABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees ENABLE CONSTRAINT emp_manager_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_id_pk;
ALTER TABLE departments ENABLE CONSTRAINT dept_name_nn;
ALTER TABLE departments ENABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_loc_fk;
ALTER TABLE employees ENABLE CONSTRAINT emp_dept_fk;
ALTER TABLE job_history ENABLE CONSTRAINT jhist_emp_fk;
ALTER TABLE job_history ENABLE CONSTRAINT jhist_dept_fk;

SELECT table_name, constraint_name, status, validated
FROM user_constraints
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS', 'JOB_HISTORY')
ORDER BY table_name, constraint_name;

-- 6. Crear departments2
CREATE TABLE departments2 AS
SELECT * FROM departments;

-- 7. Insertar tres tuplas en departments2
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (901, 'Lab Analisis', NULL, 1700);

INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (902, 'Lab Soporte', NULL, 1700);

INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (903, 'Lab Calidad', NULL, 1800);

COMMIT;

SELECT department_id, department_name, manager_id, location_id
FROM departments2
WHERE department_id IN (901, 902, 903)
ORDER BY department_id;

-- 8. Cerrar sesion
-- Clic derecho en la conexion universidad -> Desconectar

-- 9. Consultar departments2 (tras reconectar)
SELECT department_id, department_name, manager_id, location_id
FROM departments2
WHERE department_id IN (901, 902, 903)
ORDER BY department_id;

-- 10. Bloque anonimo: inicio y fin de transaccion sobre departments2
SET SERVEROUTPUT ON;

DECLARE
  v_antes   NUMBER;
  v_despues NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== INICIO DE LA TRANSACCION ===');

  SELECT COUNT(*) INTO v_antes FROM departments2;
  DBMS_OUTPUT.PUT_LINE('Filas antes: ' || v_antes);

  DELETE FROM departments2 WHERE department_id = 904;

  INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
  VALUES (904, 'Transaccion Demo', NULL, 1700);

  UPDATE departments2
  SET department_name = 'Transaccion OK'
  WHERE department_id = 904;

  SELECT COUNT(*) INTO v_despues FROM departments2;
  DBMS_OUTPUT.PUT_LINE('Filas despues: ' || v_despues);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('=== FIN DE LA TRANSACCION (COMMIT) ===');
END;
/

-- 11. Deshacer una transaccion (ROLLBACK)
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (905, 'Prueba Rollback', NULL, 1700);

SELECT department_id, department_name
FROM departments2
WHERE department_id = 905;

ROLLBACK;

SELECT department_id, department_name
FROM departments2
WHERE department_id = 905;

-- 12. Archivos de Redo y modo ARCHIVELOG / NOARCHIVELOG
SELECT d.name AS db_name,
       d.log_mode,
       d.open_mode,
       l.group#,
       l.sequence#,
       ROUND(l.bytes/1024/1024,1) AS mb,
       l.status,
       f.member AS redo_file
FROM v$database d
CROSS JOIN v$log l
JOIN v$logfile f ON f.group# = l.group#
ORDER BY l.group#;
