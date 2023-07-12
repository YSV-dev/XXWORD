CREATE OR REPLACE TYPE xxword_obj FORCE AS OBJECT 
(
-- Author    YANISHEN_SV
-- Created : 10/06/2022
-- Purpose : ����� ��� ��� ���� ��������� word

-- Attributes
  session_id  NUMBER,  -- ����� ������ � �������� ��������� ������ (��� ������ � ���������� ���������)
  log_level   NUMBER,

-- Member functions and procedures
	MEMBER FUNCTION prerender RETURN CLOB,       --�������������� � ����� (������������ � �����������)
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
  ����� ���������� � ������ ��� ������������  1 ����� ������ ���������, ��� �������������, ��������� ���������
  ����������� ������ ���������                2 ��������� ���������� ������������� ��������� ��� �������� � ��� ���������� (������ ��������� � ����)
  ��������� ����� ������������ ������ ����.   3 ��������� ����� ��������� �������� ID �������� � ID ��������
  ��������� �����                             4 ����� ������-������� ���������
  ��������� ����������� ������ ������         5 ����� ������� ������, ������� ������������ � ������
  ��������� ��������                          10  
  ��������� �������� ������                   11
  ��������� �������� ���������                12
  ��������� �������� ������ � ������ �������  13
  ����� ��������� ���������� � ����������� 
  �������� �� 1000 ��������                   15  !����� ������ ��������� �����
  ����� ��������� ���������� � ����������� 
  �������� �� 5000 ��������                   20  !����� ��� ������� ��������� �����
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
