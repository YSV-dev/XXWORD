CREATE OR REPLACE PACKAGE XXWORD IS

	-- Author  : YANISHEN_SV
	-- Created : 08.06.2022 8:53:52
	-- Purpose : Creating_word_reports

	g_project_version VARCHAR2(10) := 'alpha 0.1';
  g_project_version_num NUMBER := 0.1;

/*	--Строчные
	g_tag_none      VARCHAR2(1) := ''; --если есть необходимость вставить что-то без тэга
	g_tag_paragraph VARCHAR2(1) := 'p'; --параграф
	g_tag_span      VARCHAR2(4) := 'span'; --подтекст, используется в параграфах для выдления текста отдельным стилем
	--Модиффикаторы строчных
	g_tag_bold   VARCHAR2(1) := 'b'; --жирный
	g_tag_italic VARCHAR2(1) := 'i'; --курсив
	g_tag_strike VARCHAR2(1) := 's'; --перечёркнутый
	g_tag_sub    VARCHAR2(3) := 'sub'; --нижний  индекс
	g_tag_sup    VARCHAR2(3) := 'sup'; --верхний индекс 
	--Блочные
	g_tag_div VARCHAR2(3) := 'div'; --блок
	--Таблицы
	g_tag_table  VARCHAR2(5) := 'table'; --таблица
	g_tag_header VARCHAR2(2) := 'th'; --строка-заголовок
	g_tag_row    VARCHAR2(2) := 'tr'; --строка
	g_tag_col    VARCHAR2(2) := 'td'; --колонка*/

	s_q VARCHAR2(5) := '&#34;'; --"

	sys_log_info  VARCHAR2(5) := 'INFO ';
	sys_log_error VARCHAR2(5) := 'ERROR';
	sys_log_warn  VARCHAR2(5) := 'WARN ';

	sys_proc_build     VARCHAR2(5) := 'BUILD';
	sys_proc_render    VARCHAR2(6) := 'RENDER';
	sys_proc_init      VARCHAR2(4) := 'INIT';
	sys_proc_change    VARCHAR2(6) := 'CHANGE';
	sys_proc_prerender VARCHAR2(9) := 'PRERENDER';

	pub_style_l_0 VARCHAR2(2000) := '
.main_window{width: 100%; height: 90vh;}
.sub_window{position: absolute; padding: 10px; top: 50%; left: 50%; margin-right: -50%; transform: translate(-50%, -50%); background: #EEE; -webkit-box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2); -moz-box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2);box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2);}
.error_block{margin: 5px; background: white; -webkit-box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2); -moz-box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2); box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2);}
.error_header_block{background: #eb2828; color: white; width: 100%; height: 40px; display: table; box-sizing: border-box; padding-left: 10px;}
.error_header{font-size: 20px; margin-left: 10px; margin-top: auto; display: table-cell; vertical-align: middle;}
.error_text_block{padding: 5px;-webkit-box-shadow: 0px 6px 5px -5px rgba(34, 60, 80, 0.32) inset; -moz-box-shadow: 0px 6px 5px -5px rgba(34, 60, 80, 0.32) inset; box-shadow: 0px 6px 5px -5px rgba(34, 60, 80, 0.32) inset;}
.error_text{font_size: 12px; min-width: 350px;}
button{background: #fff; margin: 5px; padding: 10px 5px; border-radius: .375em; border: 1px solid #dbdbdb; transition: 0.5s; cursor: pointer;}
button:hover{border-color: #b5b5b5; color: #00a4b0;}
button:focuse{border-color: #b5b5b5; color: #00a4b0;}
button:active{border-color: #02c8d6; color: #02c8d6;}';

	pub_style_d_0 VARCHAR2(2000) := '
body {background: #171717}
.main_window {width: 100%; height: 90vh;}
.sub_window { position: absolute;padding: 10px;top: 50%;left: 50%;margin-right: -50%;transform: translate(-50%, -50%);background: #696969;}
.error_block  {margin: 5px; background: white; -webkit-box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2); -moz-box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2); box-shadow: 4px 4px 8px 0px rgba(34, 60, 80, 0.2);}
.error_header_block {background: #eb2828; color: white; width: 100%; height: 40px; display: table; box-sizing: border-box; padding-left: 10px;}
.error_header {font-size: 20px; margin-left: 10px; margin-top: auto; display: table-cell; vertical-align: middle;}
.error_text_block {padding: 5px;-webkit-box-shadow: 0px 6px 5px -5px rgba(34, 60, 80, 0.32) inset; -moz-box-shadow: 0px 6px 5px -5px rgba(34, 60, 80, 0.32) inset; box-shadow: 0px 6px 5px -5px rgba(34, 60, 80, 0.32) inset;}
.error_text   {font_size: 12px; min-width: 350px;}
button {color: white; background: #696969; margin: 5px; padding: 10px 5px; border-radius: .375em; border: 1px solid #dbdbdb; transition: 0.5s; cursor: pointer;}
button:hover  {background: #9c9c9c;}
button:focuse {background: #9c9c9c;}
button:active {background: #9c9c9c;}
version_text{color: white;}';

-------------------------------------------
        --ADMINISTRATION METHODS--
-------------------------------------------

  TYPE t_subject IS TABLE OF VARCHAR2(60);
  
  FUNCTION get_subjects RETURN t_subject;

	PROCEDURE give_grant_to(p_user VARCHAR2);
  
  PROCEDURE update_grants;

END XXWORD;
/
CREATE OR REPLACE PACKAGE BODY XXWORD IS

  FUNCTION get_subjects RETURN t_subject AS 
    l_subject_array  t_subject;
  BEGIN
    l_subject_array := t_subject('apps.xxword_document_doc_obj',
                                 'apps.xxword_document_ml_obj',
                                 'apps.xxword_document_obj',
                                 'apps.xxword_element_obj',
                                 'apps.xxword_html_elements_obj',
                                 'apps.xxword_html_table_el_obj',
                                 'apps.xxword_html_table_obj',
                                 'apps.xxword_obj',
                                 'apps.xxword_publicator_obj',
                                 'apps.xxword_section_obj',
                                 'apps.xxword_section_style_obj',
                                 'apps.xxword_style_obj',
                                 'apps.xxword'
                                );
    RETURN l_subject_array;
  END;
  
  PROCEDURE log(msg VARCHAR2) AS 
  BEGIN
    dbms_output.put_line(msg);
  END;

  PROCEDURE give_grant_to(p_user VARCHAR2) IS
    l_sql VARCHAR2(2000) := '';
    l_privileges VARCHAR2(7) := 'EXECUTE';
    l_subject_array  t_subject;
    l_sub_id PLS_INTEGER;
    
    l_cnt NUMBER;
  BEGIN
    l_subject_array := get_subjects;
    l_sub_id := l_subject_array.first();
    
    WHILE l_sub_id IS NOT NULL LOOP
      log('Try to give grant '||l_privileges||' on '||l_subject_array(l_sub_id)||' to '|| p_user);
      BEGIN
        l_sql := 'GRANT '||l_privileges||' ON '||l_subject_array(l_sub_id)||' TO '|| p_user;
        EXECUTE IMMEDIATE l_sql;
        
        SELECT COUNT(*) 
        INTO l_cnt 
        FROM APPS.XXWORD_GRANTS grt
        WHERE grt.db_user = p_user;
        
        IF l_cnt = 0 THEN
        
          INSERT INTO APPS.XXWORD_GRANTS(
            DB_USER,
            PRIVILEGES,
            PROJECT_VERSION,
            VERSION_NUMBER
          ) VALUES (
            p_user,
            l_privileges,
            g_project_version,
            g_project_version_num
          );
      ELSE
        UPDATE APPS.XXWORD_GRANTS grt SET 
        grt.privileges = l_privileges, 
        grt.project_version = g_project_version,
        grt.version_number = g_project_version_num,
        grt.update_date = SYSDATE
        WHERE grt.db_user = p_user;
      END IF;
      
      COMMIT;
      
      log('Success!');
      
      EXCEPTION
        WHEN OTHERS THEN
          log('ERROR! ['||SQLCODE||'] '||SQLERRM);
          EXIT;
      END;
      l_sub_id := l_subject_array.NEXT(l_sub_id);
    END LOOP;
  END;
  
  PROCEDURE update_grants IS
    CURSOR users IS SELECT db_user FROM APPS.XXWORD_GRANTS grt;
  BEGIN
    FOR user_r IN users 
    LOOP
      give_grant_to(user_r.db_user);
    END LOOP;
  END;
  
END XXWORD;
/
