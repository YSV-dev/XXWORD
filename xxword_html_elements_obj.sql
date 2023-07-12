create or replace type xxword_html_elements_obj FORCE UNDER xxword_obj
(
  -- Author  : $OSUSER
  -- Created : $DATE $TIME
  -- Purpose : 
  STATIC FUNCTION prv_get_style_class(p_parent xxword_element_obj, p_style xxword_style_obj := NULL, p_class xxword_style_obj := NULL) RETURN VARCHAR2,
  
  STATIC FUNCTION wrap_new_line(p_parent xxword_element_obj, p_style xxword_style_obj := NULL, p_class xxword_style_obj := NULL) RETURN xxword_element_obj,
  
  STATIC FUNCTION create_table(p_parent xxword_element_obj, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL) RETURN xxword_html_table_obj
)INSTANTIABLE NOT FINAL;
/
create or replace type body xxword_html_elements_obj IS

  STATIC FUNCTION prv_get_style_class(p_parent xxword_element_obj, p_style xxword_style_obj := NULL, p_class xxword_style_obj := NULL) RETURN VARCHAR2 AS
    l_class VARCHAR2(150);
    l_style VARCHAR2(2010);
    l_result VARCHAR2(2160);
    l_log    VARCHAR2(1);
  BEGIN
    IF p_style IS NOT NULL THEN
      l_style := ' style="'||p_style.prerender_style_format||'"';
    END IF;
    
    IF p_class IS NOT NULL THEN
      IF p_class.prefix != '!' THEN
        l_class := ' class="'||p_class.name||'"';
      ELSE
        l_log := p_parent.Log(p_log_level => 13, p_prefix => xxword.sys_log_warn, p_msg => 'You can''t use class with prefix "!", attribute "class" will be changed on "style"');
        l_style := ' style="'||p_style.prerender_style_format||'"';
      END IF;
    END IF;
    
    l_result := l_class || l_style;
    
    RETURN l_result;
  END;

  STATIC FUNCTION wrap_new_line(p_parent xxword_element_obj, p_style xxword_style_obj := NULL, p_class xxword_style_obj := NULL) RETURN xxword_element_obj AS
  BEGIN
    RETURN xxword_element_obj(
      p_session_id => p_parent.session_id, 
      p_log_level => p_parent.LOG_LEVEL,
      p_tag => '', 
      p_content => '<br'|| prv_get_style_class(p_parent, p_style, p_class)||'/>', 
      p_parent_id => p_parent.ELEMENT_ID, 
      p_parent_order => p_parent.get_next_parent_order
    );
  END;
  
  STATIC FUNCTION create_table(p_parent xxword_element_obj, p_style VARCHAR2 := NULL, p_class xxword_style_obj := NULL) RETURN xxword_html_table_obj AS
  BEGIN
    RETURN xxword_html_table_obj(
      p_parent => p_parent, 
      p_style => p_style,
      p_class => p_class
    );
  END;
  
end;
/
