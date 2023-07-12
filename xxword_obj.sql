CREATE OR REPLACE TYPE xxword_obj FORCE AS OBJECT 
(
-- Author    YANISHEN_SV
-- Created : 10/06/2022
-- Purpose : Общий тип для всех сущностей word

-- Attributes
  session_id  NUMBER,  -- номер сессии к которому относится объект (для работы с временными таблицами)
  log_level   NUMBER,

-- Member functions and procedures
	MEMBER FUNCTION prerender RETURN CLOB,       --преобразование в текст (используется в наследниках)
  MEMBER FUNCTION generate_UUID RETURN VARCHAR2,
  MEMBER FUNCTION log(p_log_level NUMBER, p_max_log_level NUMBER := 999, p_msg VARCHAR2, p_prefix VARCHAR2 := 'INFO', p_process_name VARCHAR2 := NULL, p_print_time BOOLEAN := TRUE, p_on_new_line BOOLEAN := TRUE) RETURN VARCHAR2
) NOT INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY xxword_obj IS

	-- Member procedures and functions
	MEMBER FUNCTION prerender RETURN CLOB IS
	BEGIN
		RETURN '<p style="color: red; background: black;">ERROR: Prerender is not available for this object</p>';
	END;
  
  MEMBER FUNCTION generate_UUID RETURN VARCHAR2 IS
     l_uuid VARCHAR2(40);
  BEGIN
     select regexp_replace(rawtohex(sys_guid()), '([A-F0-9]{8})', '\1\2\3\4\5') INTO l_uuid from dual;
     return l_uuid;
  END;
  
  /*
  Этапы рендеринга и сборки без подробностей  1 Этапы сборки документа, его инициализация, результат обработки
  Особенности вывода элементов                2 Рендеринг упрощенных представлений элементов без контента и доп параметров (только аттрибуты и тэги)
  Подробный вывод особенностей вывода элем.   3 Дополняет вывод элементов добавляя ID элемента и ID родителя
  Учитывать стили                             4 Вывод стилей-классов документа
  Учитывать особенности особых стилей         5 Вывод простых стилей, которые записывались в память
  Учитывать варнинги                          10  
  Учитывать варнинги сборки                   11
  Учитывать варнинги элементов                12
  Учитывать варнинги стилей и стилей классов  13
  Вывод урезанной информации с пререндером 
  контента до 1000 символов                   15  !Будет сильно нагружать вывод
  Вывод урезанной информации с пререндером 
  контента до 5000 символов                   20  !Будет ещё сильнее нагружать вывод
  */
  
  MEMBER FUNCTION log(p_log_level NUMBER, p_max_log_level NUMBER := 999, p_msg VARCHAR2, p_prefix VARCHAR2 := 'INFO', p_process_name VARCHAR2 := NULL, p_print_time BOOLEAN := TRUE, p_on_new_line BOOLEAN := TRUE) RETURN VARCHAR2 IS
    l_msg         VARCHAR2(5100) := '';
    l_msg_limit   NUMBER         := 500;
  BEGIN
    IF p_log_level > self.log_level OR p_max_log_level <= self.log_level THEN
      RETURN p_process_name;
    END IF;  
    
    IF p_log_level >= 15 THEN
      l_msg_limit := 1000;
    ELSIF p_log_level >= 20 THEN
      l_msg_limit := 5000;
    END IF;
    
    IF (p_print_time) THEN
      l_msg := l_msg || to_char(SYSDATE, '[DD.MM.YYYY HH24:MI:SS]');
    END IF;
  
    IF p_prefix IS NOT NULL THEN
      l_msg := l_msg || '[' || p_prefix || ']';
    END IF;
    
    IF p_process_name IS NOT NULL THEN
      l_msg := l_msg || '[' || p_process_name || ']';
    END IF;
    
    l_msg := l_msg || ' ' || substr(p_msg, 0, l_msg_limit);
    
    IF p_on_new_line THEN
       apps.fnd_file.put_line(apps.fnd_file.log, l_msg);
    ELSE
      apps.fnd_file.put(apps.fnd_file.log, l_msg);
    END IF;
    RETURN p_process_name;
  END;

END;
/
