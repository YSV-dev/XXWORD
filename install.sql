REM $Version 1.00 
REM $VersionDate 11.07.2022 
REM $Author YANISHEN_SV

SET TERMOUT  ON
SET ECHO     OFF
SET FEEDBACK ON
SET VERIFY   ON
SET PAUSE    OFF
SET SQLBLANKLINES ON
SET SERVEROUTPUT ON SIZE 1000000
WHENEVER SQLERROR continue

SPOOL XXWORD.log

CONNECT APPS/&2@&1 

SET DEFINE   OFF

PROMPT # TABLES
@@XXWORD_TABLES.sql

PROMPT # PKG
@@XXWORD.sql

PROMPT # TYPES
@@xxword_obj.sql
@@xxword_style_obj.sql
@@xxword_element_obj.sql
@@xxword_document_obj.sql
@@xxword_section_style_obj.sql
@@pre_xxword_html_table_el_obj.sql
@@xxword_html_table_obj.sql
@@xxword_html_table_el_obj.sql
@@xxword_html_elements_obj.sql
@@xxword_section_obj.sql
@@xxword_document_ml_obj.sql
@@xxword_document_doc_obj.sql
@@xxword_publicator_obj.sql

PROMPT # UPDATE GRANTS
@@xxword_update_grants.sql

SPOOL OFF
EXIT