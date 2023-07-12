create or replace type xxword_html_table_el_obj FORCE UNDER xxword_element_obj
(
  CONSTRUCTOR FUNCTION xxword_html_table_el_obj(p_parent xxword_element_obj, p_tag VARCHAR2, p_content CLOB := '', p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
    RETURN SELF AS RESULT,
  
  MEMBER FUNCTION create_row(p_content CLOB := NULL, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
     RETURN xxword_html_table_el_obj,
  
  MEMBER FUNCTION create_column(p_content CLOB := NULL, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL)
     RETURN xxword_html_table_el_obj
)INSTANTIABLE NOT FINAL;
/
