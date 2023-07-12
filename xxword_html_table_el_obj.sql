create or replace type xxword_html_table_el_obj FORCE UNDER xxword_element_obj
(
  -- Author  : $OSUSER
  -- Created : $DATE $TIME
  -- Purpose :
  CONSTRUCTOR FUNCTION xxword_html_table_el_obj(p_parent xxword_element_obj, p_tag VARCHAR2, p_content CLOB := '', p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
		RETURN SELF AS RESULT,
  
  MEMBER FUNCTION create_row(p_content CLOB := NULL, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
     RETURN xxword_html_table_el_obj,
  
  MEMBER FUNCTION create_column(p_content CLOB := NULL, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
     RETURN xxword_html_table_el_obj
)INSTANTIABLE NOT FINAL;
/
create or replace type body xxword_html_table_el_obj IS

  CONSTRUCTOR FUNCTION xxword_html_table_el_obj(p_parent xxword_element_obj, p_tag VARCHAR2, p_content CLOB := '', p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
     RETURN SELF AS RESULT IS
  BEGIN
    self.Prv_Init(p_session_id => p_parent.session_id, p_log_level => p_parent.log_level, p_tag => p_tag, p_parent_id => p_parent.element_id, p_style => p_style, p_class => p_class, p_content => p_content);
    RETURN;
  END;
  
  MEMBER FUNCTION create_row(p_content CLOB := NULL, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
     RETURN xxword_html_table_el_obj IS
  BEGIN
    RETURN xxword_html_table_el_obj(p_tag => 'tr', p_parent => SELF, p_content => p_content, p_style => p_style, p_class => p_class);
  END;
  
  MEMBER FUNCTION create_column(p_content CLOB := NULL, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
     RETURN xxword_html_table_el_obj IS
  BEGIN
    RETURN xxword_html_table_el_obj(p_tag => 'td', p_parent => SELF, p_content => p_content, p_style => p_style, p_class => p_class);
  END;
end;
/
