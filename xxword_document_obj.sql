CREATE OR REPLACE TYPE xxword_document_obj FORCE UNDER xxword_obj
(
-- Author    YANISHEN_SV
-- Created : 10/06/2022
-- Purpose : документ word
-- Attributes

  document_encoding VARCHAR2(20),
  document_name     VARCHAR2(250),
  document_extension VARCHAR2(10),

	CONSTRUCTOR FUNCTION xxword_document_obj(p_file_name VARCHAR2 := 'document_'||to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'),
                                           p_extension VARCHAR2 := NULL,  p_encoding VARCHAR2 := 'UTF-8', p_log_level NUMBER := 0
                                           ) RETURN SELF AS RESULT,

-- Member functions and procedures
  MEMBER PROCEDURE prv_init(p_file_name VARCHAR2 := 'document_'||to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'),
                        p_extension VARCHAR2 := NULL,  p_encoding VARCHAR2 := 'UTF-8', p_log_level NUMBER := 0),
                        
  MEMBER PROCEDURE set_name(p_name VARCHAR2),
  
  MEMBER PROCEDURE set_extension(p_extension VARCHAR2),
  
  MEMBER FUNCTION prv_remove_data(p_delete_doc BOOLEAN := FALSE) RETURN VARCHAR2,
  
  MEMBER FUNCTION prv_build_init RETURN VARCHAR2,

	MEMBER FUNCTION build_document RETURN VARCHAR2

)INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_document_obj IS

	-- Member procedures and functions
	CONSTRUCTOR FUNCTION xxword_document_obj(p_file_name VARCHAR2 := 'document_'||to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'), 
                                           p_extension VARCHAR2 := NULL,
                                           p_encoding VARCHAR2 := 'UTF-8', p_log_level NUMBER := 0
                                           ) RETURN SELF AS RESULT AS
    
	BEGIN
    prv_init(p_file_name, p_extension, p_encoding, p_log_level);
    RETURN;
	END;
  
  MEMBER PROCEDURE prv_init(p_file_name VARCHAR2 := 'document_'||to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'), p_extension VARCHAR2 := NULL,
                                           p_encoding VARCHAR2 := 'UTF-8', p_log_level NUMBER := 0) IS
    l_log             VARCHAR2(50);
  BEGIN
    session_id := xxword_session_sq.nextval;
    document_encoding := p_encoding;
    document_name     := p_file_name;
    document_extension := p_extension;
    log_level         := p_log_level;
    
    --remove trash
    DELETE FROM XXWORD_DOC_PUBLIC_TMP WHERE SYSDATE - CAST(creation_date AS DATE) > 1; 
    DELETE FROM XXWORD_DOCUMENTS_TMP WHERE SYSDATE - CAST(creation_date AS DATE) > 1; 
    DELETE FROM XXWORD_ATTRIBUTES_TMP WHERE SYSDATE - CAST(creation_date AS DATE) > 1; 
    DELETE FROM XXWORD_ELEMENTS_TMP WHERE SYSDATE - CAST(creation_date AS DATE) > 1; 
    DELETE FROM XXWORD_STYLES_TMP WHERE SYSDATE - CAST(creation_date AS DATE) > 1; 
    
    --protect session from outside
    DELETE FROM XXWORD_DOC_PUBLIC_TMP wdpt WHERE wdpt.doc_session_id = self.Session_Id; 
    DELETE FROM XXWORD_DOCUMENTS_TMP wdt WHERE wdt.session_id = self.session_id; 
    DELETE FROM XXWORD_ATTRIBUTES_TMP wat WHERE wat.session_id = self.session_id; 
    DELETE FROM XXWORD_ELEMENTS_TMP wet WHERE wet.session_id = self.session_id; 
    DELETE FROM XXWORD_STYLES_TMP wst WHERE wst.session_id = self.session_id; 
    COMMIT;
	
		INSERT INTO XXWORD_DOCUMENTS_TMP (session_id, document_name, document_extension, document_encoding, log_flag, created_By) VALUES (session_id, p_file_name, document_extension, document_encoding, p_log_level, apps.FND_PROFILE.VALUE('USER_ID'));
		l_log := self.Log(p_log_level => 1, p_process_name => xxword.sys_proc_init, p_msg => 'Initialized document '||document_name||'.'||document_extension||' with encoding '||p_encoding);
  END;
  
  MEMBER PROCEDURE set_name(p_name VARCHAR2) IS
  BEGIN
    document_name := p_name;
    UPDATE XXWORD_DOCUMENTS_TMP SET document_name = p_name WHERE session_id = self.session_id;
    --COMMIT;
  END;
  
  MEMBER PROCEDURE set_extension(p_extension VARCHAR2) IS
  BEGIN
    document_extension := p_extension;
    UPDATE XXWORD_DOCUMENTS_TMP SET document_extension = p_extension WHERE session_id = self.session_id;
    --COMMIT;
  END;
  
  MEMBER FUNCTION prv_remove_data(p_delete_doc BOOLEAN := FALSE) RETURN VARCHAR2 AS
  BEGIN
    --COMMIT;
		RETURN 'S';
	END;
  
  
  MEMBER FUNCTION prv_build_init RETURN VARCHAR2 AS
	BEGIN
    --COMMIT;
		RETURN 'S';
	END;

	MEMBER FUNCTION build_document RETURN VARCHAR2 AS
	BEGIN
    --COMMIT;
		RETURN 'S';
	END;

END;
/
