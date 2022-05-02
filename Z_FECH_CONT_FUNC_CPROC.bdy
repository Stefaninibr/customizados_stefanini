CREATE OR REPLACE PACKAGE BODY Z_FECH_CONT_FUNC_CPROC is

  FUNCTION parametros RETURN VARCHAR2 IS
  pstr     varchar2(5000);
--  CCOD_ESTAB   ESTABELECIMENTO.COD_ESTAB%TYPE;
  CCOD_EMPRESA EMPRESA.COD_EMPRESA%TYPE;
--  CGRUPO VARCHAR2(9);
--  DATA_W DATE;

  BEGIN
    CCOD_EMPRESA := LIB_PARAMETROS.RECUPERAR('EMPRESA');
--    CCOD_ESTAB     := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');

    LIB_PROC.add_param(pstr,
               'Geração do Encerramento Contábil',
               'VARCHAR2',
               'Text',
               'N',
               NULL);

    Lib_Proc.Add_Param(pstr,
               'Empresa',
               'Varchar2',
               'ComboBox',
               'S',
               NULL,
               NULL,
               'SELECT cod_empresa, cod_empresa||'' - ''||razao_social FROM empresa WHERE cod_empresa = '||cCod_Empresa,
               'S');

    Lib_Proc.Add_Param(Pstr,
               'Estabelecimentos',
               'Varchar2',
               'ComboBox',
               'S',
               NULL,
               NULL,
               ' SELECT a.cod_estab,' ||
               ' a.cod_estab || '' - '' || a.razao_social '||
               ' FROM estabelecimento a' ||
               ' WHERE a.cod_empresa = ' || cCod_Empresa ||
               ' ORDER BY a.cod_empresa,a.cod_estab',
               'S');

    Lib_Proc.Add_Param(pstr,
               'Competencia',
               'DATE',
               'TextBox',
               'S',
               null,
               'MM/YYYY',
               null,
               'S');

    Lib_Proc.Add_Param(pstr,
               'Codigo da Conta de Encerramento',
               'Varchar2',
               'ComboBox',
               'S',
               NULL,
               NULL,
               'SELECT ident_conta, ''IDENT_CONTA - ''||ident_conta||'' - GRUPO-''||grupo_conta||'' / CONTA-''||cod_conta||'' / ''||descricao FROM x2002_plano_contas WHERE ind_situacao = ''A'' AND ind_conta = ''A'' AND ind_natureza = ''7'' ORDER BY grupo_conta, cod_conta, descricao ',
               'S',
           ':6 = ''1''');

    Lib_Proc.Add_Param(pstr,
               'Tipo',
               'Varchar2',
               'RadioButton',
               'S',
               '1',
               NULL,
               --'1=Inicializar (reverter encerramento),2=Gerar Encerramento');
               '1=Gerar Encerramento (Parte 1),2=Recalcular Saldos (Parte 2)');

    Lib_Proc.Add_Param(pstr,
           'Tipo de Encerramento',
           'Varchar2',
           'RadioButton',
           'S',
           '1',
           NULL,
           '1=SAFX227,2=SAFX226');

    lib_proc.add_param(pstr, ' ', 'Varchar2', 'TEXT', 'u', NULL);
    lib_proc.add_param(pstr,
               'Stefanini IT Solutions - Procedimentos Customizados',
               'Varchar2',
               'TEXT',
               'u');
    lib_proc.add_param(pstr, 'Versao  : 1.6', 'Varchar2', 'TEXT', 'u');
    return pstr;
  END parametros;

  FUNCTION tipo RETURN VARCHAR2 IS
  BEGIN
    return 'SPED ECD';
  END;

  FUNCTION nome RETURN VARCHAR2 IS
  BEGIN
    return 'Geração do Encerramento Contábil Moeda Funcional';
  END;

  FUNCTION descricao RETURN VARCHAR2 IS
  BEGIN
    return 'Processo para criação dos lançamentos de encerramento do exercício.';
  END;

  PROCEDURE Recalcula_Saldo_Novo (pEmpresa varchar2, pEstab varchar2,pCompetencia date,pTipoEncerramento varchar2) IS
    nVLR_SALDO_INI  X227_SALDOS_CCUSTO_FUNC.vlr_saldo_ini%type;
    nVLR_SALDO_FIM  X227_SALDOS_CCUSTO_FUNC.vlr_saldo_fim%type;
    cIND_DEB_CRED_ANT     X227_SALDOS_CCUSTO_FUNC.ind_saldo_ini%type;
    cIND_DEB_CRED_ATU     X227_SALDOS_CCUSTO_FUNC.ind_saldo_fim%type;
    nContador_X226     integer :=0;
    nContador_X227     integer :=0;

    BEGIN
      IF pTipoEncerramento = '1' THEN
        FOR rSaldo_Novo_X227 IN Saldo_Novo_X227 (pEmpresa,pEstab,pCompetencia)
        LOOP
          BEGIN
            SELECT vlr_saldo_fim, ind_saldo_fim INTO nVLR_SALDO_INI, cIND_DEB_CRED_ANT
            FROM X227_SALDOS_CCUSTO_FUNC
            JOIN x2002_plano_contas x2002 ON x2002.ident_conta = X227_SALDOS_CCUSTO_FUNC.ident_conta
            JOIN x2003_centro_custo x2003 ON x2003.ident_custo = X227_SALDOS_CCUSTO_FUNC.ident_custo 
            WHERE X227_SALDOS_CCUSTO_FUNC.cod_empresa = rSaldo_Novo_X227.cod_empresa
            AND X227_SALDOS_CCUSTO_FUNC.cod_estab     = rSaldo_Novo_X227.cod_estab
            AND X227_SALDOS_CCUSTO_FUNC.dat_saldo     = ADD_MONTHS(LAST_DAY(rSaldo_Novo_X227.data_operacao),-1)
            AND X227_SALDOS_CCUSTO_FUNC.ident_conta   = rSaldo_Novo_X227.ident_conta
            AND X227_SALDOS_CCUSTO_FUNC.ident_custo   = rSaldo_Novo_X227.ident_custo;
            --AND X227_SALDOS_CCUSTO_FUNC.ident_conta   = rSaldo_Novo_X227.Cod_Conta
            --AND X227_SALDOS_CCUSTO_FUNC.ident_custo   = rSaldo_Novo_X227.Cod_Custo;
          EXCEPTION WHEN NO_DATA_FOUND THEN
            nVLR_SALDO_INI := 0;
            cIND_DEB_CRED_ANT := 'D';
          END;

          IF cIND_DEB_CRED_ANT = 'D' THEN
            nVLR_SALDO_FIM := NVL(((nVLR_SALDO_INI  + rSaldo_Novo_X227.valor_debito) -  rSaldo_Novo_X227.valor_credito),0);
            IF nVLR_SALDO_FIM < 0 THEN
              cIND_DEB_CRED_ATU := 'C';
            ELSE
              cIND_DEB_CRED_ATU := 'D';
            END IF;
          ELSE
            nVLR_SALDO_FIM := NVL(((nVLR_SALDO_INI  + rSaldo_Novo_X227.valor_credito) -    rSaldo_Novo_X227.valor_debito),0);
            IF nVLR_SALDO_FIM < 0 THEN
               cIND_DEB_CRED_ATU := 'D';
            ELSE
               cIND_DEB_CRED_ATU := 'C';
            END IF;
          END IF;

          BEGIN
        /*
            UPDATE X227_SALDOS_CCUSTO_FUNC SET vlr_tot_cre      = rSaldo_Novo_X227.valor_credito,
                       vlr_tot_deb      = rSaldo_Novo_X227.valor_debito,
                       vlr_saldo_fim = ABS(nVLR_SALDO_FIM),
                       ind_saldo_fim   = cIND_DEB_CRED_ATU
            WHERE X227_SALDOS_CCUSTO_FUNC.cod_empresa = rSaldo_Novo_X227.cod_empresa
            AND X227_SALDOS_CCUSTO_FUNC.cod_estab     = rSaldo_Novo_X227.cod_estab
            AND X227_SALDOS_CCUSTO_FUNC.dat_saldo     = LAST_DAY(rSaldo_Novo_X227.data_operacao)
            AND X227_SALDOS_CCUSTO_FUNC.ident_conta   = rSaldo_Novo_X227.ident_conta
            AND X227_SALDOS_CCUSTO_FUNC.ident_custo   = rSaldo_Novo_X227.ident_custo;     
      */
      insert into safx227 (cod_empresa,
                           cod_estab,
                           dat_saldo,
                           cod_conta,
                           cod_custo,
                           vlr_saldo_ini,
                           ind_saldo_ini,
                           vlr_saldo_fim,
                           ind_saldo_fim,
                           vlr_tot_cre,
                           vlr_tot_deb)
      values (rSaldo_Novo_X227.cod_empresa,
                    rSaldo_Novo_X227.cod_estab,
          to_char(LAST_DAY(rSaldo_Novo_X227.data_operacao),'yyyymmdd'), 
          (select cod_conta from x2002_plano_contas where ident_conta = rSaldo_Novo_X227.ident_conta),
          (select cod_custo from x2003_centro_custo where ident_custo = rSaldo_Novo_X227.ident_custo),
          to_char(nVLR_SALDO_INI*100),
          cIND_DEB_CRED_ANT,
          to_char(abs(nVLR_SALDO_FIM*100)),
          cIND_DEB_CRED_ATU,
          to_char(rSaldo_Novo_X227.valor_credito*100),
          to_char(rSaldo_Novo_X227.valor_debito*100));
            Lib_Proc.Add_Log('Erro de Execucao: Etapa (UPDATE Saldo Novo X227) ' || Sqlerrm, 1);
          END;
          COMMIT;

          nContador_X227 := nContador_X227 + 1;
          mLinha := '';
          mLinha := lib_str.w(mLinha, 'X227', 1);
          mLinha := lib_str.w(mLinha, rSaldo_Novo_X227.Cod_Estab, 8);
          mLinha := lib_str.w(mLinha, TO_CHAR(rSaldo_Novo_X227.data_operacao,'DD/MM/RRRR'), 16);
          mLinha := lib_str.w(mLinha, rSaldo_Novo_X227.Cod_Conta,28);
          mLinha := lib_str.w(mLinha, rSaldo_Novo_X227.Cod_Custo,45);
          mLinha := lib_str.w(mLinha, cIND_DEB_CRED_ANT,62);
          mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_INI, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),72);
          mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X227.Valor_Credito, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),89);
          mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X227.Valor_Debito, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),106);
          mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_FIM, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),123);
          mLinha := lib_str.w(mLinha, cIND_DEB_CRED_ATU,140);
          lib_proc.add(mLinha, ptipo => 1);
        END LOOP;
      END IF;

      nVLR_SALDO_INI := 0;
      cIND_DEB_CRED_ANT   := 0;

      nVLR_SALDO_FIM := 0;
      cIND_DEB_CRED_ATU   := 0;

      FOR rSaldo_Novo_X226 IN Saldo_Novo_X226 (pEmpresa,pEstab,pCompetencia)
      LOOP
    nContador_X226 := nContador_X226 + 1;
    BEGIN
      SELECT vlr_saldo_fim, ind_saldo_fim INTO nVLR_SALDO_INI, cIND_DEB_CRED_ANT
      FROM X226_SALDOS_FUNC
    JOIN x2002_plano_contas x2002 ON x2002.ident_conta = X226_SALDOS_FUNC.ident_conta
      WHERE X226_SALDOS_FUNC.cod_empresa = rSaldo_Novo_X226.cod_empresa
      AND X226_SALDOS_FUNC.cod_estab     = rSaldo_Novo_X226.cod_estab
      AND X226_SALDOS_FUNC.data_operacao    = ADD_MONTHS(LAST_DAY(rSaldo_Novo_X226.data_operacao),-1)
      --AND X226_SALDOS_FUNC.ident_conta   = rSaldo_Novo_X226.ident_conta
    AND x2002.cod_conta = rSaldo_Novo_X226.Cod_Conta;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      nVLR_SALDO_INI := 0;
      cIND_DEB_CRED_ANT := 'D';
    END;
    COMMIT;
    IF cIND_DEB_CRED_ANT = 'D' THEN
      nVLR_SALDO_FIM := NVL(((nVLR_SALDO_INI  + rSaldo_Novo_X226.valor_debito) -  rSaldo_Novo_X226.valor_credito),0);
      IF nVLR_SALDO_FIM < 0 THEN
      cIND_DEB_CRED_ATU := 'C';
      ELSE
      cIND_DEB_CRED_ATU := 'D';
      END IF;
    ELSE
      nVLR_SALDO_FIM := NVL(((nVLR_SALDO_INI  + rSaldo_Novo_X226.valor_credito) -    rSaldo_Novo_X226.valor_debito),0);
      IF nVLR_SALDO_FIM < 0 THEN
      cIND_DEB_CRED_ATU := 'D';
      ELSE
      cIND_DEB_CRED_ATU := 'C';
      END IF;
    END IF;
    BEGIN
      /*
      UPDATE X226_SALDOS_FUNC SET vlr_tot_cre   = rSaldo_Novo_X226.valor_credito,
        vlr_tot_deb   = rSaldo_Novo_X226.valor_debito,
        vlr_saldo_fim = ABS(nVLR_SALDO_FIM),
        ind_saldo_fim = cIND_DEB_CRED_ATU
      WHERE X226_SALDOS_FUNC.cod_empresa = rSaldo_Novo_X226.cod_empresa
      AND X226_SALDOS_FUNC.cod_estab     = rSaldo_Novo_X226.cod_estab
      AND X226_SALDOS_FUNC.data_operacao    = LAST_DAY(rSaldo_Novo_X226.data_operacao)
      AND X226_SALDOS_FUNC.ident_conta   = rSaldo_Novo_X226.ident_conta;
      */
      insert into safx226 (cod_empresa,
                           cod_estab,
                           cod_conta,
                           data_operacao,
                           vlr_saldo_ini,
                           ind_saldo_ini,
                           vlr_saldo_fim,
                           ind_saldo_fim,
                           vlr_tot_cre,
                           vlr_tot_deb) 
      values (rSaldo_Novo_X226.cod_empresa,
                    rSaldo_Novo_X226.cod_estab,
          (select cod_conta from x2002_plano_contas where ident_conta = rSaldo_Novo_X226.ident_conta),
          to_char(LAST_DAY(rSaldo_Novo_X226.data_operacao),'yyyymmdd'),
          to_char(nVLR_SALDO_INI*100),
          cIND_DEB_CRED_ANT,
          to_char(abs(nVLR_SALDO_FIM*100)),
          cIND_DEB_CRED_ATU,
          to_char(rSaldo_Novo_X226.valor_credito*100),
          to_char(rSaldo_Novo_X226.valor_debito*100));
    EXCEPTION WHEN OTHERS THEN
      Lib_Proc.Add_Log('Erro de Execucao: Etapa (UPDATE Saldo Novo X226) ' || Sqlerrm, 1);
    END;
    COMMIT;
    mLinha := '';
    mLinha := lib_str.w(mLinha, 'X226', 1);
    mLinha := lib_str.w(mLinha, rSaldo_Novo_X226.Cod_Estab, 8);
    mLinha := lib_str.w(mLinha, TO_CHAR(rSaldo_Novo_X226.data_operacao,'DD/MM/RRRR'), 16);
    mLinha := lib_str.w(mLinha, rSaldo_Novo_X226.Cod_Conta,28);
    mLinha := lib_str.w(mLinha, ' ',45);
    mLinha := lib_str.w(mLinha, cIND_DEB_CRED_ANT,62);
    mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_INI, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),72);
    mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X226.Valor_Credito, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),89);
    mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X226.Valor_Debito, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),106);
    mLinha := lib_str.w(mLinha, REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_FIM, 'FM9G999G999G990D00')),'.','-'),',','.'),'-',','),123);
    mLinha := lib_str.w(mLinha, cIND_DEB_CRED_ATU,140);
    lib_proc.add(mLinha, ptipo => 1);
      END LOOP;
  END Recalcula_Saldo_Novo;

  FUNCTION EXECUTAR(pEmpresa varchar2,
            pEstab varchar2,
            pCompetencia date,
            pConta varchar2,
            pTipo varchar2,
        pTipoEncerramento varchar2) RETURN NUMBER IS

    nContador         integer :=1;
    proc_id         lib_processo.proc_id%type;
    vlogmsg         varchar2(1000) := '';
    v_cnpj         varchar2(40);
    v_razao_social     varchar2(400);
    cCabecalho         varchar2(4000);
    nPosicao         integer :=1;
    --nTotal_Excluido     integer :=0;

  BEGIN
    -- Cria Processo
    proc_id := LIB_PROC.new('Z_FECH_CONT_FUNC_CPROC');
    lib_proc.add_tipo(proc_id, 1, 'Z_FECH_CONT_FUNC_CPROC', 1);

    BEGIN
      SELECT razao_social,
         substr(cgc,1,2)||'.'||substr(cgc,3,3)||'.'||substr(cgc,6,3)||'/'||substr(cgc,9,4)||'-'||substr(cgc,13,2) cgc
    INTO v_razao_social, v_cnpj
      FROM estabelecimento
      WHERE cod_empresa = pEmpresa
      AND ind_matriz_filial = 'M';
    END;

    --Lib_Proc.Add_Log('ident_conta: ' || pConta, 1);
    --Inicio Cabeçalho
    mlinha := '';
    lib_proc.add_header('Geracao do Fechamento Contabil - Resumo dos Saldos', ptipo_rel => 1);
    lib_proc.add_header('Empresa: '||pEmpresa||' - CNPJ: ' || v_cnpj||' - '||v_razao_social, ptipo_rel => 1);
    lib_proc.add_header('Emissao: ' || to_char(SYSDATE,'dd/mm/yyyy hh24:mi:ss'), ptipo_rel => 1);
    lib_proc.add_header(mLinha, ptipo_rel => 1);
    mlinha := '';

    cCabecalho := 'Origem,Estab. ,Data         ,Cod. Conta      ,Cod. Custo      ,D/C Ant. ,Saldo Anterior  ,Total Credito   ,Total Debito    ,Saldo Atual     ,D/C Atual';
    FOR rRecord IN rHeader(cCabecalho)
    LOOP
      -- lib_proc.add_log(rRecord.campo ||': '|| nPosicao,1);
      mlinha := lib_str.w(mlinha,rRecord.campo,nPosicao);
      nPosicao := nPosicao + LENGTH(rRecord.campo)+1;
    END LOOP;
    lib_proc.add_header(mlinha, ptipo_rel => 1);
    mLinha := '';
    --Fim Cabeçalho
    --nTotal_Excluido := 0;    
/*      BEGIN
        DELETE FROM X225_CONTABIL_FUNC
        WHERE cod_empresa = pEmpresa
        AND cod_estab = pEstab
        AND (data_operacao BETWEEN TO_DATE(pCompetencia,'DD/MM/RRRR') AND LAST_DAY(TO_DATE(pCompetencia,'DD/MM/RRRR')))
          AND tipo_lancto = 'E';
          nTotal_Excluido := SQL%ROWCOUNT;
      EXCEPTION WHEN OTHERS THEN
          Lib_Proc.Add_Log('Erro de Execucao - Etapa (Inicializacao - Exclusao): ' || Sqlerrm, 1);
      END;
      COMMIT;

      BEGIN
        IF pTipoEncerramento = '1' THEN 
          UPDATE X227_SALDOS_CCUSTO_FUNC
          SET vlr_saldo_fim = vlr_saldo_ini,
              ind_saldo_fim = ind_saldo_ini,
              vlr_tot_deb = 0,
              vlr_tot_cre = 0
          WHERE cod_empresa = pEmpresa
          AND cod_estab = pEstab 
          AND X227_SALDOS_CCUSTO_FUNC.dat_saldo = LAST_DAY(pCompetencia);
        END IF;        

        UPDATE X226_SALDOS_FUNC 
        SET vlr_saldo_fim = vlr_saldo_ini,
            ind_saldo_fim = ind_saldo_ini,
            vlr_tot_cre = 0,
            vlr_tot_deb = 0
        WHERE cod_empresa = pEmpresa
        AND cod_estab = pEstab
        AND data_operacao = LAST_DAY(pCompetencia);
      END;
      COMMIT;

      Lib_Proc.Add_Log('Registro Excluidos: ' || nTotal_Excluido, 1);
      Recalcula_Saldo_Novo (pEmpresa, pEstab, pCompetencia, pTipoEncerramento);
      mLinha := ' ';
      lib_proc.add(mLinha, ptipo => 1);
      mLinha := lib_str.w(mLinha, 'Total de Registros Excluídos do Tipo E: '||nTotal_Excluido, 30);
      lib_proc.add(mLinha, ptipo => 1);
      mLinha := ' ';

*/    
    IF pTipo = '1' THEN -- 1=Gerar Encerramento (Parte 1)
    FOR rSaldo IN Saldo (pEmpresa,pEstab,pCompetencia,pTipoEncerramento)
    LOOP
      BEGIN
          /*
        INSERT INTO X225_CONTABIL_FUNC (cod_empresa,
        cod_estab,
        data_operacao,
        ident_conta,
        ind_deb_cre,
        arquivamento,
        ident_contra_part,
        ident_custo,
        histcompl,
        vlr_lancto,
        num_processo,
        ind_gravacao,
        num_lancamento,
        tipo_lancto)
        VALUES (rSaldo.Cod_Empresa,
        rSaldo.Cod_Estab,
        rSaldo.Dat_Saldo,
        rSaldo.Ident_Conta,
        (CASE WHEN rSaldo.Ind_Saldo_Fim = 'D' THEN 'C' ELSE 'D' END),
        'E-' ||rSaldo.cod_estab||'-'||LPAD(nContador,10,0),
        pConta,
        rSaldo.Ident_Custo,
        'Transf. resuldado - Exercício: ' || to_char(pCompetencia, 'mm/rrrr'),
        ABS(rSaldo.Vlr_Saldo_Fim),
        '0',
        1,
        'E' || rSaldo.Cod_Estab || TO_CHAR(pCompetencia,'MMRRRR'),
        'E');
        */
        insert into safx225 (cod_empresa,
                           cod_estab,
                           data_operacao,
                           cod_conta,
                           ind_deb_cre,
                           arquivamento,
                           vlr_lancto,
                           contra_part,
                           centro_custo,
                           histcompl,
                           num_lancamento,
                           tipo_lancto)
        values (rSaldo.Cod_Empresa,
                rSaldo.Cod_Estab,
                        to_char(rSaldo.Dat_Saldo,'yyyymmdd'),
            (select cod_conta from x2002_plano_contas where ident_conta = rSaldo.Ident_Conta),
            (CASE WHEN rSaldo.Ind_Saldo_Fim = 'D' THEN 'C' ELSE 'D' END),
            'E-' ||rSaldo.cod_estab||'-'||LPAD(nContador,10,0),
            to_char(ABS(rSaldo.Vlr_Saldo_Fim)*100),
            (select cod_conta from x2002_plano_contas where ident_conta = pConta),
            (select cod_custo from x2003_centro_custo where ident_custo = rSaldo.Ident_Custo),
            'Transf. resultado - Exercício: ' || to_char(pCompetencia, 'mm/rrrr'),
            'E' || rSaldo.Cod_Estab || TO_CHAR(pCompetencia,'MMRRRR'),
            'E');
      EXCEPTION WHEN OTHERS THEN
        Lib_Proc.Add_Log('Erro de Execucao: Etapa (Insert Saldos X225)' || Sqlerrm, 1);
        Lib_Proc.Add_Log('Cod_Empresa: ' || NVL(rSaldo.Cod_Empresa,' '), 1);
        Lib_Proc.Add_Log('Cod_Estab: ' || rSaldo.Cod_Estab, 1);
        Lib_Proc.Add_Log('Dat_Saldo: ' || rSaldo.Dat_Saldo, 1);
        Lib_Proc.Add_Log('Ident_Conta: ' || rSaldo.Ident_Conta, 1);
        Lib_Proc.Add_Log('Ind_Saldo_Fim: ' || rSaldo.Ind_Saldo_Fim, 1);
        Lib_Proc.Add_Log('Arquivamento: ' || ('E-' ||rSaldo.cod_estab||'-'||LPAD(nContador,10,0)), 1);

        Lib_Proc.Add_Log('--', 1);
        Lib_Proc.Add_Log(rSaldo.Cod_Empresa,1);
        Lib_Proc.Add_Log(rSaldo.Cod_Estab,1);
        Lib_Proc.Add_Log(rSaldo.Dat_Saldo,1);
        Lib_Proc.Add_Log(rSaldo.Ident_Conta,1);
        Lib_Proc.Add_Log(pConta,1);
        Lib_Proc.Add_Log(rSaldo.Ident_Custo,1);
        Lib_Proc.Add_Log('Transf. resuldado - Exercício: ' || to_char(pCompetencia, 'mm/rrrr'),1);
        Lib_Proc.Add_Log(ABS(rSaldo.Vlr_Saldo_Fim),1);
        Lib_Proc.Add_Log('0',1);
        Lib_Proc.Add_Log(1,1);
        Lib_Proc.Add_Log('E' || rSaldo.Cod_Estab || TO_CHAR(pCompetencia,'MMRRRR'),1);
        Lib_Proc.Add_Log('E',1);
      END;
      COMMIT;
      nContador := nContador + 1;
    END LOOP;
     insert into safx225 (cod_empresa, cod_estab, data_operacao, cod_conta, ind_deb_cre, 
                          arquivamento, contra_part, centro_custo, histcompl, vlr_lancto, num_lancamento, tipo_lancto)
      select x225.cod_empresa,
      x225.cod_estab,
      to_char(x225.data_operacao,'yyyymmdd'),
      (select cod_conta from x2002_plano_contas where ident_conta = x225.ident_conta),
      x225.ind_deb_cre,
      x225.arquivamento,
      (select cod_conta from x2002_plano_contas where ident_conta = x225.ident_contra_part),
      (select cod_custo from x2003_centro_custo where ident_custo = x225.ident_custo),
      x225.histcompl,
      to_char(ABS(x225.vlr_lancto)*100),
      x225.num_lancamento,
      x225.tipo_lancto
      from x225_contabil_func x225
      where x225.cod_empresa = pempresa
      and x225.cod_estab = pestab
      AND x225.data_operacao = LAST_DAY(TO_DATE(pCompetencia,'DD/MM/RRRR'))
      and x225.tipo_lancto = 'N';    
  ELSE  
      FOR rFechamento IN Fechamento (pEmpresa,pEstab,pCompetencia)
      LOOP
    BEGIN
      /*
      INSERT INTO X225_CONTABIL_FUNC (cod_empresa,
      cod_estab,
      data_operacao,
      ident_conta,
      ind_deb_cre,
      arquivamento,
      histcompl,
      vlr_lancto,
      num_processo,
      ind_gravacao,
      num_lancamento,
      tipo_lancto)
      VALUES (rFechamento.Cod_Empresa,
      rFechamento.Cod_Estab,
      rFechamento.data_operacao,
      pConta,
      'C',
      'E-' ||rFechamento.cod_estab||'- TOTAL',
      'Lancto. Total do Enc. ' || TO_CHAR(pCompetencia, 'mm/rrrr'),
      ABS(rFechamento.valor_debito),
      '0',
      1,
      'E' || rFechamento.Cod_Estab || TO_CHAR(pCompetencia,'MMRRRR'),
      'E');
      */
      insert into safx225 (cod_empresa,
           cod_estab,
           data_operacao,
           cod_conta,
           ind_deb_cre,
           arquivamento,
           vlr_lancto,
           histcompl,
           num_lancamento,
           tipo_lancto,
           centro_custo)
      values (rFechamento.Cod_Empresa,
        rFechamento.Cod_Estab,
        to_char(rFechamento.data_operacao,'yyyymmdd'),
        (select cod_conta from x2002_plano_contas where ident_conta = pConta),
        'C',
        'E-' ||rFechamento.cod_estab||'- TOTAL',
        to_char(ABS(rFechamento.valor_debito)*100),
        'Lancto. Total do Enc. ' || TO_CHAR(pCompetencia, 'mm/rrrr'),
        'E' || rFechamento.Cod_Estab || TO_CHAR(pCompetencia,'MMRRRR'),
        'E',
        'BR10');
    EXCEPTION WHEN OTHERS THEN
       Lib_Proc.Add_Log('Erro de Execucao: Etapa (Insert Total Encerramento X225 a Credito)' || Sqlerrm, 1);
    END;
    COMMIT;

    BEGIN
      /*
      INSERT INTO X225_CONTABIL_FUNC (cod_empresa,
      cod_estab,
      data_operacao,
      ident_conta,
      ind_deb_cre,
      arquivamento,
      histcompl,
      vlr_lancto,
      num_processo,
      ind_gravacao,
      num_lancamento,
      tipo_lancto)
      VALUES (rFechamento.Cod_Empresa,
      rFechamento.Cod_Estab,
      rFechamento.data_operacao,
      pConta,
      'D',
      'E-' ||rFechamento.cod_estab||'- TOTAL',
      'Lancto. Total do Enc. ' || TO_CHAR(pCompetencia, 'mm/rrrr'),
      ABS(rFechamento.valor_credito),
      '0',
      1,
      'E' || rFechamento.Cod_Estab || TO_CHAR(pCompetencia,'MMRRRR'),
      'E');
          */
      insert into safx225 (cod_empresa,
           cod_estab,
           data_operacao,
           cod_conta,
           ind_deb_cre,
           arquivamento,
           vlr_lancto,
           histcompl,
           num_lancamento,
           tipo_lancto,
           centro_custo)
      values (rFechamento.Cod_Empresa,
        rFechamento.Cod_Estab,
        to_char(rFechamento.data_operacao,'yyyymmdd'),
        (select cod_conta from x2002_plano_contas where ident_conta = pConta),
        'D',
        'E-' ||rFechamento.cod_estab||'- TOTAL',
        to_char(ABS(rFechamento.valor_credito)*100),
        'Lancto. Total do Enc. ' || TO_CHAR(pCompetencia, 'mm/rrrr'),
        'E' || rFechamento.Cod_Estab || TO_CHAR(pCompetencia,'MMRRRR'),
        'E',
        'BR10');     
    EXCEPTION WHEN OTHERS THEN
      Lib_Proc.Add_Log('Erro de Execucao: Etapa (Insert Total Encerramento X225 a Debito) ' || Sqlerrm, 1);
    END;
    COMMIT;
      END LOOP;
      mLinha := '';
      Recalcula_Saldo_Novo (pEmpresa, pEstab,pCompetencia,pTipoEncerramento);
      --lib_proc.add(mLinha, ptipo => 1);
      mLinha := '';
    END IF;
    lib_proc.add('');
    lib_proc.close();
    RETURN proc_id;
  EXCEPTION WHEN OTHERS THEN
      lib_proc.add_log('Erro ao executar procedimento:' || ' - ' || sqlerrm,1);
      lib_proc.add_log('Etapa: ' || vlogmsg, 1);
      lib_proc.close();
      RETURN proc_id;
  END Executar;
END;
/
