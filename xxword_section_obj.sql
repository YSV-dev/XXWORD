CREATE OR REPLACE TYPE xxword_section_obj FORCE UNDER xxword_element_obj
(
-- Author    YANISHEN_SV
-- Created : 23/06/2022
-- Purpose : Секция/раздел документа

	CONSTRUCTOR FUNCTION xxword_section_obj(p_session_id   IN NUMBER,
                                          p_section_style IN xxword_section_style_obj,
                                          p_log_level IN NUMBER := 0)
		RETURN SELF AS RESULT,
    
  MEMBER FUNCTION wrap_new_page RETURN xxword_element_obj
  
)
INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_section_obj IS

	CONSTRUCTOR FUNCTION xxword_section_obj(p_session_id   IN NUMBER,
                                          p_section_style IN xxword_section_style_obj,
                                          p_log_level IN NUMBER := 0)
		RETURN SELF AS RESULT IS
	BEGIN
    self.Prv_Init(p_session_id => p_session_id, p_log_level => p_log_level, p_tag => xxword.g_tag_div, p_class => p_section_style, p_parent_id => 0);
		RETURN;
	END;

	MEMBER FUNCTION wrap_new_page RETURN xxword_element_obj IS
  BEGIN
    RETURN xxword_element_obj(
      p_session_id => session_id, 
      p_log_level => SELF.LOG_LEVEL,
      p_tag => '', 
      p_content => '<br clear=all style="mso-special-character:line-break;page-break-before:always"/>', 
      p_parent_id => SELF.ELEMENT_ID, 
      p_parent_order => SELF.get_next_parent_order
    );
  END;

END;
/
