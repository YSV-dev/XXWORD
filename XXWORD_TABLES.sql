DECLARE
	v_dummy   NUMBER;
	sql_stmt_ VARCHAR2(2000);
BEGIN

	BEGIN
		SELECT 1
		INTO   V_DUMMY
		FROM   ALL_SEQUENCES
		WHERE  SEQUENCE_OWNER = 'APPS'
					 AND SEQUENCE_NAME = 'XXWORD_SESSION_SQ';
		IF V_DUMMY = 1 THEN
			DBMS_OUTPUT.PUT_LINE('��������� ����������.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			SQL_STMT_ := '
				CREATE SEQUENCE APPS.XXWORD_SESSION_SQ
					INCREMENT BY 1
					START WITH 1
					MINVALUE 1
					MAXVALUE 99999999999
					NOCYCLE
					NOORDER
					NOCACHE
			';
			EXECUTE IMMEDIATE SQL_STMT_;
			DBMS_OUTPUT.PUT_LINE('��������� �������.');
	END;
END;
/

DECLARE
	v_dummy   NUMBER;
	sql_stmt_ VARCHAR2(2000);
BEGIN
	BEGIN
		SELECT 1
		INTO   V_DUMMY
		FROM   ALL_SEQUENCES
		WHERE  SEQUENCE_OWNER = 'APPS'
					 AND SEQUENCE_NAME = 'XXWORD_PUBLICATOR_SQ';
		IF V_DUMMY = 1 THEN
			DBMS_OUTPUT.PUT_LINE('��������� ����������.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			SQL_STMT_ := '
					CREATE SEQUENCE APPS.XXWORD_PUBLICATOR_SQ
						INCREMENT BY 1
						START WITH 1
						MINVALUE 1
						MAXVALUE 99999999999
						NOCYCLE
						NOORDER
						NOCACHE
				';
			EXECUTE IMMEDIATE SQL_STMT_;
			DBMS_OUTPUT.PUT_LINE('��������� �������.');
			dbms_output.put_line(sql_stmt_);
	END;
END;
/

DECLARE
	v_dummy   NUMBER;
	sql_stmt_ VARCHAR2(2000);
BEGIN
	BEGIN
		SELECT 1
		INTO   v_dummy
		FROM   all_tables
		WHERE  OWNER = 'APPS'
					 AND table_name = 'XXWORD_STYLES_TMP';
    IF V_DUMMY = 1 THEN
			DBMS_OUTPUT.PUT_LINE('������� ����������.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			sql_stmt_ := '
CREATE TABLE apps.XXWORD_STYLES_TMP 
(
 session_id    NUMBER NOT NULL,
 style_prefix  VARCHAR2(50),
 style_name    VARCHAR2(150) NOT NULL,
 attribute     VARCHAR2(150),
 value         VARCHAR2(250),
 order_by      NUMBER,
 creation_date TIMESTAMP DEFAULT SYSDATE
)';
			dbms_output.put_line('������� �������');
			EXECUTE IMMEDIATE sql_stmt_;
      
	END;
END;
/
COMMENT ON TABLE XXWORD_STYLES_TMP IS '��������� ������� ������';

COMMENT ON COLUMN XXWORD_STYLES_TMP.session_id IS '����� ������';
COMMENT ON COLUMN XXWORD_STYLES_TMP.style_prefix IS '������� ����� (��� �� ������ ��� id, class, style)';
COMMENT ON COLUMN XXWORD_STYLES_TMP.style_name IS '��� �����';
COMMENT ON COLUMN XXWORD_STYLES_TMP.attribute IS '������� �����';
COMMENT ON COLUMN XXWORD_STYLES_TMP.value IS '��������';
COMMENT ON COLUMN XXWORD_STYLES_TMP.order_by IS '����������';
/

DECLARE
	v_dummy   NUMBER;
	sql_stmt_ VARCHAR2(2000);
BEGIN
	BEGIN
		SELECT 1
		INTO   v_dummy
		FROM   all_tables
		WHERE  OWNER = 'APPS'
					 AND table_name = 'XXWORD_ELEMENTS_TMP';
    IF V_DUMMY = 1 THEN
			DBMS_OUTPUT.PUT_LINE('������� ����������.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			sql_stmt_ := '
CREATE TABLE apps.XXWORD_ELEMENTS_TMP 
(
 session_id    NUMBER NOT NULL,
 element_id    NUMBER NOT NULL,
 parent_id     NUMBER NOT NULL, 
 parent_order  NUMBER,
 content       CLOB,
 style         VARCHAR2(2000),
 class_name    VARCHAR2(100),
 tag           VARCHAR2(50),
 id            VARCHAR2(100),
 render        CLOB,
 creation_date TIMESTAMP DEFAULT SYSDATE
)';
			dbms_output.put_line('������� �������');
			EXECUTE IMMEDIATE sql_stmt_;
      
	END;
END;
/
COMMENT ON TABLE XXWORD_ELEMENTS_TMP IS '��������� ������� ��������� ����������';

COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.session_id IS '����� ������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.element_id IS '����� ��������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.parent_id IS  '����� �������� ��������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.parent_order IS  '���������� ��������� � ��������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.content IS  '���������� �������� (�����)';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.style IS  '����� ��������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.class_name IS  '����� ��������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.tag IS  '��� ��������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.id IS  'id �������� � HTML ��������';
COMMENT ON COLUMN XXWORD_ELEMENTS_TMP.render IS  '������ ���������';
/

DECLARE
	v_dummy   NUMBER;
	sql_stmt_ VARCHAR2(2000);
BEGIN
	BEGIN
		SELECT 1
		INTO   v_dummy
		FROM   all_tables
		WHERE  OWNER = 'APPS'
					 AND table_name = 'XXWORD_ATTRIBUTES_TMP';
    IF V_DUMMY = 1 THEN
			DBMS_OUTPUT.PUT_LINE('������� ����������.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			sql_stmt_ := '
CREATE TABLE APPS.XXWORD_ATTRIBUTES_TMP 
(
 session_id    NUMBER NOT NULL,
 element_id    NUMBER NOT NULL,
 attribute     VARCHAR2(64),
 value         VARCHAR2(256),
 creation_date TIMESTAMP DEFAULT SYSDATE
)';
			dbms_output.put_line('������� �������');
			EXECUTE IMMEDIATE sql_stmt_;
	END;
END;
/
COMMENT ON TABLE XXWORD_ATTRIBUTES_TMP IS '��������� ������� ��������� ����������';

COMMENT ON COLUMN XXWORD_ATTRIBUTES_TMP.session_id IS '����� ������';
COMMENT ON COLUMN XXWORD_ATTRIBUTES_TMP.element_id IS '����� ��������';
COMMENT ON COLUMN XXWORD_ATTRIBUTES_TMP.attribute IS  '������� ��������';
COMMENT ON COLUMN XXWORD_ATTRIBUTES_TMP.value IS  '�������� ��������';
/

DECLARE
	v_dummy   NUMBER;
	sql_stmt_ VARCHAR2(2000);
BEGIN
	BEGIN
		SELECT 1
		INTO   v_dummy
		FROM   all_tables
		WHERE  OWNER = 'APPS'
					 AND table_name = 'XXWORD_DOCUMENTS_TMP';
    IF V_DUMMY = 1 THEN
			DBMS_OUTPUT.PUT_LINE('������� ����������.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			sql_stmt_ := '
CREATE TABLE apps.XXWORD_DOCUMENTS_TMP
(
 session_id      NUMBER NOT NULL,
 document_name   VARCHAR2(250),
 document_extension VARCHAR2(10),
 document        CLOB,
 document_encoding        VARCHAR2(20),
 log_flag                 NUMBER DEFAULT 0,
 creation_date   TIMESTAMP DEFAULT SYSDATE,
 created_by      NUMBER
)';
			dbms_output.put_line('������� �������');
			EXECUTE IMMEDIATE sql_stmt_;
	END;
END;
/
COMMENT ON TABLE XXWORD_DOCUMENTS_TMP IS '��������� ������� ����������';

COMMENT ON COLUMN XXWORD_DOCUMENTS_TMP.session_id IS '����� ������';
COMMENT ON COLUMN XXWORD_DOCUMENTS_TMP.document_name IS '��� ���������';
COMMENT ON COLUMN XXWORD_DOCUMENTS_TMP.document_extension IS '���������� � ������� ����� ������ ��������';
COMMENT ON COLUMN XXWORD_DOCUMENTS_TMP.document IS '���� ���������';
COMMENT ON COLUMN XXWORD_DOCUMENTS_TMP.document_encoding IS '��������� ���������';
COMMENT ON COLUMN XXWORD_DOCUMENTS_TMP.creation_date IS '���� ��������';
COMMENT ON COLUMN XXWORD_DOCUMENTS_TMP.created_by IS '�����';
/

DECLARE
	v_dummy   NUMBER;
	sql_stmt_ VARCHAR2(2000);
BEGIN
	BEGIN
		SELECT 1
		INTO   v_dummy
		FROM   all_tables
		WHERE  OWNER = 'APPS'
					 AND table_name = 'XXWORD_DOC_PUBLIC_TMP';
    IF V_DUMMY = 1 THEN
			DBMS_OUTPUT.PUT_LINE('������� ����������.');
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			sql_stmt_ := '
CREATE TABLE apps.XXWORD_DOC_PUBLIC_TMP
(
 publicator_id  NUMBER NOT NULL,
 doc_session_id NUMBER NOT NULL,
 creation_date  TIMESTAMP DEFAULT SYSDATE,
 created_by     NUMBER DEFAULT -1
)';
			dbms_output.put_line('������� �������');
			EXECUTE IMMEDIATE sql_stmt_;
	END;
END;
/
COMMENT ON TABLE XXWORD_DOC_PUBLIC_TMP IS '��������� ������� ���������';

COMMENT ON COLUMN XXWORD_DOC_PUBLIC_TMP.publicator_id IS '����� ��������';
COMMENT ON COLUMN XXWORD_DOC_PUBLIC_TMP.doc_session_id IS '����� ������ ���������';
COMMENT ON COLUMN XXWORD_DOC_PUBLIC_TMP.creation_date IS '���� �������� �����������';
COMMENT ON COLUMN XXWORD_DOC_PUBLIC_TMP.created_by IS '��� ������';
/

DECLARE
  v_dummy   NUMBER;
  sql_stmt_ VARCHAR2(2000);
BEGIN
  BEGIN
    SELECT 1
    INTO   v_dummy
    FROM   all_tables
    WHERE  OWNER = 'APPS'
           AND table_name = 'XXWORD_GRANTS';
    IF V_DUMMY = 1 THEN
      DBMS_OUTPUT.PUT_LINE('������� ����������.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      sql_stmt_ := '
CREATE TABLE apps.XXWORD_GRANTS
(
 DB_USER         VARCHAR2(25) NOT NULL,
 PRIVILEGES      VARCHAR2(150) NOT NULL,
 PROJECT_VERSION VARCHAR2(100) NOT NULL,
 VERSION_NUMBER  NUMBER NOT NULL,
 CREATION_DATE   TIMESTAMP DEFAULT SYSDATE,
 UPDATE_DATE     TIMESTAMP DEFAULT SYSDATE
)';
      dbms_output.put_line('������� �������');
      EXECUTE IMMEDIATE sql_stmt_;
  END;
END;
/
COMMENT ON TABLE XXWORD_GRANTS IS '������� ������ ��� ������ ������� ��� ����������';

COMMENT ON COLUMN XXWORD_GRANTS.DB_USER IS '������������ � ��';
COMMENT ON COLUMN XXWORD_GRANTS.PRIVILEGES IS '����������';
COMMENT ON COLUMN XXWORD_GRANTS.PROJECT_VERSION IS '��������� ������ �������';
COMMENT ON COLUMN XXWORD_GRANTS.VERSION_NUMBER IS '����� ������ �������';
COMMENT ON COLUMN XXWORD_GRANTS.CREATION_DATE IS '���� ������';
COMMENT ON COLUMN XXWORD_GRANTS.UPDATE_DATE IS '���� ���������� ������';
/


