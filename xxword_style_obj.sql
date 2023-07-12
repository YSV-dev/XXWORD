CREATE OR REPLACE TYPE xxword_style_obj FORCE UNDER xxword_obj
(
-- Author    YANISHEN_SV
-- Created : 10/06/2022
-- Purpose : CSS стиль
-- Attributes

  prefix   VARCHAR2(150),
	NAME     VARCHAR2(100),
	order_by NUMBER,

	CONSTRUCTOR FUNCTION xxword_style_obj(p_session_id IN NUMBER,
                                        p_log_level  NUMBER := 0,
                                        p_prefix     IN VARCHAR2 := '.',
                                        p_name       VARCHAR2 := NULL,
                                        p_declarate  BOOLEAN  := TRUE)
		RETURN SELF AS RESULT,
    
    MEMBER PROCEDURE prv_init(p_session_id IN NUMBER,
                            p_log_level  NUMBER := 0,
                            p_prefix     IN VARCHAR2 := '.',
                            p_name       VARCHAR2 := NULL,
                            p_declarate  BOOLEAN  := TRUE),

	MEMBER PROCEDURE add_attr(p_attr IN VARCHAR2, p_value IN VARCHAR2), --добавление атрибута стиля (напрямую)

	MEMBER FUNCTION prerender_style_format RETURN VARCHAR2,
  
  OVERRIDING MEMBER FUNCTION prerender RETURN CLOB
)
INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_style_obj IS

	-- Member procedures and functions
	CONSTRUCTOR FUNCTION xxword_style_obj(p_session_id IN NUMBER,
                                        p_log_level  NUMBER := 0,
                                        p_prefix     IN VARCHAR2 := '.',
                                        p_name       VARCHAR2 := NULL,
                                        p_declarate  BOOLEAN  := TRUE)
		RETURN SELF AS RESULT AS
	BEGIN
    prv_init(p_session_id, p_log_level, p_prefix, p_name, p_declarate);
		RETURN;
	END;
  
  MEMBER PROCEDURE prv_init(p_session_id IN NUMBER,
                            p_log_level  NUMBER := 0,
                            p_prefix     IN VARCHAR2 := '.',
                            p_name       VARCHAR2 := NULL,
                            p_declarate  BOOLEAN  := TRUE) IS 
  BEGIN
    prefix     := p_prefix;
    log_level  := p_log_level;
    IF p_name IS NOT NULL THEN
		   NAME       := p_name;
    ELSE
       NAME       := 'style_'||self.generate_UUID;
    END IF;
    
    IF NOT p_declarate THEN
      prefix   := '!';
    END IF;
    
		session_id := p_session_id;
		order_by   := 1;
  END;

	MEMBER PROCEDURE add_attr(p_attr IN VARCHAR2, p_value IN VARCHAR2) IS
	BEGIN
		INSERT INTO XXWORD_STYLES_TMP
			(session_id,
       style_prefix,
			 style_name,
			 attribute,
			 VALUE,
			 order_by)
		VALUES
			(self.session_id,
       self.prefix,
			 self.NAME,
			 p_attr,
			 p_value,
			 self.order_by);
		order_by := order_by + 1;
    --COMMIT;
	END;
  
  MEMBER FUNCTION prerender_style_format RETURN VARCHAR2 IS
    l_RES VARCHAR2(2000);
  BEGIN
    SELECT css_style
      INTO l_RES
      FROM   (SELECT 
                     LISTAGG(wst.attribute || ': ' || wst.value||';', ' ') WITHIN GROUP(ORDER BY wst.order_by) over(PARTITION BY wst.style_name) css_style
              FROM   xxword_styles_tmp wst
              WHERE  wst.session_id = self.session_id AND wst.style_name = self.NAME
              ORDER  BY wst.style_name,
                        order_by)
      GROUP  BY css_style;
    RETURN l_RES;
  END;

	OVERRIDING MEMBER FUNCTION prerender RETURN CLOB IS
		l_RES CLOB;
	BEGIN
    IF NOT prefix = '!' THEN
      SELECT css_style
      INTO l_RES
      FROM   (SELECT wst.style_prefix || wst.style_name || ' {' ||CHR(10)||
                     LISTAGG('    '||wst.attribute || ': ' || wst.value||';', CHR(10)) WITHIN GROUP(ORDER BY wst.order_by) over(PARTITION BY wst.style_name) || CHR(10)
                     || '}' css_style
              FROM   xxword_styles_tmp wst
              WHERE  wst.session_id = self.session_id AND wst.style_name = self.NAME
              ORDER  BY wst.style_name,
                        order_by)
      GROUP  BY css_style;
    ELSE
      SELECT css_style
      INTO l_RES
      FROM   (SELECT 
                     LISTAGG(wst.attribute || ': ' || wst.value||';', ' ') WITHIN GROUP(ORDER BY wst.order_by) over(PARTITION BY wst.style_name) css_style
              FROM   xxword_styles_tmp wst
              WHERE  wst.session_id = self.session_id AND wst.style_name = self.NAME
              ORDER  BY wst.style_name,
                        order_by)
      GROUP  BY css_style;
    END IF;
	
		RETURN l_RES;
	END;

END;
/
