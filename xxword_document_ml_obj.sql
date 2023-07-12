CREATE OR REPLACE TYPE xxword_document_ml_obj FORCE UNDER xxword_document_obj
(
-- Author  : $OSUSER
-- Created : $DATE $TIME
-- Purpose : 

	CONSTRUCTOR FUNCTION xxword_document_ml_obj(p_file_name VARCHAR2 := 'document_' ||
																																			to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'),
																							p_encoding  VARCHAR2 := 'UTF-8',
																							p_log_level NUMBER := 0)
		RETURN SELF AS RESULT,

	MEMBER FUNCTION create_style_class(p_prefix VARCHAR2 := '.',
																		 p_name   VARCHAR2 := NULL)
		RETURN xxword_style_obj,
    
  MEMBER FUNCTION create_empty_style_class(p_prefix VARCHAR2 := '.',
                                           p_name   VARCHAR2 := NULL)
    RETURN xxword_style_obj,

	MEMBER FUNCTION prv_get_max_level(p_element NUMBER := 0) RETURN NUMBER,

	OVERRIDING MEMBER FUNCTION prv_remove_data(p_delete_doc BOOLEAN := FALSE)
		RETURN VARCHAR2,

	OVERRIDING MEMBER FUNCTION prv_build_init RETURN VARCHAR2,

	MEMBER FUNCTION prv_write_style(l_document IN OUT CLOB) RETURN CLOB,

	MEMBER FUNCTION prv_write_head(l_document IN OUT CLOB) RETURN CLOB,

	MEMBER FUNCTION prv_write_elements(l_document IN OUT CLOB) RETURN CLOB,

	MEMBER FUNCTION prv_write_in_doc RETURN VARCHAR2,

	MEMBER FUNCTION prv_render RETURN VARCHAR2

)
INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_document_ml_obj IS

	CONSTRUCTOR FUNCTION xxword_document_ml_obj(p_file_name VARCHAR2 := 'document_' ||
																																			to_char(SYSDATE, 'yyyy-MM-dd HH24:MI:SS'),
																							p_encoding  VARCHAR2 := 'UTF-8',
																							p_log_level NUMBER := 0)
		RETURN SELF AS RESULT AS
	
	BEGIN
		self.prv_init(p_file_name, 'html', p_encoding, p_log_level);
		RETURN;
	END;

	MEMBER FUNCTION create_style_class(p_prefix VARCHAR2 := '.',
																		 p_name   VARCHAR2 := NULL)
		RETURN xxword_style_obj IS
	BEGIN
		RETURN xxword_style_obj(p_session_id => session_id, p_prefix => p_prefix, p_name => p_name, p_log_level => self.Log_Level);
	END;
  
  MEMBER FUNCTION create_empty_style_class(p_prefix VARCHAR2 := '.',
                                     p_name   VARCHAR2 := NULL)
    RETURN xxword_style_obj IS
    l_class xxword_style_obj;    
  BEGIN
    l_class := xxword_style_obj(p_session_id => session_id, p_prefix => p_prefix, p_name => p_name, p_log_level => self.Log_Level);
    l_class.add_attr('','');
    RETURN l_class;
  END;

	MEMBER FUNCTION prv_get_max_level(p_element NUMBER := 0) RETURN NUMBER AS
		l_max_level NUMBER;
	BEGIN
		SELECT NVL(MAX(LEVEL), -1)
		INTO   l_max_level
		FROM   xxword_elements_tmp wet
		WHERE  wet.session_id = self.session_id
		START  WITH parent_id = p_element
		CONNECT BY PRIOR element_id = parent_id;
		RETURN l_max_level;
	END;

	OVERRIDING MEMBER FUNCTION prv_remove_data(p_delete_doc BOOLEAN := FALSE)
		RETURN VARCHAR2 AS
	BEGIN
		DELETE FROM xxword_elements_tmp wet
		WHERE  wet.session_id = self.session_id;
		DELETE FROM xxword_attributes_tmp wat
		WHERE  wat.session_id = self.session_id;
		DELETE FROM xxword_styles_tmp wst
		WHERE  wst.session_id = self.session_id;
		IF p_delete_doc THEN
			DELETE FROM xxword_documents_tmp wdt
			WHERE  wdt.session_id = self.session_id;
		END IF;
		COMMIT;
		RETURN 'S';
	END;

	OVERRIDING MEMBER FUNCTION prv_build_init RETURN VARCHAR2 AS
		l_remove_result VARCHAR2(1) := 'S';
		l_log           VARCHAR2(15);
	BEGIN
		l_log := self.Log(p_log_level => 1, p_process_name => xxword.sys_proc_build, p_msg => CHR(10) ||
																'------------------------------' ||
																CHR(10) ||
																'Build document ' ||
																document_name ||
																CHR(10) ||
																'------------------------------');
		IF substr(self.prv_render, 0, 1) != 'S' THEN
			l_remove_result := prv_remove_data(TRUE);
			RETURN 'E';
		END IF;
	
		IF substr(self.prv_write_in_doc, 0, 1) != 'S' THEN
			l_remove_result := prv_remove_data(TRUE);
			RETURN 'E';
		END IF;
	
		l_remove_result := prv_remove_data(FALSE);
	
		RETURN 'S';
	END;

	MEMBER FUNCTION prv_write_style(l_document IN OUT CLOB) RETURN CLOB AS
		CURSOR style_c IS
			SELECT css_style
			FROM   (SELECT wst.style_prefix || wst.style_name || ' {' || CHR(10) ||
										 LISTAGG('    ' || wst.attribute || ': ' || wst.value || ';', CHR(10)) WITHIN GROUP(ORDER BY wst.order_by, wst.style_prefix) over(PARTITION BY wst.style_name) || CHR(10) || '}' css_style
							FROM   xxword_styles_tmp wst
							WHERE  wst.session_id = self.session_id
										 AND wst.style_prefix != '!'
							ORDER  BY wst.style_name,
												order_by)
			GROUP  BY css_style;
	BEGIN
		l_document := l_document || '<style>';
		FOR style_r IN style_c
		LOOP
			l_document := l_document || style_r.css_style;
		END LOOP;
		l_document := l_document || '</style>';
		RETURN l_document;
	END;

	MEMBER FUNCTION prv_write_head(l_document IN OUT CLOB) RETURN CLOB AS
	BEGIN
		l_document := l_document || '<head>';
	
		l_document := self.prv_write_style(l_document);
	
		l_document := l_document || '</head>';
		RETURN l_document;
	END;

	MEMBER FUNCTION prv_write_elements(l_document IN OUT CLOB) RETURN CLOB AS
		CURSOR childs_c(p_element_id NUMBER) IS
			SELECT render
			FROM   xxword_elements_tmp wet
			WHERE  wet.session_id = self.session_id
						 AND wet.parent_id = p_element_id
			ORDER  BY wet.element_id,
								wet.parent_order;
	BEGIN
		l_document := l_document || '<body>';
	
		FOR element_r IN childs_c(0)
		LOOP
			l_document := l_document || element_r.render;
		END LOOP;
	
		l_document := l_document || '</body>';
		RETURN l_document;
	END;

	MEMBER FUNCTION prv_write_in_doc RETURN VARCHAR2 AS
		l_document CLOB;
	BEGIN
	
		BEGIN
			l_document := '<!DOCTYPE html>';
			l_document := l_document || '<html>';
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
		--COMMIT;
		RETURN 'S';
	END;

	MEMBER FUNCTION prv_render RETURN VARCHAR2 AS
		CURSOR graph_c(p_session_id NUMBER, p_level NUMBER) IS
			SELECT wet_lvl.session_id,
						 wet_lvl.lvl,
						 wet_lvl.element_id,
						 wet_lvl.parent_id,
						 wet_lvl.parent_order,
						 wet_attr.content,
						 wet_attr.tag,
						 wet_attr.id,
						 wet_attr.class_name,
						 wet_attr.style
			FROM   (SELECT DISTINCT wet.session_id,
															LEVEL lvl,
															wet.element_id,
															wet.parent_id,
															wet.parent_order
							FROM   xxword_elements_tmp wet
							WHERE  wet.session_id = p_session_id
										 AND LEVEL = p_level
							START  WITH wet.parent_id = 0
							CONNECT BY PRIOR element_id = parent_id) wet_lvl
			LEFT   JOIN (SELECT wet.session_id,
													wet.element_id,
													wet.content,
													wet.tag,
													wet.id,
													wet.class_name,
													wet.style
									 FROM   xxword_elements_tmp wet) wet_attr
			ON     wet_attr.session_id = wet_lvl.session_id
						 AND wet_attr.element_id = wet_lvl.element_id
			ORDER  BY wet_lvl.element_id,
								wet_lvl.parent_order;
	
		CURSOR childs_c(p_element_id NUMBER) IS
			SELECT render
			FROM   xxword_elements_tmp wet
			WHERE  wet.session_id = self.session_id
						 AND wet.parent_id = p_element_id
			ORDER  BY wet.element_id,
								wet.parent_order;
	
		l_log         VARCHAR2(25);
		l_log_process VARCHAR2(25);
	
		l_max_level     NUMBER;
		l_child_content CLOB;
	
		l_graph_tag         VARCHAR2(2256);
		l_graph_tag_c       VARCHAR2(32);
		l_graph_content     CLOB;
		l_graph_id          VARCHAR2(104);
		l_graph_style       VARCHAR2(2007);
		l_graph_attrs       VARCHAR2(1500);
		l_graph_style_class VARCHAR2(104);
	
		l_attrs_cnt NUMBER;
	BEGIN
		l_log_process := xxword.sys_proc_render;
		l_max_level   := self.prv_get_max_level(0);
	
		IF l_max_level = -1 THEN
			DELETE FROM xxword_elements_tmp wet
			WHERE  wet.session_id = self.session_id;
			DELETE FROM xxword_attributes_tmp wat
			WHERE  wat.session_id = self.session_id;
			DELETE FROM xxword_styles_tmp wst
			WHERE  wst.session_id = self.session_id;
			DELETE FROM xxword_documents_tmp wdt
			WHERE  wdt.session_id = self.session_id;
      COMMIT;
		
			l_log := self.Log(p_log_level => 1, p_process_name => l_log_process, p_msg => 'Document elements not found', p_prefix => xxword.sys_log_error);
		
			RAISE_APPLICATION_ERROR(-20101, 'Document elements not found');
			RETURN 'E: элементы документа не найдены!';
		END IF;
	
		BEGIN
			FOR r_level IN REVERSE 1 .. l_max_level
			LOOP
			
				l_log := self.Log(p_log_level => 2, p_process_name => l_log_process, p_msg => 'Rendering ' ||
																		to_char(l_max_level -
																						r_level + 1) ||
																		' of ' ||
																		to_char(l_max_level) ||
																		' levels.');
			
				FOR r_row IN graph_c(session_id, r_level)
				LOOP
					l_child_content := '';
					FOR r_child IN childs_c(r_row.element_id)
					LOOP
						l_child_content := l_child_content || r_child.render;
					END LOOP;
				
					l_graph_id          := '';
					l_graph_style       := '';
					l_graph_style_class := '';
					l_graph_attrs       := '';
					l_graph_content     := r_row.content;
				
					IF r_row.tag IS NULL THEN
						l_graph_tag   := '';
						l_graph_tag_c := '';
					ELSE
						IF r_row.id IS NOT NULL THEN
							l_graph_id := ' id="' || r_row.id || '"';
						END IF;
						IF r_row.style IS NOT NULL THEN
							l_graph_style := ' style="' || r_row.style || '"';
						END IF;
						IF r_row.class_name IS NOT NULL THEN
							l_graph_style_class := ' class="' || r_row.class_name || '"';
						END IF;
					
						SELECT COUNT(*)
						INTO   l_attrs_cnt
						FROM   xxword_attributes_tmp wat
						WHERE  wat.session_id = self.session_id
									 AND wat.element_id = r_row.element_id;
					
						IF l_attrs_cnt > 0 THEN
							SELECT NVL(attrs, '')
							INTO   l_graph_attrs
							FROM   (SELECT LISTAGG(' ' || wat.attribute || '="' ||
																		 wat.value || '"', ' ') WITHIN GROUP(ORDER BY wat.session_id, wat.element_id) over(PARTITION BY wat.session_id, wat.element_id) attrs
											FROM   xxword_attributes_tmp wat
											WHERE  wat.session_id = self.session_id
														 AND wat.element_id = r_row.element_id)
							GROUP  BY attrs;
						END IF;
					
						l_graph_tag   := '<' || r_row.tag || l_graph_id ||
														 l_graph_attrs || l_graph_style ||
														 l_graph_style_class || '>';
						l_graph_tag_c := '</' || r_row.tag || '>';
						IF (r_row.content IS NULL) THEN
							l_graph_content := l_child_content;
						ELSE
							l_graph_content := r_row.content;
						END IF;
					END IF;
					l_log := self.Log(p_log_level => 15, p_process_name => l_log_process, p_msg => 'id= ' ||
																			to_char(r_row.element_id) ||
																			' parent_id=' ||
																			to_char(r_row.parent_id) ||
																			' parent_order=' ||
																			to_char(r_row.parent_order) || ' ' ||
																			l_graph_tag ||
																			substr(l_graph_content, 0, 32000) ||
																			l_graph_tag_c);
					l_log := self.Log(p_log_level => 3, p_max_log_level => 14, p_process_name => l_log_process, p_msg => 'id= ' ||
																			to_char(r_row.element_id) ||
																			' parent_id=' ||
																			to_char(r_row.parent_id) ||
																			' parent_order=' ||
																			to_char(r_row.parent_order) || ' ' ||
																			l_graph_tag ||
																			'*content*' ||
																			l_graph_tag_c);
					l_log := self.Log(p_log_level => 2, p_max_log_level => 2, p_process_name => l_log_process, p_msg => l_graph_tag ||
																			'*content*' ||
																			l_graph_tag_c);
				
					UPDATE xxword_elements_tmp wet
					SET    render = l_graph_tag || l_graph_content || l_graph_tag_c
					WHERE  wet.session_id = self.session_id
								 AND wet.element_id = r_row.element_id;
				
				END LOOP;
			
			END LOOP;
		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
					l_log := self.Log(p_log_level => 3, p_msg => 'rendering error: ' ||
																			SQLCODE || ': ' ||
																			SQLERRM, p_prefix => xxword.sys_log_error);
					RETURN 'E' || SQLCODE || ': ' || SQLERRM;
				END;
		END;
		COMMIT;
		RETURN 'S';
	END;

END;
/
