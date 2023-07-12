CREATE OR REPLACE PACKAGE XXOPM_EXAPMLE_PKG IS

	-- Author  : YANISHEN_SV
	-- Created : 22.06.2022 9:29:08

	g_publicator xxword_publicator_obj;
	g_document   xxword_document_doc_obj;

	g_section_style xxword_section_style_obj;

	g_all_style               xxword_style_obj;
	g_header_small_text_style xxword_style_obj;
	g_header_style            xxword_style_obj;
	g_table_style             xxword_style_obj;
	g_table_td_style          xxword_style_obj;
	g_br_style                xxword_style_obj;

	GP_PART_NUMBER     VARCHAR2(30);  
	GP_ORDER_HEADER_ID NUMBER;  
	GP_ORDER_LINE_ID   NUMBER;  
	GP_SHIPPED_DATE    DATE;  
	GP_FAMILY          VARCHAR2(100);  
	GP_LOT_PAK         VARCHAR2(100);

	CURSOR indicators_c IS
		SELECT 1 FROM dual --СТРУКТУРА ТАБЛИЦ ЯВЛЯЕТСЯ КОРПОРАТИВНОЙ ТАЙНОЙ, ПОЭТОМУ МНЕ ПРИШЛОСЬ СКРЫТЬ ЭТОТ SELECT!!!
		;

	SUBTYPE indicator_st IS indicators_c%ROWTYPE;
	TYPE indicator_t IS TABLE OF indicator_st INDEX BY PLS_INTEGER;
	g_indicator_l indicator_t;

	PROCEDURE start_report(ERRBUF  OUT VARCHAR2,
												 RETCODE OUT VARCHAR2,
												 
												 P_PART_NUMBER     IN VARCHAR2, 
												 P_ORDER_HEADER_ID IN NUMBER, 
												 P_ORDER_LINE_ID   IN NUMBER, 
												 P_SHIPPED_DATE    IN VARCHAR2, 
												 P_FAMILY          IN VARCHAR2,
												 P_LOT_PAK         IN VARCHAR2
												 );

END XXOPM_EXAPMLE_PKG;
/
CREATE OR REPLACE PACKAGE BODY XXOPM_EXAPMLE_PKG IS

	PROCEDURE create_styles IS
	BEGIN
		g_all_style := g_document.create_style_class(p_name => '*', p_prefix => '');
		g_all_style.add_attr('font-size', '9pt');
		g_all_style.add_attr('font-family', 'Times New Roman');
	
		g_section_style := xxword_section_style_obj(p_session_id => g_document.session_id, p_margine => '1.27cm 1.27cm 1.27cm 0.75cm');
		g_section_style.add_attr('font-family', 'Times New Roman');
	
		g_header_small_text_style := g_document.create_style_class(p_name => 'header_small_text');
		g_header_small_text_style.add_attr('font-family', 'Times New Roman');
		g_header_small_text_style.add_attr('font-size', '9pt');
		g_header_small_text_style.add_attr('margin', '0pt');
	
		g_header_style := g_document.create_style_class(p_name => 'header');
		g_header_style.add_attr('font-family', 'Times New Roman');
		g_header_style.add_attr('font-size', '14pt');
	
		g_br_style := g_document.create_style_class(p_prefix => '!');
		g_br_style.add_attr('margin', '0');
	
		g_table_style := g_document.create_empty_style_class(p_name => 'bordered_table', p_prefix => '.');
	
		g_table_td_style := g_document.create_style_class(p_name => 'td', p_prefix => g_table_style.prefix ||
																																	 g_table_style.NAME || ' ');
		g_table_td_style.add_attr('border', '1px solid black');
		g_table_td_style.add_attr('text-align', 'center');
		g_table_td_style.add_attr('vertical-align', 'middle');
	END;
  
  PROCEDURE init_indicators IS
  BEGIN
    FOR indicator_r IN indicators_c 
    LOOP
      g_indicator_l(indicator_r.seq) := indicator_r;
    END LOOP;
  END;
  
  FUNCTION get_koef(p_indicator  IN indicator_st) RETURN NUMBER IS
    l_koef NUMBER;
  BEGIN
    IF (p_indicator.test_id IN (85, 119) AND substr(p_indicator.ordered_item, 1, 2) IN ('11', '12') AND p_indicator.RESULT_VALUE_NUM < 0.05) THEN
      l_koef := 0.05;
    ELSIF (p_indicator.test_id IN (85, 119) AND substr(p_indicator.ordered_item, 1, 2) IN ('11', '12') AND p_indicator.RESULT_VALUE_NUM >= 0.05) THEN
      l_koef := round(p_indicator.RESULT_VALUE_NUM, 1);
    ELSIF p_indicator.test_id = 164 AND p_indicator.RESULT_VALUE_NUM < 0.02 THEN
      l_koef := 0.02;
    ELSE
      l_koef := p_indicator.RESULT_VALUE_NUM;
    END IF;
    RETURN l_koef;
  END;
  
	FUNCTION get_k2o_weight(p_indicator  IN indicator_st, p_lot_weight IN NUMBER) RETURN NUMBER IS
		l_koef NUMBER;
	BEGIN
	
		IF p_indicator.TEST_DESCRIPTION LIKE '%что то%' THEN
			l_koef := get_koef(p_indicator);
		ELSE
			l_koef := 0;
		END IF;
	
		RETURN p_lot_weight * l_koef / 100;
	END;  
  
	FUNCTION get_note3(p_indicator indicator_st) RETURN VARCHAR2 IS
	BEGIN
		IF GP_LOT_PAK IS NULL
			 OR length(GP_LOT_PAK) = 0 THEN
			RETURN '';
		END IF;
		RETURN p_indicator.note3 || chr(10) || GP_LOT_PAK;
	END;  
  
  FUNCTION has_notes(p_indicator  IN indicator_st) RETURN BOOLEAN IS
  BEGIN
    IF p_indicator.note1 IS NOT NULL 
      OR p_indicator.note2 IS NOT NULL 
      OR GP_LOT_PAK IS NOT NULL THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  END;
  
  FUNCTION get_lot_weight(p_inventory_item_id NUMBER, p_organization_id NUMBER) RETURN NUMBER IS
    l_res NUMBER;
  BEGIN
  	
    SELECT 1
    INTO   l_res
    FROM   dual; 
    RETURN l_res * 1000;
  END;  
  
  FUNCTION to_format(p_number NUMBER, p_report_precision NUMBER) RETURN VARCHAR2 IS
    l_format VARCHAR2(20) := '999990';
  BEGIN
    IF p_report_precision = 0 OR p_report_precision IS NULL THEN
      RETURN to_char(p_number, l_format);
    ELSE
      l_format := l_format || '.'; 
    END IF;
    
    FOR iter_i IN 0..p_report_precision
    LOOP
        l_format := l_format || '9';
    END LOOP;
    
    RETURN to_char(p_number, l_format);
  END;
  
	FUNCTION get_req_result(p_indicator IN indicator_st) RETURN VARCHAR2 IS
		l_label VARCHAR2(2000);
	
		CURSOR c_value_desc(pc_test_id NUMBER, pc_value_char VARCHAR2) IS
			SELECT 1 from dual;
	BEGIN
		IF p_indicator.test_type IN ('N', 'L')
			 AND p_indicator.TARGET_VALUE_NUM IS NULL THEN
			RETURN to_format(p_indicator.min_value_num, p_indicator.report_precision) || '-' || to_format(p_indicator.max_value_num, p_indicator.report_precision);
		END IF;
	
		IF p_indicator.test_type = 'V' THEN
			OPEN c_value_desc(p_indicator.test_id, p_indicator.target_value_char);
			FETCH c_value_desc
				INTO l_label;
			CLOSE c_value_desc;
		END IF;
	
		IF p_indicator.test_type IN ('N', 'L') THEN
			l_label := to_char(round(p_indicator.target_value_num, p_indicator.report_precision));
		ELSE
			l_label := '1';
		END IF;
	
		RETURN l_label;
	END;  
  
	FUNCTION get_result(p_indicator IN indicator_st) RETURN VARCHAR2 IS
		l_label VARCHAR2(2000);
	
		CURSOR c_result_num_char(p_test_id NUMBER, p_result_value_num NUMBER) IS
			SELECT 1 from dual;
	BEGIN
	
		IF p_indicator.test_type = 'V' THEN
			RETURN p_indicator.target_value_char;
		ELSIF p_indicator.test_type = 'N' THEN
			RETURN to_format(get_koef(p_indicator), p_indicator.report_precision);
		ELSIF p_indicator.test_type = 'L' THEN
			OPEN c_result_num_char(p_indicator.test_id, p_indicator.result_value_num);
			FETCH c_result_num_char
				INTO l_label;
			CLOSE c_result_num_char;
			IF l_label IS NULL THEN
				RETURN('Соответствует');
			ELSE
				RETURN l_label;
			END IF;
		END IF;
	END;  
  
  FUNCTION create_document RETURN VARCHAR2 IS
    l_section_element xxword_section_obj;
  
    l_paragraph xxword_element_obj;
    l_br        xxword_element_obj;
    l_table     xxword_html_table_obj;
    l_tr        xxword_html_table_el_obj;
    l_td        xxword_html_table_el_obj;
    
    l_tr2        xxword_html_table_el_obj;
    l_td2        xxword_html_table_el_obj;
  
    l_build_result VARCHAR2(251);
    
    l_indicator    indicator_st;
    
    l_lot_weight     NUMBER;
    l_lot_weight_k2o NUMBER;
  BEGIN
  
    --preparing--
    init_indicators;
    -------------
    
    IF g_indicator_l.FIRST IS NULL THEN
      RETURN 'E'||'Данные по параметрам не найдены!';
    END IF;
  
    l_indicator := g_indicator_l(1);
    
    g_document := xxword_document_doc_obj(p_file_name => 'Сертификат качества ' || l_indicator.full_agreement, p_log_level => 20);
    
    apps.fnd_file.put_line(apps.fnd_file.log, 'Сессия: ' || g_document.session_id);
    
    create_styles;
    
    l_section_element := g_document.create_section(g_section_style);
    
    
    
    l_br := xxword_html_elements_obj.wrap_new_line(p_parent => l_section_element, p_style => g_br_style);
    l_br := l_br.create_prototype;
    l_br := l_br.create_prototype;
    l_br := l_br.create_prototype;
    
    l_table := xxword_html_elements_obj.create_table(p_parent => l_section_element, p_style => 'width: 100%;');
    l_tr    := l_table.create_row;
    l_td    := l_tr.create_column(p_content => '<span class="' ||
                                               g_header_style.name ||
                                               '"><b>СЕРТИФИКАТ КАЧЕСТВА</b></span>', p_style => 'width: 100%; text-align: right;');

    
    l_table := xxword_html_elements_obj.create_table(p_parent => l_section_element, p_class => g_header_small_text_style);
    l_tr    := l_table.create_row;
    l_td    := l_tr.create_column(p_content => 'Изготовитель товара', p_style => 'width: 100%');
    
    l_table := xxword_html_elements_obj.create_table(p_parent => l_section_element, p_class => g_header_small_text_style);
    l_tr    := l_table.create_row;
    l_td    := l_tr.create_column(p_content => 'ПАО &laquo;123&raquo;', p_style => 'width: 55%');
    l_td    := l_tr.create_column(p_content => 'Договор', p_style => 'width: 10%; text-align: right; vertical-align: top;');
    l_td    := l_tr.create_column(p_content => l_indicator.full_agreement, p_style => 'width: 20%; vertical-align: top;');
    
    l_br        := l_br.create_prototype;
    l_paragraph := l_section_element.create_element(p_type => 'p', p_style_class => g_header_small_text_style, p_content => 'Россия');
    l_paragraph := l_paragraph.create_prototype(p_content => 'г.Березники');
    l_br        := l_br.create_prototype;
      
    l_table := xxword_html_elements_obj.create_table(p_parent => l_section_element, p_style => 'font-size: 9pt');
    l_tr    := l_table.generate_row('Продавец:'||l_indicator.SELLER_ORGANIZATION_NAME, ':');
    l_tr    := l_table.generate_row('Грузополучатель:'||l_indicator.CONSIGNEE_ORGANIZATION_NAME, ':');
    l_tr    := l_table.generate_row('Страна:'||l_indicator.CONSIGNEE_COUNTRY, ':');
    IF GP_PART_NUMBER IS NOT NULL THEN
       l_tr    := l_table.generate_row('Номер партии:'||GP_PART_NUMBER, ':');
    END IF;
    l_tr    := l_table.generate_row('Дата изготовления:'||to_char(l_indicator.MADE_DATE, 'dd.mm.yyyy'), ':');
    IF GP_SHIPPED_DATE IS NOT NULL THEN
       l_tr := l_table.generate_row('Дата отгрузки:'||to_char(GP_SHIPPED_DATE, 'dd.mm.yyyy'), ':');
    END IF;
    l_tr    := l_table.generate_row('Метод отгрузки:Автотранспорт', ':');
    IF l_indicator.nakl IS NOT NULL THEN
       l_tr := l_table.generate_row('Накладная:'||l_indicator.nakl, ':');
    END IF;
    
    l_br := l_br.create_prototype;
    
    l_lot_weight := get_lot_weight(l_indicator.inventory_item_id, l_indicator.organization_id);
    l_lot_weight_k2o := get_k2o_weight(l_indicator, l_lot_weight);
    
    l_table := xxword_html_elements_obj.create_table(p_parent => l_section_element, p_class => g_table_style, p_style => 'width: 100%; border-collapse: collapse; font-size: 9pt;');
    l_tr    := l_table.generate_row('Наименование товара|НД|Вид грузовых мест|Масса нетто, кг|Масса в пересчете на что-то, кг', '|');
    l_tr    := l_table.generate_row(l_indicator.item_name||':'||l_indicator.STANDARD_CODE||':'||l_indicator.ITEM_PACK_DESCRIPTION||':'|| TO_CHAR(l_lot_weight) ||':'||to_char(l_lot_weight_k2o), ':');
    
    l_br := l_br.create_prototype;
    l_br := l_br.create_prototype;
    
    l_table := xxword_html_elements_obj.create_table(p_parent => l_section_element, p_class => g_table_style, p_style => 'width: 100%; border-collapse: collapse; font-size: 9pt;');
    l_tr    := l_table.generate_row('Наименование показателей:Требования НД:Установлено анализом', ':');
    FOR indicator_id IN g_indicator_l.FIRST..g_indicator_l.LAST 
    LOOP
      l_indicator := g_indicator_l(indicator_id);
      l_tr    := l_table.create_row;
      l_td    := l_tr.create_column(p_content => l_indicator.test_description, p_style => 'text-align: left;');
      l_td    := l_tr.create_column(p_content => get_req_result(l_indicator));
      l_td    := l_tr.create_column(p_content => get_result(l_indicator));
    END LOOP; 
    --l_tr    := l_table.generate_row(' : : ', ':');
    l_tr    := l_table.create_row;
    l_tr    := l_tr.create_column;
    l_tr.add_attribute('colspan', '3');
    
    
    l_br := xxword_html_elements_obj.wrap_new_line(p_parent => l_tr, p_style => g_br_style);
    l_paragraph := l_tr.create_element(p_type => 'p', p_content => 'КАКОЙ_ТО ВАЖНЫЙ ТЕКСТ', p_style_class => g_header_small_text_style, p_style => 'text-align: center;');
    l_br := l_br.create_prototype;
    l_table := xxword_html_elements_obj.create_table(p_parent => l_tr, p_style => 'font-size: 9pt; text-align: left;');
    IF has_notes(l_indicator) THEN 
      l_tr2 := l_table.create_row;
      l_td2 := l_tr2.create_column(p_style => 'width: 180pt; border: 0pt');
      l_td2 := l_tr2.create_column(p_style => 'width: 30pt; border: 0pt', p_content => 'Примечание:');
      l_td2 := l_tr2.create_column(p_style => 'width: 180pt; border: 0pt; text-align: left;', p_content => l_indicator.note1);
      l_tr2 := l_table.create_row;
      l_td2 := l_tr2.create_column(p_style => 'border: 0pt');
      l_td2 := l_tr2.create_column(p_style => 'border: 0pt');
      l_td2 := l_tr2.create_column(p_style => 'border: 0pt; text-align: left;', p_content => l_indicator.note2);
      l_tr2 := l_table.create_row;
      l_td2 := l_tr2.create_column(p_style => 'border: 0pt');
      l_td2 := l_tr2.create_column(p_style => 'border: 0pt');
      l_td2 := l_tr2.create_column(p_style => 'border: 0pt; text-align: left;', p_content => get_note3(l_indicator));
      --l_table.generate_row(p_row => '|'||, p_separator => '|');
    END IF;
    
    l_br := l_br.create_prototype;
    
    l_table := xxword_html_elements_obj.create_table(p_parent => l_tr, p_style => 'font-size: 9pt; text-align: left;');
    l_tr2 := l_table.create_row;
    l_td2 := l_tr2.create_column(p_style => 'width: 200pt; border: 0pt; vertical-align: middle');
    l_td2 := l_tr2.create_column(p_style => 'border: 0pt; vertical-align: middle', p_content => 'Подпись');
    l_td2 := l_tr2.create_column(p_style => 'border: 0pt; width: 80pt; border-bottom: 1pt solid black; vertical-align: middle');
    l_td2 := l_tr2.create_column(p_style => 'border: 0pt; vertical-align: middle', p_content => 'Фамилия И.О.');
    l_td2 := l_tr2.create_column(p_style => 'border: 0pt; width: 80pt; border-bottom: 1pt solid black; vertical-align: middle', p_content => '<span style="font-size: 8pt;">'||GP_FAMILY||'</span>');
    
    
    /*l_table := xxword_html_elements_obj.create_table(p_parent => l_tr, p_style => 'font-size: 9pt; margin: 0pt');
    l_tr2 := l_table.create_row;
    l_td2 := l_tr2.create_column(p_style => 'border: 0pt; width: 20pt;');
    l_td2 := l_tr2.create_column(p_style => 'border: 0pt; width: 100pt; height: 100pt; border: 0pt; vertical-align: middle', p_content => 'Штамп ОТК');*/
    
    l_br := l_br.create_prototype;
    l_br := l_br.create_prototype;
    l_br := l_br.create_prototype;
    
    l_paragraph := l_tr.create_element(p_type => 'p', p_content => 'Штамп ОТК', p_style_class => g_header_small_text_style, p_style => 'text-align: left; margin-left: 100pt; height: 100pt;');
    
    l_br := l_br.create_prototype;
    l_br := l_br.create_prototype;
    l_br := l_br.create_prototype;
    
    l_build_result := g_document.build_document;
    apps.fnd_file.put_line(apps.fnd_file.log, 'Результат построения: ' || l_build_result);
    
    RETURN 'S';--l_build_result;
  END; 

	--start_point
	PROCEDURE start_report(ERRBUF            OUT VARCHAR2,
												 RETCODE           OUT VARCHAR2,
												 P_PART_NUMBER     IN VARCHAR2, 
												 P_ORDER_HEADER_ID IN NUMBER, 
												 P_ORDER_LINE_ID   IN NUMBER, 
												 P_SHIPPED_DATE    IN VARCHAR2, 
												 P_FAMILY          IN VARCHAR2,
												 P_LOT_PAK         IN VARCHAR2
												 ) IS
		l_build_result VARCHAR2(5000);
	BEGIN
		GP_PART_NUMBER     := P_PART_NUMBER;
		GP_ORDER_HEADER_ID := P_ORDER_HEADER_ID;
		GP_ORDER_LINE_ID   := P_ORDER_LINE_ID;
    IF P_SHIPPED_DATE IS NOT NULL THEN
		   GP_SHIPPED_DATE    := to_date(P_SHIPPED_DATE, 'yyyy/mm/dd hh24:mi:ss');
    END IF;
		GP_FAMILY          := P_FAMILY;
		GP_LOT_PAK         := P_LOT_PAK;
	  
    g_publicator := xxword_publicator_obj(p_style_set => xxword.pub_style_l_0, p_downLoad_text => 'Скачать ', p_print_extension => TRUE);
    
    BEGIN
      l_build_result  := create_document;
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          l_build_result := 'E<p>'|| SQLERRM || '<BR/>' || DBMS_UTILITY.FORMAT_ERROR_STACK() || '<BR/>' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() || '</p>';
        END;
    END;
    
    IF substr(l_build_result, 0, 1) = 'S' THEN
      g_publicator.add_document(g_document);
      g_publicator.publicate; 
      g_publicator.send_email(p_to => 'Моя почта', p_email_text => '<h1>hello world</h1>', p_subject => 'TEST'); 
    ELSE
      g_publicator.show_error(substr(l_build_result, 2, 250)||'
      <p>Для разработчиков:</p>
      <p>---------------------------------------------</p>
      <pre>
      <p>Модуль:              ИМЯ МОДУЛЯ</p>
      <p>Пакет:               ИМЯ ПАКЕТА</p>
      <p>GP_PART_NUMBER:     '||GP_PART_NUMBER||'</p>
      <p>GP_ORDER_HEADER_ID: '||GP_ORDER_HEADER_ID||'</p>
      <p>GP_ORDER_LINE_ID:   '||GP_ORDER_LINE_ID||'</p>
      <p>GP_SHIPPED_DATE:    '||GP_SHIPPED_DATE||'</p>
      <p>GP_FAMILY:          '||GP_FAMILY||'</p>
      <p>GP_LOT_PAK:         '||GP_LOT_PAK||'</p>
      </pre>
      ', 'Ошибка!');
    END IF;
	END;

END XXOPM_EXAPMLE_PKG;
/
