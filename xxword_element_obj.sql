CREATE OR REPLACE TYPE xxword_element_obj FORCE UNDER xxword_obj
(
-- Author    YANISHEN_SV
-- Created : 10/06/2022
-- Purpose : Общий тип для элементов

-- Attributes
	element_id   NUMBER,
	tag          VARCHAR2(50),
	content      CLOB,
	style_class  xxword_style_obj,
	style        VARCHAR2(2000),
	id           VARCHAR2(100),
	parent_id    NUMBER,
	parent_order NUMBER,

-- Member functions and procedures
	CONSTRUCTOR FUNCTION xxword_element_obj(p_session_id   NUMBER,
                                          p_log_level    IN NUMBER := 0,
																					p_tag          VARCHAR2 := NULL,
																					p_content      CLOB := NULL,
																					p_class        xxword_style_obj := NULL,
																					p_style        VARCHAR2 := NULL,
																					p_id           VARCHAR2 := NULL,
																					p_parent_id    NUMBER := 0,
																					p_parent_order NUMBER := -1,
                                          p_attr_legacy_id  IN NUMBER := -1)
		RETURN SELF AS RESULT,
    
  MEMBER PROCEDURE prv_init (p_session_id   IN NUMBER,
                                      p_log_level    IN NUMBER := 0,
                                      p_tag          IN VARCHAR2 := NULL,
                                      p_content      IN CLOB := NULL,
                                      p_class        IN xxword_style_obj := NULL,
                                      p_style        IN VARCHAR2 := NULL,
                                      p_id           IN VARCHAR2 := NULL,
                                      p_parent_id    IN NUMBER := 0,
                                      p_parent_order IN NUMBER := -1,
                                      p_attr_legacy_id  IN NUMBER := -1),

	OVERRIDING MEMBER FUNCTION prerender RETURN CLOB,

	MEMBER PROCEDURE insert_elem(p_obj IN OUT xxword_element_obj),
  
  MEMBER PROCEDURE add_attribute(p_attribute VARCHAR2, p_value VARCHAR2),
  
  MEMBER PROCEDURE set_id(p_id VARCHAR2),

  MEMBER PROCEDURE set_style(p_style VARCHAR2),
  
  MEMBER PROCEDURE set_style_class(p_style_class IN xxword_style_obj),

	MEMBER PROCEDURE set_content(p_content CLOB),
  
  MEMBER FUNCTION create_element(p_type        IN VARCHAR2 := NULL,
                                 p_content     IN CLOB := NULL,
                                 p_style       IN VARCHAR2 := NULL,
                                 p_style_class xxword_style_obj := NULL,
                                 p_id          IN VARCHAR2 := NULL)
    RETURN xxword_element_obj,
    
  MEMBER FUNCTION create_prototype(
                                  p_tag          IN VARCHAR2 := NULL,
                                  p_content      IN CLOB := NULL,
                                  p_style_class  IN xxword_style_obj := NULL,
                                  p_style        IN VARCHAR2 := NULL,
                                  p_id           IN VARCHAR2 := NULL,
                                  p_dubl_attrs   IN BOOLEAN  := TRUE
                                 ) RETURN xxword_element_obj,

	MEMBER FUNCTION get_next_element_id RETURN NUMBER,
  
  MEMBER FUNCTION get_next_parent_order RETURN NUMBER,
  
  MEMBER FUNCTION has_content RETURN BOOLEAN
)
INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_element_obj IS

	CONSTRUCTOR FUNCTION xxword_element_obj(p_session_id   IN NUMBER,
                                          p_log_level    IN NUMBER := 0,
																					p_tag          IN VARCHAR2 := NULL,
																					p_content      IN CLOB := NULL,
																					p_class        xxword_style_obj := NULL,
																					p_style        IN VARCHAR2 := NULL,
																					p_id           IN VARCHAR2 := NULL,
																					p_parent_id    IN NUMBER := 0,
																					p_parent_order IN NUMBER := -1,
                                          p_attr_legacy_id  IN NUMBER := -1)
		RETURN SELF AS RESULT IS
	BEGIN
    prv_init(p_session_id, p_log_level, p_tag, p_content, p_class, p_style, p_id, p_parent_id, p_parent_order, p_attr_legacy_id);
		RETURN;
	END;
  
  MEMBER PROCEDURE prv_init ( p_session_id   IN NUMBER,
                              p_log_level    IN NUMBER := 0,
                              p_tag          IN VARCHAR2 := NULL,
                              p_content      IN CLOB := NULL,
                              p_class        xxword_style_obj := NULL,
                              p_style        IN VARCHAR2 := NULL,
                              p_id           IN VARCHAR2 := NULL,
                              p_parent_id    IN NUMBER := 0,
                              p_parent_order IN NUMBER := -1,
                              p_attr_legacy_id  IN NUMBER := -1) IS
    l_log      VARCHAR2(10);
    l_log_text VARCHAR2(200);
  BEGIN
    session_id   := p_session_id;
    element_id   := SELF.get_next_element_id;
    tag          := p_tag;
    style_class  := p_class;
    style        := p_style;
    id           := p_id;
    parent_id    := p_parent_id;
    content      := p_content;
    log_level    := p_log_level;
    
    IF p_class IS NOT NULL THEN
      IF p_class.prefix != '!' THEN
        style_class := p_class;
      ELSE
        l_log := self.Log(p_log_level => 13, p_process_name => xxword.sys_proc_init, p_prefix => xxword.sys_log_warn, p_msg => 'You can''t use class with prefix "!", attribute "class" will be changed on "style"');
        style := p_class.prerender_style_format;
      END IF;
    END IF;
    
    IF p_parent_order = -1 THEN 
      parent_order := self.get_next_parent_order;
    ELSE
      parent_order := p_parent_order;
    END IF;
    
    IF tag IS NULL THEN
      l_log_text := 'ID: '||to_char(element_id)||'. You cannot use attributes on elements without a tag! Used ';
      IF style_class IS NOT NULL THEN
        l_log := self.Log(p_log_level => 12, p_process_name => xxword.sys_proc_init, p_msg => l_log_text||'class attribute.', p_prefix => xxword.sys_log_warn);
      END IF;
      IF style IS NOT NULL THEN
        l_log := self.Log(p_log_level => 12, p_process_name => xxword.sys_proc_init, p_msg => l_log_text||'style attribute.', p_prefix => xxword.sys_log_warn);
      END IF;
      IF id IS NOT NULL THEN
        l_log := self.Log(p_log_level => 12, p_process_name => xxword.sys_proc_init, p_msg => l_log_text||'id attribute.', p_prefix => xxword.sys_log_warn);
      END IF;
    END IF;
  
    INSERT INTO XXWORD_ELEMENTS_TMP
      (session_id,
       element_id,
       parent_id,
       parent_order,
       content,
       style,
       class_name,
       tag,
       id)
    VALUES
      (session_id,
       element_id,
       parent_id,
       parent_order,
       content,
       style,
       style_class.name,
       tag,
       id);
    --COMMIT;
    
    IF NOT p_attr_legacy_id = -1 THEN
      
       l_log := self.Log(p_log_level => 3, p_process_name => xxword.sys_proc_init, p_msg => 'Inheriting attributes from element '||to_char(p_attr_legacy_id)||' to element '||to_char(element_id)||'.', p_prefix => xxword.sys_log_info);
       
       FOR r_attr IN (SELECT wat.attribute, wat.VALUE FROM xxword_attributes_tmp wat WHERE wat.session_id = self.session_id AND wat.element_id = p_attr_legacy_id)
       LOOP
           l_log := self.Log(p_log_level => 6, p_msg => r_attr.attribute||': '||r_attr.VALUE||';', p_prefix => NULL, p_print_time => FALSE);
           INSERT INTO xxword_attributes_tmp (session_id, element_id, attribute, VALUE) VALUES (self.session_id, self.element_id, r_attr.attribute, r_attr.value);
       END LOOP;
    END IF;
     
    RETURN;
  END;

  --TODO
	OVERRIDING MEMBER FUNCTION prerender RETURN CLOB IS
	BEGIN
		RETURN '<p>Пока не реализовано</p>';
	END;

	MEMBER PROCEDURE insert_elem(p_obj IN OUT xxword_element_obj) IS
		e_child_not_allowed EXCEPTION;
		PRAGMA EXCEPTION_INIT(e_child_not_allowed, -20002);
	BEGIN
		p_obj.parent_id := self.element_id;
	
		IF NOT has_content THEN
			UPDATE xxword_elements_tmp wet
			SET    wet.parent_id    = self.element_id,
						 wet.parent_order = self.get_next_parent_order
			WHERE  wet.session_id = self.session_id
						 AND wet.element_id = p_obj.element_id;
			--COMMIT;
		ELSE
			RAISE e_child_not_allowed; --Запрещено вставлять дочерние элементы, если есть контент
		END IF;
	END;
  
  MEMBER PROCEDURE add_attribute(p_attribute VARCHAR2, p_value VARCHAR2) IS
  BEGIN
    INSERT INTO xxword_attributes_tmp wat (session_id, element_id, attribute, VALUE) VALUES (self.session_id, self.element_id, p_attribute, p_value);
  END;
  
  MEMBER PROCEDURE set_id(p_id VARCHAR2) IS
  BEGIN
    id := p_id;
    UPDATE xxword_elements_tmp wet
      SET    wet.id = p_id
      WHERE  wet.session_id = self.session_id
             AND wet.element_id = self.element_id;
      --COMMIT;
  END;
  
  MEMBER PROCEDURE set_style(p_style VARCHAR2) IS
  BEGIN
    style := p_style;
    UPDATE xxword_elements_tmp wet
      SET    wet.style = p_style
      WHERE  wet.session_id = self.session_id
             AND wet.element_id = self.element_id;
      --COMMIT;
  END;
  
  MEMBER PROCEDURE set_style_class(p_style_class IN xxword_style_obj) IS
  BEGIN
    SELF.style_class := p_style_class;
    UPDATE xxword_elements_tmp wet
      SET    wet.class_name = p_style_class.name
      WHERE  wet.session_id = self.session_id
             AND wet.element_id = self.element_id;
      --COMMIT;
  END;

	MEMBER PROCEDURE set_content(p_content CLOB) IS
	
		l_tag       VARCHAR2(50);
		l_child_cnt NUMBER;
	
		e_content_not_allowed EXCEPTION;
		PRAGMA EXCEPTION_INIT(e_content_not_allowed, -20001);
	BEGIN
    
		SELECT wet.tag,
					 (COUNT(*) OVER(PARTITION BY wet.parent_id)) - 1
		INTO   l_tag,
					 l_child_cnt
		FROM   xxword_elements_tmp wet
		WHERE  wet.session_id = self.session_id
					 AND wet.element_id = self.element_id;
	
		IF l_child_cnt = 0 /*
           AND
           l_tag IN
           (NULL, '', 'p', 'span', 'i', 'b', 'big', 'small', 'strong', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'sub', 'sup')*/
		 THEN
      content := p_content;
     
			UPDATE xxword_elements_tmp wet
			SET    wet.content = p_content
			WHERE  wet.session_id = self.session_id
						 AND wet.element_id = self.element_id;
			--COMMIT;
		ELSE
			RAISE e_content_not_allowed; --Запрещено добавлять внутренний текст к элементам у которых есть дочерние элементы
		END IF;
	END;
  
  
  
  MEMBER FUNCTION create_element(p_type        IN VARCHAR2 := NULL,
                                 p_content     IN CLOB := NULL,
                                 p_style       IN VARCHAR2 := NULL,
                                 p_style_class IN xxword_style_obj := NULL,
                                 p_id          IN VARCHAR2 := NULL)
    RETURN xxword_element_obj AS
  BEGIN
    RETURN xxword_element_obj(
      p_session_id => session_id, 
      p_log_level => SELF.LOG_LEVEL,
      p_tag => p_type, 
      p_content => p_content, 
      p_class => p_style_class, 
      p_style => p_style, 
      p_id => p_id, 
      p_parent_id => SELF.ELEMENT_ID, 
      p_parent_order => SELF.get_next_parent_order
    );
  END;
  
  MEMBER FUNCTION create_prototype(
                                  p_tag          IN VARCHAR2 := NULL,
                                  p_content      IN CLOB := NULL,
                                  p_style_class  IN xxword_style_obj := NULL,
                                  p_style        IN VARCHAR2 := NULL,
                                  p_id           IN VARCHAR2 := NULL,
                                  p_dubl_attrs   IN BOOLEAN  := TRUE
                                 ) RETURN xxword_element_obj IS
      l_tag          VARCHAR2(50);
      l_content      CLOB;
      l_style_class  xxword_style_obj;
      l_style        VARCHAR2(2000);
      l_id           VARCHAR2(100);
      l_attr_legacy_id  NUMBER := -1;
  BEGIN
    SELECT
      decode(p_tag, NULL, SELF.tag, p_tag),
      decode(p_style, NULL, SELF.style, p_style),
      decode(p_id, NULL, NULL, p_id)
    INTO
      l_tag,
      l_style,
      l_id
    FROM dual;
    
    IF p_style_class IS NOT NULL THEN
      l_style_class := p_style_class;
    ELSE
      l_style_class := self.style_class;
    END IF;
    
    IF p_content IS NULL THEN
      l_content := self.content;
    ELSE
      l_content := p_content;
    END IF;
    
    IF p_dubl_attrs THEN
      l_attr_legacy_id := self.element_id;
    END IF;
    
    RETURN xxword_element_obj(
      p_session_id => SELF.session_id, 
      p_log_level => SELF.LOG_LEVEL,
      p_tag => l_tag, 
      p_content => l_content, 
      p_class => l_style_class, 
      p_style => l_style, 
      p_id => l_id, 
      p_parent_id => SELF.parent_id, 
      p_parent_order => SELF.get_next_parent_order,
      p_attr_legacy_id => l_attr_legacy_id
    );
  END;

	MEMBER FUNCTION get_next_element_id RETURN NUMBER IS
		l_last_element_id NUMBER;
	BEGIN
		SELECT NVL(MAX(wet.element_id), 0) + 1
		INTO   l_last_element_id
		FROM   XXWORD_ELEMENTS_TMP wet
		WHERE  wet.session_id = self.session_id;
		RETURN l_last_element_id;
	END;

	MEMBER FUNCTION get_next_parent_order RETURN NUMBER IS
    l_last_parent_order NUMBER;
	BEGIN
		SELECT NVL(MAX(parent_order), 0) + 1
		INTO   l_last_parent_order
		FROM   xxword_elements_tmp wet
		WHERE  wet.session_id = self.session_id
			 AND wet.parent_id = SELF.parent_id;
    RETURN l_last_parent_order;
	END;
  
  MEMBER FUNCTION has_content RETURN BOOLEAN IS
    l_result NUMBER;
  BEGIN
    SELECT CASE 
            WHEN wet.content IS NULL THEN 0
            ELSE 1
       END
    INTO   l_result
    FROM   xxword_elements_tmp wet
    WHERE  wet.session_id = self.session_id
       AND wet.element_id = self.element_id;
    IF l_result = 1 THEN 
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  END;
  
END;
/
