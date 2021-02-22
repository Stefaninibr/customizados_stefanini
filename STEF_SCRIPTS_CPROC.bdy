CREATE OR REPLACE PACKAGE BODY STEF_SCRIPTS_CPROC IS
  -- Wolak
  -- ceborges@stefanini.com
  -- 15/02/2021
  -- Stefanini IT Solutions
  vs_cod_empresa empresa.cod_empresa%TYPE;
  mLinha VARCHAR2(1000);
  FUNCTION parametros RETURN VARCHAR2 IS pstr VARCHAR2(5000);
  BEGIN
    vs_cod_empresa := lib_parametros.recuperar('EMPRESA');
    LIB_PROC.ADD_PARAM(PSTR,'Empresa','Varchar2','Combobox','N',VS_COD_EMPRESA,NULL,
    'select cod_empresa,cod_empresa||'' - ''||razao_social||'' - CNPJ: ''||cnpj razao_social from empresa order by cod_empresa');
    LIB_PROC.ADD_PARAM(PSTR,'Data Inicial','DATE','TextBox','S',NULL,'DD/MM/YYYY');
    LIB_PROC.ADD_PARAM(PSTR,'Data Final','DATE','TextBox','S',NULL,'DD/MM/YYYY');
    LIB_PROC.ADD_PARAM(PSTR,'Ajuste','Varchar2','ListBox','S','1',NULL,
    '1=(1) Valor PIS e COFINS,2=(2) Código Situação B,3=(3) Código de Tributação do IPI,4=(4) Código Federal');
    -- Ajuste 1
    LIB_PROC.ADD_PARAM(PSTR,'Tipo (1)','Varchar2','ListBox','S','N',NULL,'N=Nacional,I=Importado',PHABILITA => ':4 = ''1''');
    LIB_PROC.ADD_PARAM(PSTR,'Novo Cód. Sit. PIS/COFINS (1)','Varchar2','TextBox','S',PHABILITA => ':4 = ''1''');
    LIB_PROC.ADD_PARAM(PSTR,'CFOP(s) (=) (1)','Varchar2','TextBox','S',PHABILITA => ':4 = ''1''');
    LIB_PROC.ADD_PARAM(PSTR,'Produto(s) (=) (1)','Varchar2','TextBox','S',PHABILITA => ':4 = ''1''');
    LIB_PROC.ADD_PARAM(PSTR,'Nota(s) Fiscal(is) (=) (1)','Varchar2','TextBox','N',PHABILITA => ':4 = ''1''');
    -- Ajuste 2
    --LIB_PROC.ADD_PARAM(PSTR,'Novo Indicador de Fatura (2)','Varchar2','TextBox','S',PHABILITA => ':4 = ''2''');
    --LIB_PROC.ADD_PARAM(PSTR,'CFOP(s) (=) (2)','Varchar2','TextBox','S',PHABILITA => ':4 = ''2''');
    -- Ajuste 2
    LIB_PROC.ADD_PARAM(PSTR,'Novo Código Situação CST B (2)','Varchar2','TextBox','S',PHABILITA => ':4 = ''2''');
    LIB_PROC.ADD_PARAM(PSTR,'Código Tributação ICMS (=) (2)','Varchar2','TextBox','S',PHABILITA => ':4 = ''2''');
    LIB_PROC.ADD_PARAM(PSTR,'Código(s) Situação CST B (<>) (2)','Varchar2','TextBox','S',PHABILITA => ':4 = ''2''');
    -- Ajuste 3
    LIB_PROC.ADD_PARAM(PSTR,'Tipo Documento (=) (3)','Varchar2','ListBox','S','X',NULL,'X=Entrada e Saida,S=Saida,E=Entrada',PHABILITA=>':4 = ''3''');
    LIB_PROC.ADD_PARAM(PSTR,'Novo Código Tributo IPI (3)','Varchar2','TextBox','S',PHABILITA => ':4 = ''3''');
    LIB_PROC.ADD_PARAM(PSTR,'Código Tributação IPI (=) (3)','Varchar2','TextBox','S',PHABILITA => ':4 = ''3''');
    LIB_PROC.ADD_PARAM(PSTR,'Código(s) Tributo IPI (<>) (3)','Varchar2','TextBox','S',PHABILITA => ':4 = ''3''');
    -- Ajuste 4
    LIB_PROC.ADD_PARAM(PSTR,'Tipo Documento (=) (4)','Varchar2','ListBox','S','X',NULL,'X=Entrada e Saida,S=Saida,E=Entrada',PHABILITA=>':4 = ''4''');
    LIB_PROC.ADD_PARAM(PSTR,'Novo Código Federal (4)','Varchar2','TextBox','S',PHABILITA => ':4 = ''4''');
    LIB_PROC.ADD_PARAM(PSTR,'Código Tributo IPI (=) (4)','Varchar2','TextBox','S',PHABILITA => ':4 = ''4''');
    -- Versao
    LIB_PROC.ADD_PARAM(PSTR,'');
    LIB_PROC.ADD_PARAM(PSTR,'Stefanini IT Group - Versão 19022021/1700');
    return pstr;
  end;
  FUNCTION nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Scripts de Ajustes';
  END;
  FUNCTION tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Ajustes';
  END;
  FUNCTION versao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Versao 1.0';
  END;
  FUNCTION descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Scripts para ajuste de informações na base de dados';
  END;
  FUNCTION modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Scripts de Ajustes';
  END;
  FUNCTION classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Scripts de Ajustes';
  END;
  FUNCTION executar(P_EMPRESA VARCHAR2,
                    P_DATAINICIAL DATE,
                    P_DATAFINAL DATE,
                    P_AJUSTE VARCHAR2,
                    P_5_TIPO VARCHAR2,
                    P_5_CODSITPISCOFINS VARCHAR2,
                    P_5_CFOPS VARCHAR2,
                    P_5_PRODUTOS VARCHAR2,
                    P_5_NOTASFISCAIS VARCHAR2,
                    --P_4_INDICADORFATURA VARCHAR2,
                    --P_4_CFOPS VARCHAR2,
                    P_3_CODSITCSTB VARCHAR2,
                    P_3_COD_TRIBUTACAO_ICMS VARCHAR2,
                    P_3_CODSSITCSTB VARCHAR2,
                    P_2_TIPODOCUMENTO VARCHAR2,
                    P_2_COD_TRIB_IPI VARCHAR2,
                    P_2_COD_TRIBUTACAO_IPI VARCHAR2,
                    P_2_CODS_TRIB_IPI VARCHAR2,
                    P_1_TIPODOCUMENTO VARCHAR2,
                    P_1_CODFEDERAL VARCHAR2,
                    P_1_CODTRIBIPI VARCHAR2) RETURN INTEGER IS
    PROC_ID LIB_PROCESSO.PROC_ID%TYPE;
    NIDENT_FEDERAL X2044_SIT_TRIB_FED.IDENT_FEDERAL%TYPE;
    NIDENT_SITUACAO_B Y2026_SIT_TRB_UF_B.IDENT_SITUACAO_B%TYPE;
    NVLR_ALIQ_PIS NUMBER(10,2);
    NVLR_ALIQ_COFINS NUMBER(10,2);
  BEGIN
    -- Cria Processo
    proc_id := lib_proc.new('STEF_SCRIPTS_CPROC');
    --
    LIB_PROC.ADD_TIPO(PROC_ID,1,'Resultado',1);
    LIB_PROC.ADD_HEADER('Script '||(CASE WHEN P_AJUSTE = '1' THEN 'Valor PIS e COFiNS'
                                         WHEN P_AJUSTE = '2' THEN 'Código Situação B'
                                         WHEN P_AJUSTE = '3' THEN 'Código de Tributação do IPI'
                                         WHEN P_AJUSTE = '4' THEN 'Código Federal' END));
    mlinha := lib_str.w('',rpad('-',150,'-'),1);
    LIB_PROC.ADD_HEADER(MLINHA);
    IF P_AJUSTE = '1' THEN
      NVLR_ALIQ_PIS := (CASE WHEN P_5_TIPO = 'N' THEN 1.65 ELSE 2.10 END);
      NVLR_ALIQ_COFINS := (CASE WHEN P_5_TIPO = 'N' THEN 7.60 ELSE 9.65 END);
      UPDATE X08_ITENS_MERC SET
      COD_SITUACAO_PIS = P_5_CODSITPISCOFINS,
      COD_SITUACAO_COFINS = P_5_CODSITPISCOFINS,
      VLR_BASE_PIS = VLR_CONTAB_ITEM,
      VLR_BASE_COFINS = VLR_CONTAB_ITEM,
      VLR_ALIQ_PIS = NVLR_ALIQ_PIS,
      VLR_ALIQ_COFINS = NVLR_ALIQ_COFINS,
      VLR_PIS = VLR_CONTAB_ITEM * (NVLR_ALIQ_PIS/100),
      VLR_COFINS = VLR_CONTAB_ITEM * (NVLR_ALIQ_COFINS/100),
      DAT_LANC_PIS_COFINS = DATA_FISCAL
      WHERE COD_EMPRESA = P_EMPRESA
      AND DATA_FISCAL BETWEEN P_DATAINICIAL AND P_DATAFINAL
      AND IDENT_CFO IN (SELECT B.IDENT_CFO
                        FROM XMLTABLE(('"'||REPLACE(P_5_CFOPS,',','","')||'"')) X
                        JOIN X2012_COD_FISCAL B ON B.COD_CFO = TRIM(X.COLUMN_VALUE))
      AND (IDENT_PRODUTO IN (SELECT B.IDENT_PRODUTO
                             FROM XMLTABLE(('"'||REPLACE(P_5_PRODUTOS,',','","')||'"')) X
                             JOIN X2013_PRODUTO B ON B.COD_PRODUTO = TRIM(X.COLUMN_VALUE)) OR P_5_PRODUTOS IS NULL)
      AND (NUM_DOCFIS IN (SELECT TRIM(COLUMN_VALUE) FROM XMLTABLE(('"'||REPLACE(P_5_NOTASFISCAIS,',','","')||'"'))) OR P_5_NOTASFISCAIS IS NULL);
      LIB_PROC.ADD('Quantidade de linhas ajustadas: '||SQL%ROWCOUNT);
    END IF;
    /*
    IF P_AJUSTE = '2' THEN
      UPDATE X07_DOCTO_FISCAL SET IND_FATURA = P_4_INDICADORFATURA
      WHERE COD_EMPRESA = P_EMPRESA
      AND DATA_FISCAL BETWEEN P_DATAINICIAL AND P_DATAFINAL
      AND IND_FATURA <> P_4_INDICADORFATURA
      AND IDENT_CFO IN (SELECT B.IDENT_CFO
                        FROM XMLTABLE(('"'||REPLACE(P_4_CFOPS,',','","')||'"')) X
                        JOIN X2012_COD_FISCAL B ON B.COD_CFO = TRIM(X.COLUMN_VALUE));
      LIB_PROC.ADD('Quantidade de linhas ajustadas: '||SQL%ROWCOUNT);
    END IF;
    */
    IF P_AJUSTE = '2' THEN
      BEGIN
        SELECT IDENT_SITUACAO_B INTO NIDENT_SITUACAO_B FROM Y2026_SIT_TRB_UF_B WHERE COD_SITUACAO_B = P_3_CODSITCSTB;
      EXCEPTION WHEN OTHERS THEN
        LIB_PROC.ADD('ERRO: Não encontrado na tabela Y2026_SIT_TRB_UF_B o COD_SITUACAO_B '||P_3_CODSITCSTB);
        LIB_PROC.CLOSE();
        RETURN proc_id;
      END;
      UPDATE X08_ITENS_MERC SET IDENT_SITUACAO_B = NIDENT_SITUACAO_B
      WHERE (COD_EMPRESA, COD_ESTAB, DATA_FISCAL, MOVTO_E_S, NORM_DEV, IDENT_DOCTO, IDENT_FIS_JUR, NUM_DOCFIS, SERIE_DOCFIS, SUB_SERIE_DOCFIS, DISCRI_ITEM)
      IN (SELECT COD_EMPRESA, COD_ESTAB, DATA_FISCAL, MOVTO_E_S, NORM_DEV, IDENT_DOCTO, IDENT_FIS_JUR, NUM_DOCFIS, SERIE_DOCFIS, SUB_SERIE_DOCFIS, DISCRI_ITEM
      FROM X08_BASE_MERC
      WHERE COD_EMPRESA = P_EMPRESA
      AND DATA_FISCAL BETWEEN P_DATAINICIAL AND P_DATAFINAL
      AND COD_TRIBUTACAO = P_3_COD_TRIBUTACAO_ICMS
      AND COD_TRIBUTO = 'ICMS'
      AND IDENT_SITUACAO_B NOT IN (SELECT B.IDENT_SITUACAO_B
                                   FROM XMLTABLE(('"'||REPLACE(P_3_CODSSITCSTB,',','","')||'"')) X
                                   JOIN Y2026_SIT_TRB_UF_B B ON B.COD_SITUACAO_B = TRIM(X.COLUMN_VALUE)));
      LIB_PROC.ADD('Quantidade de linhas ajustadas: '||SQL%ROWCOUNT);
    END IF;
    IF P_AJUSTE = '3' THEN
      UPDATE X08_ITENS_MERC SET COD_TRIB_IPI = P_2_COD_TRIB_IPI
      WHERE (COD_EMPRESA, COD_ESTAB, DATA_FISCAL, MOVTO_E_S, NORM_DEV, IDENT_DOCTO, IDENT_FIS_JUR, NUM_DOCFIS, SERIE_DOCFIS, SUB_SERIE_DOCFIS, DISCRI_ITEM)
      IN (SELECT COD_EMPRESA, COD_ESTAB, DATA_FISCAL, MOVTO_E_S, NORM_DEV, IDENT_DOCTO, IDENT_FIS_JUR, NUM_DOCFIS, SERIE_DOCFIS, SUB_SERIE_DOCFIS, DISCRI_ITEM
      FROM X08_BASE_MERC
      WHERE COD_EMPRESA = P_EMPRESA
      AND DATA_FISCAL BETWEEN P_DATAINICIAL AND P_DATAFINAL
      AND (P_2_TIPODOCUMENTO = 'X' OR
          (P_2_TIPODOCUMENTO = 'S' AND MOVTO_E_S = 9) OR
          (P_2_TIPODOCUMENTO = 'E' AND MOVTO_E_S <> 9))
      AND COD_TRIBUTACAO = P_2_COD_TRIBUTACAO_IPI
      AND COD_TRIBUTO = 'IPI'
      AND COD_TRIB_IPI NOT IN (SELECT TRIM(COLUMN_VALUE) FROM XMLTABLE(('"'||REPLACE(P_2_CODS_TRIB_IPI,',','","')||'"'))));
      LIB_PROC.ADD('Quantidade de linhas ajustadas: '||SQL%ROWCOUNT);
    END IF;
    IF P_AJUSTE = '4' THEN
      BEGIN
        SELECT IDENT_FEDERAL INTO NIDENT_FEDERAL FROM X2044_SIT_TRIB_FED WHERE COD_FEDERAL = P_1_CODFEDERAL;
      EXCEPTION WHEN OTHERS THEN
        LIB_PROC.ADD('ERRO: Não encontrado na tabela X2044_SIT_TRIB_FED o COD_FEDERAL '||P_1_CODFEDERAL);
        LIB_PROC.CLOSE();
        RETURN proc_id;
      END;
      UPDATE X08_ITENS_MERC SET IDENT_FEDERAL = NIDENT_FEDERAL
      WHERE COD_EMPRESA = P_EMPRESA
      AND DATA_FISCAL BETWEEN P_DATAINICIAL AND P_DATAFINAL
      AND (P_1_TIPODOCUMENTO = 'X' OR
          (P_1_TIPODOCUMENTO = 'S' AND MOVTO_E_S = 9) OR
          (P_1_TIPODOCUMENTO = 'E' AND MOVTO_E_S <> 9))
      AND COD_TRIB_IPI = P_1_CODTRIBIPI;
      LIB_PROC.ADD('Quantidade de linhas ajustadas: '||SQL%ROWCOUNT);
    END IF;
    lib_proc.close();
    RETURN proc_id;
  EXCEPTION WHEN others THEN
    lib_proc.add_log('Erro ao executar procedimento: '||SQLERRM,1);
    lib_proc.close();
    RETURN proc_id;
  END EXECUTAR;
END;
/
