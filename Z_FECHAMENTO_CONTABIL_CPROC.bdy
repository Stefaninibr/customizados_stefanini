CREATE OR REPLACE PACKAGE BODY Z_FECHAMENTO_CONTABIL_CPROC is

  FUNCTION parametros RETURN VARCHAR2 IS
    pstr varchar2(5000);
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
                       'SELECT cod_empresa, cod_empresa||'' - ''||razao_social FROM empresa WHERE cod_empresa = ' ||
                       cCod_Empresa,
                       'S');
  
    Lib_Proc.Add_Param(Pstr,
                       'Estabelecimentos',
                       'Varchar2',
                       'ComboBox',
                       'S',
                       NULL,
                       NULL,
                       ' SELECT a.cod_estab,' ||
                       ' a.cod_estab || '' - '' || a.razao_social ' ||
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
                       'N',
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
                       '1=Gerar Encerramento (Parte 1),2=Recalcular Saldos (Parte 2)');
  
    Lib_Proc.Add_Param(pstr,
                       'Tipo de Encerramento',
                       'Varchar2',
                       'RadioButton',
                       'S',
                       '1',
                       NULL,
                       '1=SAFX80,2=SAFX02');
    lib_proc.add_param(pstr, ' ', 'Varchar2', 'TEXT', 'u', NULL);
    lib_proc.add_param(pstr,
                       'Stefanini IT Solutions - Procedimentos Customizados',
                       'Varchar2',
                       'TEXT',
                       'u');
    lib_proc.add_param(pstr, 'Versao  : 1.0', 'Varchar2', 'TEXT', 'u');
    return pstr;
  END parametros;

  FUNCTION tipo RETURN VARCHAR2 IS
  BEGIN
    return 'SPED ECD';
  END;

  FUNCTION nome RETURN VARCHAR2 IS
  BEGIN
    return 'Geração do Encerramento Contábil';
  END;

  FUNCTION descricao RETURN VARCHAR2 IS
  BEGIN
    return 'Processo para criação dos lançamentos de encerramento do exercício.';
  END;

  PROCEDURE Recalcula_Saldo_Novo(pEmpresa          varchar2,
                                 pEstab            varchar2,
                                 pCompetencia      date,
                                 pTipoEncerramento varchar2) IS
    nVLR_SALDO_CONT_ANT x80_saldos_ccusto.vlr_saldo_cont_ant%type;
    nVLR_SALDO_CONT_ATU x80_saldos_ccusto.vlr_saldo_cont_atu%type;
    cIND_DEB_CRED_ANT   x80_saldos_ccusto.ind_deb_cred_ant%type;
    cIND_DEB_CRED_ATU   x80_saldos_ccusto.ind_deb_cred_atu%type;
    nContador_X02       integer := 0;
    nContador_X80       integer := 0;
  
  BEGIN
  
    IF pTipoEncerramento = '1' THEN
    
      FOR rSaldo_Novo_X80 IN Saldo_Novo_X80(pEmpresa, pEstab, pCompetencia) LOOP
        BEGIN
          SELECT vlr_saldo_cont_atu, ind_deb_cred_atu
            INTO nVLR_SALDO_CONT_ANT, cIND_DEB_CRED_ANT
            FROM x80_saldos_ccusto
            JOIN x2002_plano_contas x2002
              ON x2002.ident_conta = x80_saldos_ccusto.ident_conta
            JOIN x2003_centro_custo x2003
              ON x2003.ident_custo = x80_saldos_ccusto.ident_custo
           WHERE x80_saldos_ccusto.cod_empresa =
                 rSaldo_Novo_X80.cod_empresa
             AND x80_saldos_ccusto.cod_estab = rSaldo_Novo_X80.cod_estab
             AND x80_saldos_ccusto.dat_saldo =
                 ADD_MONTHS(LAST_DAY(rSaldo_Novo_X80.data_saldo), -1)
             AND x80_saldos_ccusto.ident_conta =
                 rSaldo_Novo_X80.ident_conta
             AND x80_saldos_ccusto.ident_custo =
                 rSaldo_Novo_X80.ident_custo;
          --AND x80_saldos_ccusto.ident_conta   = rSaldo_Novo_X80.Cod_Conta
          --AND x80_saldos_ccusto.ident_custo   = rSaldo_Novo_X80.Cod_Custo;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            nVLR_SALDO_CONT_ANT := 0;
            cIND_DEB_CRED_ANT   := 'D';
        END;
      
        IF cIND_DEB_CRED_ANT = 'D' THEN
          nVLR_SALDO_CONT_ATU := NVL(((nVLR_SALDO_CONT_ANT +
                                     rSaldo_Novo_X80.valor_debito) -
                                     rSaldo_Novo_X80.valor_credito),
                                     0);
          IF nVLR_SALDO_CONT_ATU < 0 THEN
            cIND_DEB_CRED_ATU := 'C';
          ELSE
            cIND_DEB_CRED_ATU := 'D';
          END IF;
        ELSE
          nVLR_SALDO_CONT_ATU := NVL(((nVLR_SALDO_CONT_ANT +
                                     rSaldo_Novo_X80.valor_credito) -
                                     rSaldo_Novo_X80.valor_debito),
                                     0);
          IF nVLR_SALDO_CONT_ATU < 0 THEN
            cIND_DEB_CRED_ATU := 'D';
          ELSE
            cIND_DEB_CRED_ATU := 'C';
          END IF;
        END IF;
      
        BEGIN
          insert into safx80
            (cod_empresa,
             cod_estab,
             dat_saldo,
             cod_conta,
             cod_custo,
             vlr_saldo_cont_ant,
             ind_deb_cred_ant,
             vlr_tot_deb,
             vlr_tot_cred,
             vlr_saldo_cont_atu,
             ind_deb_cred_atu)
          values
            (rSaldo_Novo_X80.cod_empresa,
             rSaldo_Novo_X80.cod_estab,
             to_char(LAST_DAY(rSaldo_Novo_X80.data_saldo), 'yyyymmdd'),
             (select cod_conta
                from x2002_plano_contas
               where ident_conta = rSaldo_Novo_X80.ident_conta),
             (select cod_custo
                from x2003_centro_custo
               where ident_custo = rSaldo_Novo_X80.ident_custo),
             to_char(ABS(nVLR_SALDO_CONT_ANT) * 100),
             cIND_DEB_CRED_ANT,
             to_char(ABS(rSaldo_Novo_X80.valor_debito) * 100),
             to_char(ABS(rSaldo_Novo_X80.valor_credito) * 100),
             to_char(ABS(nVLR_SALDO_CONT_ATU) * 100),
             cIND_DEB_CRED_ATU);
        EXCEPTION
          WHEN OTHERS THEN
            Lib_Proc.Add_Log('Erro de Execucao: Etapa (UPDATE Saldo Novo X80) ' ||
                             Sqlerrm,
                             1);
        END;
        COMMIT;
      
        nContador_X80 := nContador_X80 + 1;
        mLinha        := '';
        mLinha        := lib_str.w(mLinha, 'X80', 1);
        mLinha        := lib_str.w(mLinha, rSaldo_Novo_X80.Cod_Estab, 8);
        mLinha        := lib_str.w(mLinha,
                                   TO_CHAR(rSaldo_Novo_X80.Data_Saldo,
                                           'DD/MM/RRRR'),
                                   16);
        mLinha        := lib_str.w(mLinha, rSaldo_Novo_X80.Cod_Conta, 28);
        mLinha        := lib_str.w(mLinha, rSaldo_Novo_X80.Cod_Custo, 45);
        mLinha        := lib_str.w(mLinha, cIND_DEB_CRED_ANT, 62);
        mLinha        := lib_str.w(mLinha,
                                   REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_CONT_ANT,
                                                                        'FM9G999G999G990D00')),
                                                           '.',
                                                           '-'),
                                                   ',',
                                                   '.'),
                                           '-',
                                           ','),
                                   72);
        mLinha        := lib_str.w(mLinha,
                                   REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X80.Valor_Credito,
                                                                        'FM9G999G999G990D00')),
                                                           '.',
                                                           '-'),
                                                   ',',
                                                   '.'),
                                           '-',
                                           ','),
                                   89);
        mLinha        := lib_str.w(mLinha,
                                   REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X80.Valor_Debito,
                                                                        'FM9G999G999G990D00')),
                                                           '.',
                                                           '-'),
                                                   ',',
                                                   '.'),
                                           '-',
                                           ','),
                                   106);
        mLinha        := lib_str.w(mLinha,
                                   REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_CONT_ATU,
                                                                        'FM9G999G999G990D00')),
                                                           '.',
                                                           '-'),
                                                   ',',
                                                   '.'),
                                           '-',
                                           ','),
                                   123);
        mLinha        := lib_str.w(mLinha, cIND_DEB_CRED_ATU, 140);
        lib_proc.add(mLinha, ptipo => 1);
      END LOOP;
    END IF;
  
    nVLR_SALDO_CONT_ANT := 0;
    cIND_DEB_CRED_ANT   := 0;
  
    nVLR_SALDO_CONT_ATU := 0;
    cIND_DEB_CRED_ATU   := 0;
  
    FOR rSaldo_Novo_X02 IN Saldo_Novo_X02(pEmpresa, pEstab, pCompetencia) LOOP
      nContador_X02 := nContador_X02 + 1;
      BEGIN
        SELECT vlr_saldo_fim, ind_saldo_fim
          INTO nVLR_SALDO_CONT_ANT, cIND_DEB_CRED_ANT
          FROM x02_saldos
          JOIN x2002_plano_contas x2002
            ON x2002.ident_conta = x02_saldos.ident_conta
         WHERE x02_saldos.cod_empresa = rSaldo_Novo_X02.cod_empresa
           AND x02_saldos.cod_estab = rSaldo_Novo_X02.cod_estab
           AND x02_saldos.data_saldo =
               ADD_MONTHS(LAST_DAY(rSaldo_Novo_X02.data_saldo), -1)
              --AND x02_saldos.ident_conta   = rSaldo_Novo_X02.ident_conta
           AND x2002.cod_conta = rSaldo_Novo_X02.Cod_Conta;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          nVLR_SALDO_CONT_ANT := 0;
          cIND_DEB_CRED_ANT   := 'D';
      END;
      COMMIT;
    
      IF cIND_DEB_CRED_ANT = 'D' THEN
        nVLR_SALDO_CONT_ATU := NVL(((nVLR_SALDO_CONT_ANT +
                                   rSaldo_Novo_X02.valor_debito) -
                                   rSaldo_Novo_X02.valor_credito),
                                   0);
        IF nVLR_SALDO_CONT_ATU < 0 THEN
          cIND_DEB_CRED_ATU := 'C';
        ELSE
          cIND_DEB_CRED_ATU := 'D';
        END IF;
      ELSE
        nVLR_SALDO_CONT_ATU := NVL(((nVLR_SALDO_CONT_ANT +
                                   rSaldo_Novo_X02.valor_credito) -
                                   rSaldo_Novo_X02.valor_debito),
                                   0);
        IF nVLR_SALDO_CONT_ATU < 0 THEN
          cIND_DEB_CRED_ATU := 'D';
        ELSE
          cIND_DEB_CRED_ATU := 'C';
        END IF;
      END IF;
      BEGIN
        insert into safx02
          (cod_empresa,
           cod_estab,
           cod_conta,
           data_saldo,
           vlr_saldo_ini,
           ind_saldo_ini,
           vlr_saldo_fim,
           ind_saldo_fim,
           vlr_tot_cre,
           vlr_tot_deb)
        values
          (rSaldo_Novo_X02.cod_empresa,
           rSaldo_Novo_X02.cod_estab,
           (select cod_conta
              from x2002_plano_contas
             where ident_conta = rSaldo_Novo_X02.ident_conta),
           to_char(LAST_DAY(rSaldo_Novo_X02.data_saldo), 'yyyymmdd'),
           to_char(ABS(nVLR_SALDO_CONT_ANT) * 100),
           cIND_DEB_CRED_ANT,
           to_char(ABS(nVLR_SALDO_CONT_ATU) * 100),
           cIND_DEB_CRED_ATU,
           to_char(ABS(rSaldo_Novo_X02.valor_credito) * 100),
           to_char(ABS(rSaldo_Novo_X02.valor_debito) * 100));
      EXCEPTION
        WHEN OTHERS THEN
          Lib_Proc.Add_Log('Erro de Execucao: Etapa (UPDATE Saldo Novo X02) ' ||
                           Sqlerrm,
                           1);
      END;
      COMMIT;
      mLinha := '';
      mLinha := lib_str.w(mLinha, 'X02', 1);
      mLinha := lib_str.w(mLinha, rSaldo_Novo_X02.Cod_Estab, 8);
      mLinha := lib_str.w(mLinha,
                          TO_CHAR(rSaldo_Novo_X02.Data_Saldo, 'DD/MM/RRRR'),
                          16);
      mLinha := lib_str.w(mLinha, rSaldo_Novo_X02.Cod_Conta, 28);
      mLinha := lib_str.w(mLinha, ' ', 45);
      mLinha := lib_str.w(mLinha, cIND_DEB_CRED_ANT, 62);
      mLinha := lib_str.w(mLinha,
                          REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_CONT_ANT,
                                                               'FM9G999G999G990D00')),
                                                  '.',
                                                  '-'),
                                          ',',
                                          '.'),
                                  '-',
                                  ','),
                          72);
      mLinha := lib_str.w(mLinha,
                          REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X02.Valor_Credito,
                                                               'FM9G999G999G990D00')),
                                                  '.',
                                                  '-'),
                                          ',',
                                          '.'),
                                  '-',
                                  ','),
                          89);
      mLinha := lib_str.w(mLinha,
                          REPLACE(REPLACE(REPLACE(TRIM(to_char(rSaldo_Novo_X02.Valor_Debito,
                                                               'FM9G999G999G990D00')),
                                                  '.',
                                                  '-'),
                                          ',',
                                          '.'),
                                  '-',
                                  ','),
                          106);
      mLinha := lib_str.w(mLinha,
                          REPLACE(REPLACE(REPLACE(TRIM(to_char(nVLR_SALDO_CONT_ATU,
                                                               'FM9G999G999G990D00')),
                                                  '.',
                                                  '-'),
                                          ',',
                                          '.'),
                                  '-',
                                  ','),
                          123);
      mLinha := lib_str.w(mLinha, cIND_DEB_CRED_ATU, 140);
      lib_proc.add(mLinha, ptipo => 1);
    END LOOP;
  
  END Recalcula_Saldo_Novo;

  FUNCTION EXECUTAR(pEmpresa          varchar2,
                    pEstab            varchar2,
                    pCompetencia      date,
                    pConta            varchar2,
                    pTipo             varchar2,
                    pTipoEncerramento varchar2) RETURN NUMBER IS
  
    nContador      integer := 1;
    proc_id        lib_processo.proc_id%type;
    vlogmsg        varchar2(1000) := '';
    v_cnpj         varchar2(40);
    v_razao_social varchar2(400);
    cCabecalho     varchar2(4000);
    nPosicao       integer := 1;
    --nTotal_Excluido     integer :=0;
  
  BEGIN
    -- Cria Processo
    proc_id := LIB_PROC.new('Z_FECHAMENTO_CONTABIL_CPROC');
    lib_proc.add_tipo(proc_id, 1, 'Z_FECHAMENTO_CONTABIL_CPROC', 1);
  
    BEGIN
      SELECT razao_social,
             substr(cgc, 1, 2) || '.' || substr(cgc, 3, 3) || '.' ||
             substr(cgc, 6, 3) || '/' || substr(cgc, 9, 4) || '-' ||
             substr(cgc, 13, 2) cgc
        INTO v_razao_social, v_cnpj
        FROM estabelecimento
       WHERE cod_empresa = pEmpresa
         AND ind_matriz_filial = 'M';
    END;
  
    --Lib_Proc.Add_Log('ident_conta: ' || pConta, 1);
    --Inicio Cabeçalho
    mlinha := '';
    lib_proc.add_header('Geracao do Fechamento Contabil - Resumo dos Saldos',
                        ptipo_rel => 1);
    lib_proc.add_header('Empresa: ' || pEmpresa || ' - CNPJ: ' || v_cnpj ||
                        ' - ' || v_razao_social,
                        ptipo_rel => 1);
    lib_proc.add_header('Emissao: ' ||
                        to_char(SYSDATE, 'dd/mm/yyyy hh24:mi:ss'),
                        ptipo_rel => 1);
    lib_proc.add_header(mLinha, ptipo_rel => 1);
    mlinha := '';
  
    cCabecalho := 'Origem,Estab. ,Data         ,Cod. Conta      ,Cod. Custo      ,D/C Ant. ,Saldo Anterior  ,Total Credito   ,Total Debito    ,Saldo Atual     ,D/C Atual';
    FOR rRecord IN rHeader(cCabecalho) LOOP
      -- lib_proc.add_log(rRecord.campo ||': '|| nPosicao,1);
      mlinha   := lib_str.w(mlinha, rRecord.campo, nPosicao);
      nPosicao := nPosicao + LENGTH(rRecord.campo) + 1;
    END LOOP;
    lib_proc.add_header(mlinha, ptipo_rel => 1);
    mLinha := '';
    --Fim Cabeçalho
    --nTotal_Excluido := 0;
    IF ptipo = '1' then
      FOR rSaldo IN Saldo(pEmpresa, pEstab, pCompetencia, pTipoEncerramento) LOOP
        BEGIN
          insert into safx01
            (cod_empresa,
             cod_estab,
             data_operacao,
             conta_deb_cred,
             ind_deb_cre,
             arquivamento,
             contra_part,
             centro_custo,
             histcompl,
             vlr_lancto,
             num_lancamento,
             tipo_lancto)
          values
            (rSaldo.Cod_Empresa,
             rSaldo.Cod_Estab,
             to_char(rSaldo.Dat_Saldo, 'yyyymmdd'),
             (select cod_conta
                from x2002_plano_contas
               where ident_conta = rSaldo.ident_conta),
             (CASE
               WHEN rSaldo.Ind_Saldo_Fim = 'D' THEN
                'C'
               ELSE
                'D'
             END),
             'E-' || rSaldo.cod_estab || '-' || LPAD(nContador, 10, 0),
             (select cod_conta
                from x2002_plano_contas
               where ident_conta = pConta),
             (select cod_custo
                from x2003_centro_custo
               where ident_custo = rSaldo.ident_custo),
             'Transf. resultado - Exercício: ' ||
             to_char(pCompetencia, 'mm/rrrr'),
             to_char(ABS(rSaldo.Vlr_Saldo_Fim) * 100),
             'E' || rSaldo.Cod_Estab || TO_CHAR(pCompetencia, 'MMRRRR'),
             'E');
        EXCEPTION
          WHEN OTHERS THEN
            Lib_Proc.Add_Log('Erro de Execucao: Etapa (Insert Saldos X01)' ||
                             Sqlerrm,
                             1);
            Lib_Proc.Add_Log('Cod_Empresa: ' ||
                             NVL(rSaldo.Cod_Empresa, ' '),
                             1);
            Lib_Proc.Add_Log('Cod_Estab: ' || rSaldo.Cod_Estab, 1);
            Lib_Proc.Add_Log('Dat_Saldo: ' || rSaldo.Dat_Saldo, 1);
            Lib_Proc.Add_Log('Ident_Conta: ' || rSaldo.Ident_Conta, 1);
            Lib_Proc.Add_Log('Ind_Saldo_Fim: ' || rSaldo.Ind_Saldo_Fim, 1);
            Lib_Proc.Add_Log('Arquivamento: ' || ('E-' || rSaldo.cod_estab || '-' ||
                             LPAD(nContador, 10, 0)),
                             1);
          
            Lib_Proc.Add_Log('--', 1);
            Lib_Proc.Add_Log(rSaldo.Cod_Empresa, 1);
            Lib_Proc.Add_Log(rSaldo.Cod_Estab, 1);
            Lib_Proc.Add_Log(rSaldo.Dat_Saldo, 1);
            Lib_Proc.Add_Log(rSaldo.Ident_Conta, 1);
            Lib_Proc.Add_Log(pConta, 1);
            Lib_Proc.Add_Log(rSaldo.Ident_Custo, 1);
            Lib_Proc.Add_Log('Transf. resuldado - Exercício: ' ||
                             to_char(pCompetencia, 'mm/rrrr'),
                             1);
            Lib_Proc.Add_Log(ABS(rSaldo.Vlr_Saldo_Fim), 1);
            Lib_Proc.Add_Log('0', 1);
            Lib_Proc.Add_Log(1, 1);
            Lib_Proc.Add_Log('E' || rSaldo.Cod_Estab ||
                             TO_CHAR(pCompetencia, 'MMRRRR'),
                             1);
            Lib_Proc.Add_Log('E', 1);
          
        END;
        COMMIT;
        nContador := nContador + 1;
      END LOOP;
    
      insert into safx01
        (cod_empresa,
         cod_estab,
         data_operacao,
         conta_deb_cred,
         ind_deb_cre,
         arquivamento,
         contra_part,
         centro_custo,
         histcompl,
         vlr_lancto,
         num_lancamento,
         tipo_lancto)
        select x01.cod_empresa,
               x01.cod_estab,
               to_char(x01.data_lancto, 'yyyymmdd'),
               (select cod_conta
                  from x2002_plano_contas
                 where ident_conta = x01.ident_conta),
               x01.ind_deb_cre,
               x01.arquivamento,
               (select cod_conta
                  from x2002_plano_contas
                 where ident_conta = x01.ident_contra_part),
               (select cod_custo
                  from x2003_centro_custo
                 where ident_custo = x01.ident_custo),
               x01.txt_histcompl,
               to_char(ABS(x01.vlr_lancto) * 100),
               x01.num_lancamento,
               x01.tipo_lancto
          from x01_contabil x01
         where x01.cod_empresa = pempresa
           and x01.cod_estab = pestab
           AND x01.data_lancto =
               LAST_DAY(TO_DATE(pCompetencia, 'DD/MM/RRRR'))
           and x01.tipo_lancto = 'N';
    ELSE
      FOR rFechamento IN Fechamento(pEmpresa, pEstab, pCompetencia) LOOP
        BEGIN
          insert into safx01
            (cod_empresa,
             cod_estab,
             data_operacao,
             conta_deb_cred,
             ind_deb_cre,
             arquivamento,
             histcompl,
             vlr_lancto,
             num_lancamento,
             tipo_lancto,
             centro_custo)
          values
            (rFechamento.Cod_Empresa,
             rFechamento.Cod_Estab,
             to_char(rFechamento.Data_Saldo, 'yyyymmdd'),
             (select cod_conta
                from x2002_plano_contas
               where ident_conta = pConta),
             'C',
             'E-' || rFechamento.cod_estab || '- TOTAL',
             'Lancto. Total do Enc. ' || TO_CHAR(pCompetencia, 'mm/rrrr'),
             to_char(ABS(rFechamento.valor_debito) * 100),
             'E' || rFechamento.Cod_Estab ||
             TO_CHAR(pCompetencia, 'MMRRRR'),
             'E',
             'BR10');
        EXCEPTION
          WHEN OTHERS THEN
            Lib_Proc.Add_Log('Erro de Execucao: Etapa (Insert Total Encerramento X01 a Credito)' ||
                             Sqlerrm,
                             1);
        END;
        COMMIT;
      
        BEGIN
          insert into safx01
            (cod_empresa,
             cod_estab,
             data_operacao,
             conta_deb_cred,
             ind_deb_cre,
             arquivamento,
             histcompl,
             vlr_lancto,
             num_lancamento,
             tipo_lancto,
             centro_custo)
          values
            (rFechamento.Cod_Empresa,
             rFechamento.Cod_Estab,
             to_char(rFechamento.Data_Saldo, 'yyyymmdd'),
             (select cod_conta
                from x2002_plano_contas
               where ident_conta = pConta),
             'D',
             'E-' || rFechamento.cod_estab || '- TOTAL',
             'Lancto. Total do Enc. ' || TO_CHAR(pCompetencia, 'mm/rrrr'),
             to_char(ABS(rFechamento.valor_credito) * 100),
             'E' || rFechamento.Cod_Estab ||
             TO_CHAR(pCompetencia, 'MMRRRR'),
             'E',
             'BR10');
        EXCEPTION
          WHEN OTHERS THEN
            Lib_Proc.Add_Log('Erro de Execucao: Etapa (Insert Total Encerramento X01 a Debito) ' ||
                             Sqlerrm,
                             1);
        END;
        COMMIT;
      END LOOP;
      mLinha := '';
      Recalcula_Saldo_Novo(pEmpresa,
                           pEstab,
                           pCompetencia,
                           pTipoEncerramento);
    END IF;
  
    lib_proc.add('');
  
    lib_proc.close();
    RETURN proc_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      lib_proc.add_log('Erro ao executar procedimento:' || ' - ' ||
                       sqlerrm,
                       1);
      lib_proc.add_log('Etapa: ' || vlogmsg, 1);
      lib_proc.close();
      RETURN proc_id;
  END Executar;

END Z_FECHAMENTO_CONTABIL_CPROC;
/
