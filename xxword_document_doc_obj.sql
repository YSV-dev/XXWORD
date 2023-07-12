CREATE OR REPLACE TYPE xxword_document_doc_obj FORCE UNDER xxword_document_ml_obj (
-- Author  : $OSUSER
-- Created : $DATE $TIME
-- Purpose : 

CONSTRUCTOR FUNCTION xxword_document_doc_obj(p_file_name VARCHAR2 := 'document_' || to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'), p_encoding VARCHAR2 := 'UTF-8', p_log_level NUMBER := 0) RETURN SELF AS RESULT,

MEMBER FUNCTION create_section(p_section_style xxword_section_style_obj) RETURN xxword_section_obj,

OVERRIDING MEMBER FUNCTION build_document RETURN VARCHAR2,

OVERRIDING MEMBER FUNCTION prv_write_head(l_document IN OUT CLOB) RETURN CLOB,

OVERRIDING MEMBER FUNCTION prv_write_in_doc RETURN VARCHAR2

) INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_document_doc_obj IS

	CONSTRUCTOR FUNCTION xxword_document_doc_obj(p_file_name VARCHAR2 := 'document_' ||
																																	 to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'),
																					 p_encoding  VARCHAR2 := 'UTF-8',
																					 p_log_level NUMBER := 0)
		RETURN SELF AS RESULT AS
	
	BEGIN
		self.prv_init(p_file_name, 'doc', p_encoding, p_log_level);
		RETURN;
	END;
	-- Member procedures and functions

	MEMBER FUNCTION create_section(p_section_style xxword_section_style_obj)
		RETURN xxword_section_obj AS
	BEGIN
		RETURN xxword_section_obj(p_session_id => session_id, p_section_style => p_section_style, p_log_level => SELF.LOG_LEVEL);
	END;
  
  OVERRIDING MEMBER FUNCTION prv_write_head(l_document IN OUT CLOB) RETURN CLOB AS
    l_user_full_name VARCHAR2(250);
		l_creation_date  VARCHAR2(25);
  BEGIN
    SELECT full_name
    INTO   l_user_full_name
    FROM   apps.per_all_people_f papf
    LEFT   JOIN apps.fnd_user fu
    ON     fu.employee_id = papf.person_id
    WHERE  SYSDATE BETWEEN papf.effective_start_date AND
           papf.effective_end_date
           AND fu.user_id = apps.FND_PROFILE.VALUE('USER_ID');
  
    SELECT to_char(SYSDATE, 'yyyy-MM-dd"T"HH24:MI:SS"Z"')
    INTO   l_creation_date
    FROM   dual;
    
    l_document := l_document || '<head>
  <meta http-equiv=Content-Type content="text/html; charset=' || document_encoding || '">
  <meta name=ProgId content=Word.Document>
  <meta name=Generator content="Microsoft Word 15">
  <meta name=Originator content="Microsoft Word 15">
  <link rel=File-List href="html_test.files/filelist.xml">
  <link rel=dataStoreItem href="html_test.files/item0004.xml" target="html_test.files/props005.xml">
  <link rel=themeData href="html_test.files/themedata.thmx">
  <link rel=colorSchemeMapping href="html_test.files/colorschememapping.xml">
  
  <!--[if gte mso 9]><xml>
    <o:DocumentProperties>
    <o:Author>' || l_user_full_name || '</o:Author>
    <o:LastAuthor>' || l_user_full_name || '</o:LastAuthor>
    <o:Revision>22</o:Revision>
    <o:TotalTime>2917</o:TotalTime>
    <o:Created>' || l_creation_date || '</o:Created>
    <o:LastSaved>' || l_creation_date || '</o:LastSaved>
    <o:Pages>1</o:Pages>
    <o:Characters>1</o:Characters>
    <o:Company>Uralkali</o:Company>
    <o:Lines>1</o:Lines>
    <o:Paragraphs>1</o:Paragraphs>
    <o:CharactersWithSpaces>1</o:CharactersWithSpaces>
    <o:Version>16.00</o:Version>
    </o:DocumentProperties>
    <o:OfficeDocumentSettings>
    <o:AllowPNG/>
    </o:OfficeDocumentSettings>
    </xml>
  <![endif]-->';
  
    l_document := self.prv_write_style(l_document);
  
    l_document := l_document || '</head>';
    RETURN l_document;
  END;
  
  OVERRIDING MEMBER FUNCTION prv_write_in_doc RETURN VARCHAR2 AS
    l_document CLOB;
  BEGIN
  
    BEGIN
      l_document := '<!DOCTYPE html>';
      l_document := l_document || '<html xmlns:v="urn:schemas-microsoft-com:vml"
xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns:m="http://schemas.microsoft.com/office/2004/12/omml"
xmlns="http://www.w3.org/TR/REC-html40">';
      l_document := self.prv_write_head(l_document);
      l_document := self.prv_write_elements(l_document);
      l_document := l_document || '</html>';
    
      UPDATE xxword_documents_tmp wdt
      SET    wdt.document = l_document
      WHERE  wdt.session_id = SELF.SESSION_ID;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN 'E';
    END;
    COMMIT;
    RETURN 'S';
  END;

	OVERRIDING MEMBER FUNCTION build_document RETURN VARCHAR2 AS
    l_build_result VARCHAR2(1);
	BEGIN
    
		l_build_result := self.prv_build_init;

		COMMIT;
		RETURN l_build_result;
	END;
END;
/
