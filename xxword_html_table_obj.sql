CREATE OR REPLACE TYPE xxword_html_table_obj FORCE UNDER xxword_html_table_el_obj
(
	CONSTRUCTOR FUNCTION xxword_html_table_obj(p_parent xxword_element_obj,
																						 p_style  VARCHAR2 := NULL,
																						 p_class  xxword_style_obj := NULL)
		RETURN SELF AS RESULT,

	MEMBER FUNCTION generate_row(p_row       VARCHAR2,
															 p_separator VARCHAR2 := ';',
															 p_width_row VARCHAR2 := NULL)
		RETURN xxword_html_table_el_obj
)
INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_html_table_obj IS

	CONSTRUCTOR FUNCTION xxword_html_table_obj(p_parent xxword_element_obj,
																						 p_style  VARCHAR2 := NULL,
																						 p_class  xxword_style_obj := NULL)
		RETURN SELF AS RESULT IS
	BEGIN
		self.Prv_Init(p_session_id => p_parent.session_id, p_log_level => p_parent.log_level, p_tag => 'table', p_class => p_class, p_style => p_style, p_parent_id => p_parent.element_id);
		RETURN;
	END;

	MEMBER FUNCTION generate_row(p_row       VARCHAR2,
															 p_separator VARCHAR2 := ';',
															 p_width_row VARCHAR2 := NULL)
		RETURN xxword_html_table_el_obj AS
		CURSOR row_c IS
			SELECT content.res content,
           width.res   WIDTH
      FROM   (SELECT ROWNUM rn, SUBSTR(str, DECODE(LEVEL, 1, 1, INSTR(str, p_separator, 1, LEVEL - 1) + 1), INSTR(str, p_separator, 1, LEVEL) -
                             DECODE(LEVEL, 1, 1, INSTR(str, p_separator, 1, LEVEL - 1) + 1)) res,
                     LEVEL lvl
              FROM   (SELECT p_row || p_separator AS str FROM DUAL)
              CONNECT BY NVL(INSTR(str, p_separator, 1, LEVEL), 0) <> 0) content
      LEFT   JOIN (SELECT SUBSTR(str, DECODE(LEVEL, 1, 1, INSTR(str, p_separator, 1, LEVEL - 1) + 1), INSTR(str, p_separator, 1, LEVEL) -
                                  DECODE(LEVEL, 1, 1, INSTR(str, p_separator, 1, LEVEL - 1) + 1)) res,
                          LEVEL lvl
                   FROM   (SELECT p_width_row || p_separator AS str FROM DUAL)
                   CONNECT BY NVL(INSTR(str, p_separator, 1, LEVEL), 0) <> 0) width
      ON     content.lvl = width.lvl
      ORDER BY content.rn
      ;
	
		l_row   xxword_html_table_el_obj;
		l_tmp   xxword_html_table_el_obj;
		l_style VARCHAR2(20);
	BEGIN
		l_row := self.Create_Row;
		FOR ROW_R IN ROW_C
		LOOP
			IF ROW_R.width IS NOT NULL THEN
				l_style := 'width: ' || ROW_R.width;
			ELSE
				l_style := NULL;
			END IF;
			l_tmp := l_row.create_column(p_content => ROW_R.content, p_style => l_style);
		END LOOP;
	
		RETURN l_row;
	END;
END;
/
