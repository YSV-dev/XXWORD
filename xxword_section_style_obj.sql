CREATE OR REPLACE TYPE xxword_section_style_obj FORCE UNDER xxword_style_obj
(
-- Author    YANISHEN_SV
-- Created : 10/06/2022
-- Purpose : стиль для настройки секции

	CONSTRUCTOR FUNCTION xxword_section_style_obj(p_session_id       NUMBER,
                                                p_margine          IN VARCHAR2 := '2.0cm 42.5pt 2.0cm 3.0cm', --margin
                                                p_header_margin    IN VARCHAR2 := '35.4pt', --mso-header-margin
                                                p_footer_margin    IN VARCHAR2 := '35.4pt', --mso-footer-margin
                                                p_size             IN VARCHAR2 := '612.0pt 792.0pt', --size
                                                p_page_orientation IN VARCHAR2 := NULL, --landscape           --mso-page-orientation
                                                p_columns          IN VARCHAR2 := NULL, --2 even 35.4pt        --mso-columns
                                                p_log_level        IN NUMBER := 0) RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY xxword_section_style_obj IS
	CONSTRUCTOR FUNCTION xxword_section_style_obj(p_session_id       NUMBER,
																								p_margine          IN VARCHAR2 := '2.0cm 42.5pt 2.0cm 3.0cm', --margin
																								p_header_margin    IN VARCHAR2 := '35.4pt', --mso-header-margin
																								p_footer_margin    IN VARCHAR2 := '35.4pt', --mso-footer-margin
																								p_size             IN VARCHAR2 := '612.0pt 792.0pt', --size
																								p_page_orientation IN VARCHAR2 := NULL, --landscape           --mso-page-orientation
																								p_columns          IN VARCHAR2 := NULL, --2 even 35.4pt        --mso-columns
																								p_log_level        IN NUMBER := 0)
		RETURN SELF AS RESULT IS
		l_last_section_id NUMBER;
		l_init_element    xxword_style_obj;
	BEGIN
		SELECT COUNT(*) + 1
		INTO   l_last_section_id
		FROM   xxword_styles_tmp wst
		WHERE  wst.session_id = self.session_id
					 AND wst.style_name LIKE 'div.WordSection%';
		self.prv_init(p_session_id => p_session_id, p_log_level => p_log_level, p_prefix => '@page ', p_name => 'WordSection' || l_last_section_id);
	
		SELF.ADD_ATTR('margin', p_margine);
		SELF.ADD_ATTR('mso-header-margin', p_header_margin);
		SELF.ADD_ATTR('mso-footer-margin', p_footer_margin);
		SELF.ADD_ATTR('size', p_size);
		IF p_page_orientation IS NOT NULL THEN
			SELF.ADD_ATTR('mso-page-orientation', p_header_margin);
		END IF;
		IF p_columns IS NOT NULL THEN
			SELF.ADD_ATTR('mso-columns', p_columns);
		END IF;
	
		l_init_element := xxword_style_obj(p_prefix => 'div.', p_name => SELF.name, p_session_id => session_id);
		l_init_element.add_attr('page', SELF.name);
		--COMMIT;
		RETURN;
	END;
END;
/
