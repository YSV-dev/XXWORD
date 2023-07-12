CREATE OR REPLACE TYPE xxword_publicator_obj AS OBJECT
(
-- Author    YANISHEN_SV
-- Created : 23/06/2022
-- Purpose : Тип созданный для выгрузки документов
	publicator_id NUMBER,
  pub_style     VARCHAR2(2000),
  downLoad_text VARCHAR2(150),
  print_extension NUMBER,

	CONSTRUCTOR FUNCTION xxword_publicator_obj(p_style_set VARCHAR2, p_downLoad_text VARCHAR2 := 'DOWNLOAD ', p_print_extension BOOLEAN := TRUE) RETURN SELF AS RESULT,

	MEMBER PROCEDURE add_document(p_document xxword_document_obj),

  MEMBER PROCEDURE print_document_body,

  MEMBER PROCEDURE prv_print_header,

  MEMBER PROCEDURE prv_print_footer,

  MEMBER PROCEDURE show_error(p_error_msg VARCHAR2, p_header VARCHAR2 := 'Error!'),
  
  MEMBER PROCEDURE send_email(p_from VARCHAR2 := 'prod12_noreply@uralkali.com', 
                              p_to   VARCHAR2,
                              p_subject VARCHAR2 := 'no subject',
                              p_email_text CLOB := NULL,
                              p_smtp_host VARCHAR2 := NULL,
                              p_smtp_port NUMBER   := NULL
                              ),

	MEMBER PROCEDURE publicate
)
/
CREATE OR REPLACE TYPE BODY xxword_publicator_obj IS

	CONSTRUCTOR FUNCTION xxword_publicator_obj(p_style_set VARCHAR2, p_downLoad_text VARCHAR2 := 'DOWNLOAD ', p_print_extension BOOLEAN := TRUE) RETURN SELF AS RESULT AS
	BEGIN
		publicator_id := xxword_publicator_sq.nextval;
    pub_style     := p_style_set;
    downLoad_text := p_downLoad_text;

    IF p_print_extension THEN
       print_extension := 1;
    ELSE
       print_extension := 0;
    END IF;

		RETURN;
	END;

	MEMBER PROCEDURE add_document(p_document xxword_document_obj) IS
	BEGIN
		INSERT INTO XXWORD_DOC_PUBLIC_TMP
			(publicator_id,
			 doc_session_id,
			 created_by)
		VALUES
			(SELF.publicator_id,
			 p_document.session_id,
			 apps.FND_PROFILE.VALUE('USER_ID'));
	END;


  MEMBER PROCEDURE print_document_body IS
  CURSOR document_c IS(
      SELECT dpt.doc_session_id,
             wdt.document,
             wdt.document_name,
             wdt.document_extension
      FROM   XXWORD_DOC_PUBLIC_TMP dpt
      INNER  JOIN xxword_documents_tmp wdt
      ON     wdt.session_id = dpt.doc_session_id
      WHERE  dpt.publicator_id = SELF.publicator_id);

    l_clob_length NUMBER;
    l_doc_render  CLOB;
    l_iter        NUMBER := 0;
    l_doc_cnt     NUMBER := 0;
    BUFFER_SIZE   NUMBER := 32000;
  BEGIN

    FOR doc_r IN document_c
    LOOP
      l_doc_render  := doc_r.document;
      l_clob_length := LENGTH(l_doc_render);
      l_iter        := FLOOR(l_clob_length / BUFFER_SIZE);

      IF l_iter < 1 THEN
        l_iter := 1;
      END IF;

      FOR doc_part IN 0 .. l_iter
      LOOP
        apps.fnd_file.put(apps.fnd_file.output, SUBSTR(l_doc_render, doc_part * BUFFER_SIZE, BUFFER_SIZE));
      END LOOP;
      l_doc_cnt := l_doc_cnt + 1;
    END LOOP;
  END;

  MEMBER PROCEDURE prv_print_header IS
  BEGIN
    apps.fnd_file.put(apps.fnd_file.output, '<!DOCTYPE html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=EmulateIE11" />
<meta charset="utf-8">
</head>
<style>'||pub_style||'</style>
<body>
<div class="main_window">
<div class="sub_window">
');
  END;

  MEMBER PROCEDURE prv_print_footer IS
  BEGIN
    apps.fnd_file.put(apps.fnd_file.output, '
</div>
</div>
</body>
<p class="version_text">Version: '||xxword.g_project_version||'</p>');
  END;

  MEMBER PROCEDURE show_error(p_error_msg VARCHAR2, p_header VARCHAR2 := 'Error!') IS
  BEGIN
    prv_print_header;
    apps.fnd_file.put(apps.fnd_file.output, '<div class="error_block">');
    apps.fnd_file.put(apps.fnd_file.output, '<div class="error_header_block"><h1 class="error_header">'||p_header||'</h1></div>');
    apps.fnd_file.put(apps.fnd_file.output, '<div class="error_text_block"><p class="error_text" readonly="true">'||p_error_msg||'</p></div>');
    apps.fnd_file.put(apps.fnd_file.output, '</div>');
    prv_print_footer;
  END;
  
  MEMBER PROCEDURE send_email(p_from VARCHAR2 := 'prod12_noreply@uralkali.com', 
                              p_to   VARCHAR2,
                              p_subject VARCHAR2 := 'no subject',
                              p_email_text CLOB := NULL,
                              p_smtp_host VARCHAR2 := NULL,
                              p_smtp_port NUMBER   := NULL
                              ) IS 
    CURSOR document_c IS(
      SELECT dpt.doc_session_id,
             wdt.document,
             wdt.document_name,
             wdt.document_extension
      FROM   XXWORD_DOC_PUBLIC_TMP dpt
      INNER  JOIN xxword_documents_tmp wdt
      ON     wdt.session_id = dpt.doc_session_id
      WHERE  dpt.publicator_id = SELF.publicator_id);
      
    l_mail_conn UTL_SMTP.connection;
    l_smtp_host VARCHAR2(300);
    l_smtp_port NUMBER;
    l_boundary    VARCHAR2(50) := '----=*#abc1234321cba#*=';
    
    l_clob_length NUMBER;
    l_doc_name    VARCHAR2(250);
		l_doc_render  CLOB;
    l_iter        NUMBER := 0;
    BUFFER_SIZE   NUMBER := 32000;
  BEGIN 
    SELECT nvl(p_smtp_host, xxapps.get_smtp_host),
           nvl(p_smtp_port, xxapps.get_smtp_port)
    INTO   l_smtp_host,
           l_smtp_port
    FROM dual;
  
    l_mail_conn := UTL_SMTP.open_connection(l_smtp_host, l_smtp_port);
    UTL_SMTP.helo(l_mail_conn, l_smtp_host);
    UTL_SMTP.mail(l_mail_conn, p_from);
    UTL_SMTP.rcpt(l_mail_conn, p_to);
    
    UTL_SMTP.open_data(l_mail_conn);
    
    UTL_SMTP.write_data(l_mail_conn, 'Date: '    || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: '      || p_to                                       || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'From: '    || p_from                                     || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || CONVERT (p_subject, 'UTF8')                || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Reply-To: '|| p_to                                       || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0'                                       || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed;'                          || UTL_TCP.crlf || UTL_TCP.crlf);
    
    
    IF p_email_text IS NOT NULL THEN
    -----cast_to_raw
       UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
        --UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw('Content-Type: text/html; charset="iso-8859-5"' || UTL_TCP.crlf || UTL_TCP.crlf));
        UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/html; charset="UTF8"' || UTL_TCP.crlf);

        UTL_SMTP.write_data(l_mail_conn, CONVERT(p_email_text, 'UTF8'));
        UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
    -----
    
      /*UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw('--' || l_boundary || UTL_TCP.crlf));
      UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw('Content-Type: text/html; charset="UTF8"' || UTL_TCP.crlf || UTL_TCP.crlf));

      l_doc_render  := p_email_text;
      l_clob_length := LENGTH(l_doc_render);
      l_iter        := FLOOR(l_clob_length / BUFFER_SIZE);

      IF l_iter < 1 THEN
        l_iter := 1;
      END IF;

      FOR doc_part IN 0 .. l_iter
			LOOP
				UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw(CONVERT(SUBSTR(l_doc_render, doc_part * BUFFER_SIZE, BUFFER_SIZE), 'UTF8')));
			END LOOP;
      
      UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw(UTL_TCP.crlf || UTL_TCP.crlf));*/
    END IF;
      
    FOR doc_r IN document_c
    LOOP
      l_doc_render  := doc_r.document;
			
      IF l_doc_render IS NOT NULL THEN
        l_clob_length := LENGTH(l_doc_render);
			  l_iter        := FLOOR(l_clob_length / BUFFER_SIZE);
        l_doc_name    := doc_r.document_name||'.'||doc_r.document_extension;
        UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw('--' || l_boundary || UTL_TCP.crlf));
        UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw(convert('Content-Type: text/plain; name="' || l_doc_name || '"' || UTL_TCP.crlf, 'UTF8')));
        UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw(convert('Content-Disposition: attachment; filename="' || l_doc_name || '"' || UTL_TCP.crlf || UTL_TCP.crlf, 'UTF8')));
        
        IF l_iter < 1 THEN
          l_iter := 1;
        END IF;

        FOR doc_part IN 0 .. l_iter
        LOOP
          UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw(CONVERT(SUBSTR(l_doc_render, doc_part * BUFFER_SIZE, BUFFER_SIZE), 'UTF8')));
        END LOOP;
        UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw('--' || l_boundary || '--' || UTL_TCP.crlf));
      END IF;
      
    END LOOP;
    
    UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.cast_to_raw('--' || l_boundary || '--' || UTL_TCP.crlf));
    UTL_SMTP.close_data(l_mail_conn);
    UTL_SMTP.quit(l_mail_conn);
  END;

	MEMBER PROCEDURE publicate IS
		CURSOR document_c IS(
			SELECT dpt.doc_session_id,
						 wdt.document,
						 wdt.document_name,
             wdt.document_extension
			FROM   XXWORD_DOC_PUBLIC_TMP dpt
			INNER  JOIN xxword_documents_tmp wdt
			ON     wdt.session_id = dpt.doc_session_id
			WHERE  dpt.publicator_id = SELF.publicator_id);

		l_clob_length NUMBER;
		l_doc_render  CLOB;
		l_iter        NUMBER := 0;
		l_doc_cnt     NUMBER := 0;
		BUFFER_SIZE   NUMBER := 32000;

    l_extension   VARCHAR2(10);
	BEGIN
		--скрипт скачивания документов
		prv_print_header;

		FOR doc_r IN document_c
		LOOP
			l_doc_render  := doc_r.document;
			l_clob_length := LENGTH(l_doc_render);
			l_iter        := FLOOR(l_clob_length / BUFFER_SIZE);

			apps.fnd_file.put(apps.fnd_file.output, '<div class="dockument_div" id="result_' || to_char(l_doc_cnt) || '" content="');

			IF l_iter < 1 THEN
				l_iter := 1;
			END IF;

			FOR doc_part IN 0 .. l_iter
			LOOP
				apps.fnd_file.put(apps.fnd_file.output, REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
                                                SUBSTR(l_doc_render, doc_part * BUFFER_SIZE, BUFFER_SIZE),
                                                CHR(134), '\\'), CHR(10), ' '), '"', ''''));
			END LOOP;

      IF print_extension = 1 THEN
        l_extension := '.'||doc_r.document_extension;
      ELSE
        l_extension := '';
      END IF;

			apps.fnd_file.put(apps.fnd_file.output, '
		"/>
		<button onclick="
				var text = document.getElementById(&quot;result_' || to_char(l_doc_cnt) || '&quot;);
				var blob = new Blob([text.getAttribute(&quot;content&quot;)]);
				window.navigator.msSaveOrOpenBlob(blob , &quot;' || doc_r.document_name || '.'||doc_r.document_extension||'&quot;);"
				type="button">' || downLoad_text || doc_r.document_name ||l_extension|| '</button></div>');
			l_doc_cnt := l_doc_cnt + 1;
		END LOOP;

		prv_print_footer;
	END;

END;
/
