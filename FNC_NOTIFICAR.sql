FUNCTION FNC_NOTIFICAR(P_ORGAO_AUTUADOR VARCHAR2,
                           P_ORGAO_AR       VARCHAR2,
                           P_DATA_POSTAGEM  VARCHAR2,
                           P_REMESSA_AR     VARCHAR2,
                           P_UF_OPERADOR    VARCHAR2,
                           P_OPERADOR       VARCHAR2,
                           P_ESTACAO        VARCHAR2,
                           P_FUNCAO         VARCHAR2,
                           P_SESSAO         VARCHAR2) RETURN TCURSOR IS
        RETORNO             TCURSOR;
        QTD                 NUMBER;
        NUMERO_TAREFA       VARCHAR2(14);
        USA_FATURAMENTO     VARCHAR2(1);
        REMESSA_NOTIFICACAO VARCHAR2(8);
        TMP                 VARCHAR2(255);
        ARQUIVO_CORREIO     VARCHAR2(50);
        NUM_AR              VARCHAR2(13);
        SIGLA_AR            VARCHAR2(2);
        UTILIZA_AR_DIGITAL  VARCHAR2(1);
        UF_LOCAL            VARCHAR2(2);
        V_SERV_FATURAMENTO  VARCHAR2(15);
        IMPRIME_FORMULARIO  VARCHAR2(1);
        IMPRIME_PROPRIETARIO_INFRATOR VARCHAR2(1);
        IDENT_CLIENTE_AR    VARCHAR2(3);
        VERSAO_EMISSOR      VARCHAR2(30);
        GERA_ARQUIVO_CORREIO_2019 VARCHAR2(1);
--      ENVIA_RENAINF       VARCHAR2(1);
        -- VARIAVEIS ENVIO CORREIOS VIA FAC
        CAC_FAC             VARCHAR2(8);
        LOTE_FAC            VARCHAR2(5);
        SEQ_LOTE_FAC        NUMBER;
        DR_FAC              VARCHAR2(2);
    BEGIN
        -- GATO PARA NAO ENVIAR AS MULTAS DO RENAINF
--        ENVIA_RENAINF := PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || P_UF_OPERADOR || '/ENVIAMULTASRENAINF');
    
        -- VERIFICA SE O ORGAO USA FATURAMENTO

        SELECT PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/UFLOCAL')
        INTO UF_LOCAL
        FROM DUAL I;        
        
        CASE 
          WHEN UF_LOCAL = 'AC' THEN
             IF TO_DATE(P_DATA_POSTAGEM, 'YYYY-MM-DD') > TO_DATE('2023-09-24', 'YYYY-MM-DD') THEN
                  VERSAO_EMISSOR := PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || UF_LOCAL || '/' || P_ORGAO_AUTUADOR || '/VERSAOEMISSORNOVO');
             ELSE
                  VERSAO_EMISSOR := PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || UF_LOCAL || '/' || P_ORGAO_AUTUADOR || '/VERSAOEMISSOR');
             END IF;
        ELSE
                  VERSAO_EMISSOR := PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || UF_LOCAL || '/' || P_ORGAO_AUTUADOR || '/VERSAOEMISSOR');
        END CASE; 
        
        IF UF_LOCAL = 'AC' THEN
           UTILIZA_AR_DIGITAL := PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || UF_LOCAL || '/' || P_ORGAO_AUTUADOR || '/UTILIZAARDIGITAL');   
        ELSE
           UTILIZA_AR_DIGITAL := PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || UF_LOCAL || '/UTILIZAARDIGITAL');
        END IF;
                
        USA_FATURAMENTO := PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || P_UF_OPERADOR || '/' ||
                                                                       P_ORGAO_AUTUADOR || '/FATURAMENTO');
                                                                       
        -- VERIFICA SE IMPRIME SEMPRE O FORMULARIO DE IDENTIFICACAO DE CONDUTOR
        IMPRIME_FORMULARIO := PKG_SPA_CONSULTAR_VALOR .BUSCA_VALOR_SIMPLES('SGM/' || UF_LOCAL || '/' ||
                                                                       P_ORGAO_AUTUADOR || '/IMPRIMEFORMULARIOCONDUTORSEMPRE');   
                                                               
        -- VERIFICA SE IMPRIME DADOS DO INFRATOR (PROPRIETARIO) QUANDO MULTA DE CONDUTOR E CONDUTOR N�O IDENTIFICADO
        IMPRIME_PROPRIETARIO_INFRATOR := PKG_SPA_CONSULTAR_VALOR .BUSCA_VALOR_SIMPLES('SGM/' || UF_LOCAL || '/' ||
                                                                       P_ORGAO_AUTUADOR || '/IMPRIMEINFRATORPROPRIETARIO');   
                                                               
                                                                
        -- PEGA O NUMERO DA REMESSA DE NOTIFICACAO
        SELECT LPAD(MULTA.SEQ_SGM_MMA1NOTI_REMESSA.NEXTVAL,
                    8,
                    0)
          INTO REMESSA_NOTIFICACAO
          FROM DUAL;
          
        IF UTILIZA_AR_DIGITAL = 'N' THEN 
          -- PEGA O NUMERO DA LOTE FAC CORREIOS E SETA SEQUENCIAL LOTE = 0
          SELECT LPAD(MULTA.SEQ_LOTE_FAC_CORREIOS.NEXTVAL,
                      5,
                      0)
            INTO LOTE_FAC
            FROM DUAL;   
          
          SEQ_LOTE_FAC := 0; 
        END IF;
        
    
        -- SELECIONA MULTAS VALIDAS PARA NOTIFICA��O E POPULA A TABELA TEMPOR�RIA
        IF UTILIZA_AR_DIGITAL = 'N' THEN
          INSERT INTO T_SGM_NOTIFICACAO
              (ORGAO_AUTUADOR,
               DESC_ORGAO_AUTUADOR,
               MU_MUL_NUMERO,
               MU_MUL_SEQUENCIAL,
               DATA_SITUACAO,
               DT_PESSOA,
               NOME_PROPRIETARIO,
               NOME_LOGRADOURO,
               COMPLEMENTO_LOGRADOURO,
               ENDERECO_BAIRRO,
               MUNICIPIO_LOGRADOURO,
               UF_LOGRADOURO,
               ENDERECO_CEP,
               CPF_CGC,
               NOME_MARCA_MODELO,
               CHASSI,
               PLACA,
               PLACA_UF,
               ABREV_COMBUSTIVEL,
               ANO_FABRICACAO,
               ANO_MODELO,
               ESPECIE,
               COR,
               RENAVAM,
               DT_MUNIC_CODIGO,
               DT_MUNIC_DESC,
               DATA,
               HORA,
               INFRACAO,
               INFRACAO_DESDOBRAMENTO,
               INFRACAO_DESCRICAO,
               INFRACAO_REGULAMENTO,
               DESCRICAO_LOCAL,
               OBSERVACAO_MULTA,
               AGENTE,
               DOC_INFRATOR,
               UF_INFRATOR,
               NOME_INFRATOR,
               MM_GRM_PONTOS,
               MM_GRM_DESCRICAO,
               COD_RENAINF,
               COD_RETORNO,
               VALOR,
               VALOR_COM_DESCONTO,
               COD_EQUIPAMENTO,
               MEDICAO_PERMITIDA,
               MEDICAO_AFERIDA,
               MEDICAO_CONSIDERADA,
               UNIDADE_MEDIDA,
               NRO_NOTIFICACAO,
               DATA_LIMITE_DEF_PREVIA,
               NUMERO_AR,
               REMESSA_AR,
               REMESSA_NOTIFICACAO,
               MU_REM_NUMERO,
               DATA_AUTUACAO,
               DATA_POSTAGEM,
               NUMERO_AR_CORREIO,
               NOME_CONDUTOR, 
               CPF_CONDUTOR, 
               DOC_CONDUTOR, 
               UF_DOC_CONDUTOR, 
               TIPO_DOC_CONDUTOR, 
               DESC_TIPO_DOC_CONDUTOR, 
               CONDUTOR_HABILITADO,
               IMPRIME_FORMULARIO_CONDUTOR_SN,
               MULTA_PESSOA,
               SNE_ATIVO,
               DATA_ADESAO_SNE,
               ENDERECO_NUMERO,
               SUSPENSIVA
               )
              SELECT B.COD_ORGAO_AUTUADOR,
                     B.DESC_ORGAO_AUTUADOR,
                     B.NUMERO_AUTO,
                     B.NUMERO_SEQUENCIAL,
                     B.DATA_SITUACAO,
                     B.DT_PESSOA,
                     B.NOME_PROPRIETARIO,
                     B.ENDERECO_PROPRIETARIO,
                     B.COMPLEMENTO_ENDERECO_PROP || ' ' || TRIM(B.ENDERECO_NUMERO_PROP),
                     B.BAIRRO_PROPRIETARIO,
                     B.CIDADE_PROPRIETARIO,
                     B.UF_PROPRIETARIO,
                     B.CEP_PROPRIETARIO,
                     B.CPF_CGC_PROPRIETARIO,
                     B.DESC_MARCA_MODELO,
                     B.CHASSI,
                     B.PLACA,
                     B.UF_PLACA,
                     B.COMBUSTIVEL,
                     B.ANO_FABRICACAO,
                     B.ANO_MODELO,
                     B.DESC_ESPECIE,
                     B.DESC_COR,
                     B.RENAVAM,
                     B.COD_MUNIC_COMETIMENTO, -- Alterado para 5 posi��es de novo com DV Tabela TOM no Final - ALtera��o na view (V_NOTIFICACAO_PENALIDADE_AIT)
                     B.DESC_MUNIC_COMETIMENTO,
                     B.DATA_COMETIMENTO,
                     B.HORA_COMETIMENTO,
                     CASE WHEN LENGTH(B.INFRACAO) = 5 AND SUBSTR(B.INFRACAO,1,1) = '0' 
                          THEN SUBSTR(B.INFRACAO,2)
                          ELSE B.INFRACAO
                     END INFRACAO, -- c�d infra��o impresso com 4 d�gitos, sem o zero a esquerda
                     B.INFRACAO_DESDOBRAMENTO,
                     B.INFRACAO_DESCRICAO,
                     B.INFRACAO_REGULAMENTO,
                     B.LOCAL_INFRACAO || B.COMPLEMENTO_LOCAL_INFRACAO,
                     B.OBSERVACAO_MULTA,
                     B.AGENTE,
                     CASE WHEN B.MULTA_PESSOA = 'S' THEN
                       B.DOC_INFRATOR
                     ELSE
                       CASE WHEN NVL(TRIM(IMPRIME_PROPRIETARIO_INFRATOR),'S') = 'N' AND
                                 B.TIPO_INFRATOR = '1' AND
                                 NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN NULL
                            ELSE M.MU_MUL_NUMERO_CNH
                       END 
                     END DOC_INFRATOR,
                     CASE WHEN NVL(TRIM(IMPRIME_PROPRIETARIO_INFRATOR),'S') = 'N' AND
                               B.TIPO_INFRATOR = '1' AND
                               NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN NULL
                          ELSE M.MU_MUL_CNH_UF
                     END UF_INFRATOR,
                     CASE WHEN B.MULTA_PESSOA = 'S' THEN
                       B.NOME_INFRATOR
                     ELSE
                       CASE WHEN NVL(TRIM(IMPRIME_PROPRIETARIO_INFRATOR),'S') = 'N' AND
                                 B.TIPO_INFRATOR = '1' AND
                                 NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN NULL
                            ELSE FNC_RETIRA_CARACTER_ESPECIAL(REPLACE(M.MU_MUL_NOME_INFRATOR, '&', 'E'))
                       END 
                     END NOME_INFRATOR,
                     B.PONTOS_INFRACAO,
                     B.GRUPO_INFRACAO,
                     B.COD_RENAINF,
                     T.COD_RETORNO,
                     B.VALOR,
                     B.VALOR_COM_DESCONTO,
                     B.RADAR,
                     B.MEDICAO_PERMITIDA,
                     B.MEDICAO_AFERIDA,
                     B.MEDICAO_CONSIDERADA,
                     B.UNIDADE_MEDIDA,
                     B.NUMERO_NOTIFICACAO,
                     B.DATA_LIMITE_DEFESA,
                     CASE WHEN TRIM(P_ORGAO_AR) IS NULL OR TRIM(B.NOME_PROPRIETARIO) IS NULL OR
                               -- valida o endere�o 
                               (B.UF_PROPRIETARIO = P_UF_OPERADOR AND LENGTH(TRIM(B.ENDERECO_PROPRIETARIO || B.COMPLEMENTO_ENDERECO_PROP)) <= 2) OR
                               (B.UF_PROPRIETARIO <> P_UF_OPERADOR AND TRIM(B.ENDERECO_PROPRIETARIO || B.COMPLEMENTO_ENDERECO_PROP) IS NULL) OR
                               (S.INDICADOR_ADESAO_SNE = '1' AND S.INDICADOR_ADESAO_OA_SNE = '1')
                               /*OR
                               -- GATO PARA NAO IMPRIMIR AS MULTAS DO RENAINF
                               NVL(ENVIA_RENAINF, 'S') <> 'S' AND TRIM(B.COD_RENAINF) IS NOT NULL */
                          THEN NULL
                          ELSE CASE WHEN UTILIZA_AR_DIGITAL = 'S' THEN
                                      PKG_AR_GERAL.FNC_GERAR_AR(P_ORGAO_AR,
                                                                P_UF_OPERADOR,
                                                                P_REMESSA_AR,
                                                                '1',
                                                                '2',
                                                                P_OPERADOR,
                                                                P_ESTACAO,
                                                                P_FUNCAO,
                                                                B.ENDERECO_PROPRIETARIO,
                                                                CASE WHEN TRIM(B.COMPLEMENTO_ENDERECO_PROP) IS NOT NULL AND TRIM(B.ENDERECO_NUMERO_PROP) IS NOT NULL
                                                                     THEN 
                                                                       CASE WHEN LENGTH(TRIM(B.COMPLEMENTO_ENDERECO_PROP)) > 15 THEN
                                                                         SUBSTR(B.COMPLEMENTO_ENDERECO_PROP, 1,22 - LENGTH(TRIM(B.ENDERECO_NUMERO_PROP))-1) || '-' || TRIM(B.ENDERECO_NUMERO_PROP)
                                                                       END  
                                                                     ELSE B.COMPLEMENTO_ENDERECO_PROP || '-' || B.ENDERECO_NUMERO_PROP
                                                                     END,
                                                                B.BAIRRO_PROPRIETARIO,
                                                                B.CEP_PROPRIETARIO,
                                                                B.NOME_PROPRIETARIO,
                                                                B.COD_MUNICIPIO_PROPRIETARIO,
                                                                P_DATA_POSTAGEM,
                                                                B.NUMERO_NOTIFICACAO, -- P_NUM_DOCUMENTO
                                                                B.PLACA, -- P_PLACA
                                                                B.RENAVAM, -- P_RENAVAM
                                                                B.NUMERO_AUTO, -- P_NUM_AUTO
                                                                TO_CHAR(SYSDATE,'YYYY'), -- P_ANO_DOC
                                                                TO_CHAR(SYSDATE,'YYYYMMDD'), --P_DATA_DOC
                                                                '', -- P_SEQUENCIAL_REMESSA
                                                                '1', -- P_TIPO_ENVIO - 1-Remessa Econ�mica; 2-SEDEX; 3-Carta comercial; 4-PAC
                                                                '1',  -- P_TIPO_RASTREAMENTO - 1-AR Digital; 2-AR Simples
                                                                LOTE_FAC, 
                                                                '',
                                                                B.UF_PROPRIETARIO)                                                             
                            ELSE
                                      PKG_AR_GERAL.FNC_GERAR_AR(P_ORGAO_AR,
                                                                P_UF_OPERADOR,
                                                                P_REMESSA_AR,
                                                                '1',
                                                                '2',
                                                                P_OPERADOR,
                                                                P_ESTACAO,
                                                                P_FUNCAO,
                                                                B.ENDERECO_PROPRIETARIO,
                                                                B.COMPLEMENTO_ENDERECO_PROP,
                                                                B.BAIRRO_PROPRIETARIO,
                                                                B.CEP_PROPRIETARIO,
                                                                B.NOME_PROPRIETARIO,
                                                                B.COD_MUNICIPIO_PROPRIETARIO,
                                                                P_DATA_POSTAGEM,
                                                                B.NUMERO_NOTIFICACAO, -- P_NUM_DOCUMENTO
                                                                B.PLACA, -- P_PLACA
                                                                B.RENAVAM, -- P_RENAVAM
                                                                B.NUMERO_AUTO, -- P_NUM_AUTO
                                                                TO_CHAR(SYSDATE,'YYYY'), -- P_ANO_DOC
                                                                TO_CHAR(SYSDATE,'YYYYMMDD'), --P_DATA_DOC
                                                                '', -- P_SEQUENCIAL_REMESSA
                                                                '4', -- P_TIPO_ENVIO - 1-Remessa Econ�mica; 2-SEDEX; 3-Carta comercial; 4-PAC
                                                                '1',  -- P_TIPO_RASTREAMENTO - 1-AR Digital; 2-AR Simples
                                                                LOTE_FAC, 
                                                                LPAD(ROWNUM,11,'0'),
                                                                B.UF_PROPRIETARIO,
                                                                P_ORGAO_AUTUADOR
                                                                )
                            END                                                             
                     END,
                     P_REMESSA_AR,
                     REMESSA_NOTIFICACAO,
                     B.NUMERO_REMESSA,
                     TO_CHAR(SYSDATE,
                             'YYYYMMDD'),
                     P_DATA_POSTAGEM,
                     -- ALTERADO PARA GRAVAR NA ESPELHO O NUMERO DO AR QUE SER� IMPRESSO NA VIA CORREIO
                     NULL,
                     B.NOME_CONDUTOR,
                     B.CPF_CONDUTOR, 
                     B.DOC_CONDUTOR, 
                     B.UF_DOC_CONDUTOR, 
                     B.TIPO_DOC_CONDUTOR, 
                     B.DESC_TIPO_DOC_CONDUTOR, 
                     B.CONDUTOR_HABILITADO,
                     CASE WHEN NVL(TRIM(IMPRIME_FORMULARIO),'S') = 'N'
                          THEN CASE WHEN B.TIPO_INFRATOR = '1' AND
                                         NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN 'S'
                                    ELSE 'N'
                               END
                          ELSE 'S'
                     END IMPRIME_FORMULARIO_CONDUTOR_SN,
                     B.MULTA_PESSOA,
                     CASE WHEN S.INDICADOR_ADESAO_SNE = '1' AND S.INDICADOR_ADESAO_OA_SNE = '1' THEN
                         'S'
                     ELSE
                         'N'
                     END, /*SEN ATIVO*/
                     S.DATA_ADESAO_SNE, /*DATA ADESAO*/
                     TRIM(B.ENDERECO_NUMERO_PROP),
                     CASE WHEN TINF.DT_INF_SITUACAO_CNH = 'S' THEN
                       'S'
                     ELSE
                       'N' 
                     END /*SUSPENSIVA*/
                FROM T_SGM_NOTIFICACAO_AUTUACAO_AIT B,
                     MM_RINF_TRANSACOES_POR_MULTA  T,
                     MM_SNE_ADESAO S,
                     MMA1MULT M,
                     MMA1TINF TINF
               WHERE B.COD_ORGAO_AUTUADOR = T.MM_OAU_CODIGO(+)
                 AND B.NUMERO_AUTO = T.MU_MUL_NUMERO(+)
                 AND B.NUMERO_SEQUENCIAL = T.MU_MUL_SEQUENCIAL(+)
                 AND B.DESTINATARIO_E_DATA_OK = 'S'
                 AND B.COD_ORGAO_AUTUADOR = S.MM_OAU_CODIGO(+)
                 AND B.NUMERO_AUTO = S.MU_MUL_NUMERO(+)
                 AND B.NUMERO_SEQUENCIAL = S.MU_MUL_SEQUENCIAL(+)
                 AND B.INFRACAO = S.DT_INF_CODIGO(+)
                 AND M.DT_MUNIC_CODIGO = B.COD_MUNICIPIO
                 AND M.MU_MUL_NUMERO = B.NUMERO_AUTO
                 AND M.MU_MUL_SEQUENCIAL    = B.NUMERO_SEQUENCIAL(+)
                 AND M.DT_INF_CODIGO        = TINF.DT_INF_CODIGO(+)
                 AND M.DT_INF_DESDOBRAMENTO = TINF.DT_INF_DESDOBRAMENTO(+)
                 AND M.MU_MUL_DATA BETWEEN TINF.DT_INF_INICIO_VIGENCIA AND TINF.DT_INF_FIM_VIGENCIA(+)
                 AND M.DT_INF_CODIGO        = TINF.DT_INF_CODIGO(+)
                 AND M.DT_INF_DESDOBRAMENTO = TINF.DT_INF_DESDOBRAMENTO(+)
                 AND M.MU_MUL_DATA BETWEEN TINF.DT_INF_INICIO_VIGENCIA AND TINF.DT_INF_FIM_VIGENCIA(+)
                 AND (T.MU_MUL_NUMERO IS NULL OR 
                     (T.NUM_TRANSACAO = '412' AND T.COD_RETORNO IN ('000', '266')) OR
                     (T.MU_MUL_NUMERO IS NOT NULL AND TRIM(B.COD_RENAINF) IS NULL));
        ELSE
          INSERT INTO T_SGM_NOTIFICACAO
              (ORGAO_AUTUADOR,
               DESC_ORGAO_AUTUADOR,
               MU_MUL_NUMERO,
               MU_MUL_SEQUENCIAL,
               DATA_SITUACAO,
               DT_PESSOA,
               NOME_PROPRIETARIO,
               NOME_LOGRADOURO,
               COMPLEMENTO_LOGRADOURO,
               ENDERECO_BAIRRO,
               MUNICIPIO_LOGRADOURO,
               UF_LOGRADOURO,
               ENDERECO_CEP,
               CPF_CGC,
               NOME_MARCA_MODELO,
               CHASSI,
               PLACA,
               PLACA_UF,
               ABREV_COMBUSTIVEL,
               ANO_FABRICACAO,
               ANO_MODELO,
               ESPECIE,
               COR,
               RENAVAM,
               DT_MUNIC_CODIGO,
               DT_MUNIC_DESC,
               DATA,
               HORA,
               INFRACAO,
               INFRACAO_DESDOBRAMENTO,
               INFRACAO_DESCRICAO,
               INFRACAO_REGULAMENTO,
               DESCRICAO_LOCAL,
               OBSERVACAO_MULTA,
               AGENTE,
               DOC_INFRATOR,
               UF_INFRATOR,
               NOME_INFRATOR,
               MM_GRM_PONTOS,
               MM_GRM_DESCRICAO,
               COD_RENAINF,
               COD_RETORNO,
               VALOR,
               VALOR_COM_DESCONTO,
               COD_EQUIPAMENTO,
               MEDICAO_PERMITIDA,
               MEDICAO_AFERIDA,
               MEDICAO_CONSIDERADA,
               UNIDADE_MEDIDA,
               NRO_NOTIFICACAO,
               DATA_LIMITE_DEF_PREVIA,
               NUMERO_AR,
               REMESSA_AR,
               REMESSA_NOTIFICACAO,
               MU_REM_NUMERO,
               DATA_AUTUACAO,
               DATA_POSTAGEM,
               NUMERO_AR_CORREIO,
               NOME_CONDUTOR, 
               CPF_CONDUTOR, 
               DOC_CONDUTOR, 
               UF_DOC_CONDUTOR, 
               TIPO_DOC_CONDUTOR, 
               DESC_TIPO_DOC_CONDUTOR, 
               CONDUTOR_HABILITADO,
               IMPRIME_FORMULARIO_CONDUTOR_SN,
               MULTA_PESSOA,
               SNE_ATIVO,
               DATA_ADESAO_SNE,
               SUSPENSIVA
               )
              SELECT B.COD_ORGAO_AUTUADOR,
                     B.DESC_ORGAO_AUTUADOR,
                     B.NUMERO_AUTO,
                     B.NUMERO_SEQUENCIAL,
                     B.DATA_SITUACAO,
                     B.DT_PESSOA,
                     B.NOME_PROPRIETARIO,
                     B.ENDERECO_PROPRIETARIO,
                     B.COMPLEMENTO_ENDERECO_PROP || ' ' || TRIM(B.ENDERECO_NUMERO_PROP),
                     B.BAIRRO_PROPRIETARIO,
                     B.CIDADE_PROPRIETARIO,
                     B.UF_PROPRIETARIO,
                     B.CEP_PROPRIETARIO,
                     B.CPF_CGC_PROPRIETARIO,
                     B.DESC_MARCA_MODELO,
                     B.CHASSI,
                     B.PLACA,
                     B.UF_PLACA,
                     B.COMBUSTIVEL,
                     B.ANO_FABRICACAO,
                     B.ANO_MODELO,
                     B.DESC_ESPECIE,
                     B.DESC_COR,
                     B.RENAVAM,
                     B.COD_MUNIC_COMETIMENTO, -- Alterado para 5 posi��es de novo com DV Tabela TOM no Final - ALtera��o na view (V_NOTIFICACAO_PENALIDADE_AIT)
                     B.DESC_MUNIC_COMETIMENTO,
                     B.DATA_COMETIMENTO,
                     B.HORA_COMETIMENTO,
                     CASE WHEN LENGTH(B.INFRACAO) = 5 AND SUBSTR(B.INFRACAO,1,1) = '0' 
                          THEN SUBSTR(B.INFRACAO,2)
                          ELSE B.INFRACAO
                     END INFRACAO, -- c�d infra��o impresso com 4 d�gitos, sem o zero a esquerda
                     B.INFRACAO_DESDOBRAMENTO,
                     B.INFRACAO_DESCRICAO,
                     B.INFRACAO_REGULAMENTO,
                     B.LOCAL_INFRACAO || B.COMPLEMENTO_LOCAL_INFRACAO,
                     B.OBSERVACAO_MULTA,
                     B.AGENTE,
                     CASE WHEN B.MULTA_PESSOA = 'S' THEN
                       B.DOC_INFRATOR
                     ELSE
                       CASE WHEN NVL(TRIM(IMPRIME_PROPRIETARIO_INFRATOR),'S') = 'N' AND
                                 B.TIPO_INFRATOR = '1' AND
                                 NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN NULL
                            ELSE M.MU_MUL_NUMERO_CNH
                       END 
                     END DOC_INFRATOR,
                     CASE WHEN NVL(TRIM(IMPRIME_PROPRIETARIO_INFRATOR),'S') = 'N' AND
                               B.TIPO_INFRATOR = '1' AND
                               NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN NULL
                          ELSE M.MU_MUL_CNH_UF
                     END UF_INFRATOR,
                     CASE WHEN B.MULTA_PESSOA = 'S' THEN
                       B.NOME_INFRATOR
                     ELSE
                       CASE WHEN NVL(TRIM(IMPRIME_PROPRIETARIO_INFRATOR),'S') = 'N' AND
                                 B.TIPO_INFRATOR = '1' AND
                                 NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN NULL
                            ELSE FNC_RETIRA_CARACTER_ESPECIAL(REPLACE(M.MU_MUL_NOME_INFRATOR, '&', 'E'))
                       END 
                     END NOME_INFRATOR,
                     B.PONTOS_INFRACAO,
                     B.GRUPO_INFRACAO,
                     B.COD_RENAINF,
                     T.COD_RETORNO,
                     B.VALOR,
                     B.VALOR_COM_DESCONTO,
                     B.RADAR,
                     B.MEDICAO_PERMITIDA,
                     B.MEDICAO_AFERIDA,
                     B.MEDICAO_CONSIDERADA,
                     B.UNIDADE_MEDIDA,
                     B.NUMERO_NOTIFICACAO,
                     B.DATA_LIMITE_DEFESA,
                     CASE WHEN TRIM(P_ORGAO_AR) IS NULL OR TRIM(B.NOME_PROPRIETARIO) IS NULL OR
                               -- valida o endere�o 
                               (B.UF_PROPRIETARIO = P_UF_OPERADOR AND LENGTH(TRIM(B.ENDERECO_PROPRIETARIO || B.COMPLEMENTO_ENDERECO_PROP)) <= 2) OR
                               (B.UF_PROPRIETARIO <> P_UF_OPERADOR AND TRIM(B.ENDERECO_PROPRIETARIO || B.COMPLEMENTO_ENDERECO_PROP) IS NULL) OR
                               (S.INDICADOR_ADESAO_SNE = '1' AND S.INDICADOR_ADESAO_OA_SNE = '1')
                               /*OR
                               -- GATO PARA NAO IMPRIMIR AS MULTAS DO RENAINF
                               NVL(ENVIA_RENAINF, 'S') <> 'S' AND TRIM(B.COD_RENAINF) IS NOT NULL */
                          THEN NULL
                          ELSE 
                            CASE WHEN UTILIZA_AR_DIGITAL = 'S' THEN
                                PKG_AR_GERAL.FNC_GERAR_AR(P_ORGAO_AR,
                                                                P_UF_OPERADOR,
                                                                P_REMESSA_AR,
                                                                '1',
                                                                '2',
                                                                P_OPERADOR,
                                                                P_ESTACAO,
                                                                P_FUNCAO,
                                                                B.ENDERECO_PROPRIETARIO,
                                                                CASE WHEN TRIM(B.COMPLEMENTO_ENDERECO_PROP) IS NOT NULL AND TRIM(B.ENDERECO_NUMERO_PROP) IS NOT NULL
                                                                     THEN 
                                                                       CASE WHEN LENGTH(TRIM(B.COMPLEMENTO_ENDERECO_PROP)) > 15 THEN
                                                                         SUBSTR(B.COMPLEMENTO_ENDERECO_PROP, 1,22 - LENGTH(TRIM(B.ENDERECO_NUMERO_PROP))-1) || '-' || TRIM(B.ENDERECO_NUMERO_PROP)
                                                                       END  
                                                                     ELSE B.COMPLEMENTO_ENDERECO_PROP || '-' || B.ENDERECO_NUMERO_PROP
                                                                     END,
                                                                B.BAIRRO_PROPRIETARIO,
                                                                B.CEP_PROPRIETARIO,
                                                                B.NOME_PROPRIETARIO,
                                                                B.COD_MUNICIPIO_PROPRIETARIO,
                                                                P_DATA_POSTAGEM)                                                             
                            ELSE
                                SUBSTR(PKG_AR_GERAL.FNC_GERAR_AR(P_ORGAO_AR,
                                                                    P_UF_OPERADOR,
                                                                    P_REMESSA_AR,
                                                                    '1',
                                                                    '2',
                                                                    P_OPERADOR,
                                                                    P_ESTACAO,
                                                                    P_FUNCAO,
                                                                    B.ENDERECO_PROPRIETARIO,
                                                                    B.COMPLEMENTO_ENDERECO_PROP,
                                                                    B.BAIRRO_PROPRIETARIO,
                                                                    B.CEP_PROPRIETARIO,
                                                                    B.NOME_PROPRIETARIO,
                                                                    B.COD_MUNICIPIO_PROPRIETARIO,
                                                                    P_DATA_POSTAGEM),
                                                                    3,
                                                                    9)
                            END                                                             
                     END,
                     P_REMESSA_AR,
                     REMESSA_NOTIFICACAO,
                     B.NUMERO_REMESSA,
                     TO_CHAR(SYSDATE,
                             'YYYYMMDD'),
                     CASE WHEN UTILIZA_AR_DIGITAL = 'S' and ((S.INDICADOR_ADESAO_SNE <> '1' OR S.INDICADOR_ADESAO_SNE IS NULL) OR (S.INDICADOR_ADESAO_OA_SNE <> '1' OR S.INDICADOR_ADESAO_OA_SNE IS NULL)) THEN
                        P_DATA_POSTAGEM
                     ELSE
                        NULL
                     END,
                     -- ALTERADO PARA GRAVAR NA ESPELHO O NUMERO DO AR QUE SER� IMPRESSO NA VIA CORREIO
                     NULL,
                     B.NOME_CONDUTOR,
                     B.CPF_CONDUTOR, 
                     B.DOC_CONDUTOR, 
                     B.UF_DOC_CONDUTOR, 
                     B.TIPO_DOC_CONDUTOR, 
                     B.DESC_TIPO_DOC_CONDUTOR, 
                     B.CONDUTOR_HABILITADO,
                     CASE WHEN NVL(TRIM(IMPRIME_FORMULARIO),'S') = 'N'
                          THEN CASE WHEN B.TIPO_INFRATOR = '1' AND
                                         NVL(TRIM(B.CONDUTOR_IDENTIFICADO),'N') <> 'S' THEN 'S'
                                    ELSE 'N'
                               END
                          ELSE 'S'
                     END IMPRIME_FORMULARIO_CONDUTOR_SN,
                     B.MULTA_PESSOA,
                     CASE WHEN S.INDICADOR_ADESAO_SNE = '1' AND S.INDICADOR_ADESAO_OA_SNE = '1' THEN
                         'S'
                     ELSE
                         'N'
                     END, /*SEN ATIVO*/
                     S.DATA_ADESAO_SNE, /*DATA ADESAO*/
                     CASE WHEN TINF.DT_INF_SITUACAO_CNH = 'S' THEN
                       'S'
                     ELSE
                       'N' 
                     END/*SUSPENSIVA*/
                FROM T_SGM_NOTIFICACAO_AUTUACAO_AIT B,
                     MM_RINF_TRANSACOES_POR_MULTA  T,
                     MM_SNE_ADESAO S,
                     MMA1MULT M,
                     MMA1TINF TINF
               WHERE B.COD_ORGAO_AUTUADOR = T.MM_OAU_CODIGO(+)
                 AND B.NUMERO_AUTO = T.MU_MUL_NUMERO(+)
                 AND B.NUMERO_SEQUENCIAL = T.MU_MUL_SEQUENCIAL(+)
                 AND B.DESTINATARIO_E_DATA_OK = 'S'
                 AND B.COD_ORGAO_AUTUADOR = S.MM_OAU_CODIGO(+)
                 AND B.NUMERO_AUTO = S.MU_MUL_NUMERO(+)
                 AND B.NUMERO_SEQUENCIAL = S.MU_MUL_SEQUENCIAL(+)
                 AND B.INFRACAO = S.DT_INF_CODIGO(+)
                 AND M.DT_MUNIC_CODIGO = B.COD_MUNICIPIO
                 AND M.MU_MUL_NUMERO = B.NUMERO_AUTO
                 AND M.MU_MUL_SEQUENCIAL = B.NUMERO_SEQUENCIAL
                 AND M.DT_INF_CODIGO        = TINF.DT_INF_CODIGO(+)
                 AND M.DT_INF_DESDOBRAMENTO = TINF.DT_INF_DESDOBRAMENTO(+)
                 AND M.MU_MUL_DATA BETWEEN TINF.DT_INF_INICIO_VIGENCIA AND TINF.DT_INF_FIM_VIGENCIA(+)
                 AND (T.MU_MUL_NUMERO IS NULL OR 
                     (T.NUM_TRANSACAO = '412' AND T.COD_RETORNO IN ('000', '266')) OR
                     (T.MU_MUL_NUMERO IS NOT NULL AND TRIM(B.COD_RENAINF) IS NULL));
        END IF;
       
        -- ATUALIZA O NUMERO AR VIA CORREIO
        IF UTILIZA_AR_DIGITAL = 'S' THEN
          UPDATE T_SGM_NOTIFICACAO T1
           SET T1.NUMERO_AR_CORREIO = PKG_AR_GERAL.FNC_PEGAR_SIGLA_OBJ_V_CORREIO(P_UF_OPERADOR, P_ORGAO_AUTUADOR) || SUBSTR(T1.NUMERO_AR,3,9) || PKG_AR_GERAL.FNC_PEGAR_PAIS_OBJ_V_CORREIO(P_UF_OPERADOR, P_ORGAO_AR)
          WHERE T1.MU_MUL_NUMERO = (SELECT T.MU_MUL_NUMERO FROM T_SGM_NOTIFICACAO T
                                     WHERE T.MU_MUL_NUMERO = T1.MU_MUL_NUMERO
                                       AND T.MU_MUL_SEQUENCIAL = T1.MU_MUL_SEQUENCIAL )
             AND T1.SNE_ATIVO = 'N';
        END IF;
                      
        -- PEGA QUANTAS INFRACOES PODEM SER IMPRESSAS
        SELECT COUNT(*)
          INTO QTD
          FROM T_SGM_NOTIFICACAO T
         WHERE TRIM(T.NOME_PROPRIETARIO) IS NOT NULL
           -- valida o endere�o
           AND ((T.UF_LOGRADOURO  = P_UF_OPERADOR AND LENGTH(TRIM(T.NOME_LOGRADOURO || T.ENDERECO_BAIRRO)) > 2) OR
                (T.UF_LOGRADOURO <> P_UF_OPERADOR AND TRIM(T.NOME_LOGRADOURO || T.ENDERECO_BAIRRO) IS NOT NULL));
        -- GATO PARA NAO IMPRIMIR AS MULTAS DO RENAINF
        -- AND (NVL(ENVIA_RENAINF, 'S') = 'S' OR TRIM(T.COD_RENAINF) IS NULL);
    
        -- ALTERA SOMENTE SE TIVER INFRACOES VALIDAS PARA IMPRESSAO
        IF QTD > 0 THEN
            -- PEGA O NUMERO DA TAREFA

              IF USA_FATURAMENTO = 'S' THEN
                  IF P_ORGAO_AUTUADOR IN ('101100','123100','101400') THEN --Detran AC,RR,AP
                     V_SERV_FATURAMENTO := '000000000000008';
                   ELSIF P_ORGAO_AUTUADOR = '101200' THEN  --Der AC
                     V_SERV_FATURAMENTO := '000000000000015';
                   ELSIF P_ORGAO_AUTUADOR IN ('201390','203010') THEN --Pref. Rio Branco-AC, Boa Vista-RR
                     V_SERV_FATURAMENTO := '000000000000016'; 
                   ELSIF P_ORGAO_AUTUADOR IN ('206150') THEN --Pref. Santana-AP
                     V_SERV_FATURAMENTO := '000000000000017'; 
                   END IF;
                  
                  NUMERO_TAREFA := PKG_FATURAMENTO.FNC_RETORNA_NUMERO_TAREFA(P_SESSAO,
                                                                             '3',
                                                                             P_FUNCAO,
                                                                             V_SERV_FATURAMENTO,
                                                                             P_OPERADOR,
                                                                             ' ',
                                                                             P_UF_OPERADOR,
                                                                             'MULTAWEB');

                  TMP           := PKG_FATURAMENTO.FNC_ATUALIZA_QTDE_EXECUTADA(NUMERO_TAREFA,
                                                                               '3',
                                                                               V_SERV_FATURAMENTO,
                                                                               QTD);
              END IF;
          
              -- ATUALIZA DADOS DA INFRA��O
              UPDATE MMA1MULT MULT
                 SET MULT.MU_MUL_DATA_AUTUACAO     = TO_CHAR(SYSDATE,
                                                             'YYYYMMDD'),
                     MULT.FI_TAR_NUMERO_TAREFA     = NUMERO_TAREFA,
                     (MULT.MU_MUL_LIMITE_DEF_PREVIA, MULT.MU_MUL_AUTO_PRF, MULT.REGISTRAR_NA_EDITAL,MULT.MU_SIT_CODIGO) = (SELECT T2.DATA_LIMITE_DEF_PREVIA,
                                                                                                                                  T2.NRO_NOTIFICACAO,
                                                                                                                                  CASE WHEN T2.SNE_ATIVO = 'S' THEN 'N' ELSE NULL END,
                                                                                                                                  CASE WHEN T2.SNE_ATIVO = 'S' THEN '13H' ELSE '131' END
                                                                                                                             FROM T_SGM_NOTIFICACAO T2
                                                                                                                            WHERE T2.ORGAO_AUTUADOR = MULT.MM_OAU_CODIGO
                                                                                                                              AND T2.MU_MUL_NUMERO = MULT.MU_MUL_NUMERO
                                                                                                                              AND T2.MU_MUL_SEQUENCIAL = MULT.MU_MUL_SEQUENCIAL)
               WHERE (MM_OAU_CODIGO, MU_MUL_NUMERO, MU_MUL_SEQUENCIAL) IN
                     (SELECT T.ORGAO_AUTUADOR,
                             T.MU_MUL_NUMERO,
                             T.MU_MUL_SEQUENCIAL
                        FROM T_SGM_NOTIFICACAO T
                       WHERE TRIM(T.NOME_PROPRIETARIO) IS NOT NULL
                         -- valida o endere�o
                         AND ((T.UF_LOGRADOURO = P_UF_OPERADOR AND LENGTH(TRIM(T.NOME_LOGRADOURO || T.COMPLEMENTO_LOGRADOURO)) > 2) OR
                              (T.UF_LOGRADOURO <> P_UF_OPERADOR AND TRIM(T.NOME_LOGRADOURO || T.COMPLEMENTO_LOGRADOURO) IS NOT NULL)));
                     
                            
            -- INSERE DADOS DA NOTIFICA��O
              INSERT INTO MMA1NOTI
                  (DT_MUNIC_CODIGO,
                   MU_MUL_NUMERO,
                   MU_MUL_SEQUENCIAL,
                   MU_NOT_INDICE_SEQ,
                   MM_OAU_CODIGO,
                   MU_MUL_TIPO_NOTIFICACAO,
                   MU_MUL_DATA_POSTAGEM,
                   MU_MUL_NUMERO_AR,
                   MU_MUL_REMESSA_NOTIFICACAO,
                   MU_MUL_DATA_REMESSA,
                   NRO_NOTIFICACAO)
                  SELECT NULL,
                         T.MU_MUL_NUMERO,
                         T.MU_MUL_SEQUENCIAL,
                         (SELECT LPAD(NVL(MAX(MU_NOT_INDICE_SEQ),
                                          0) + 1,
                                      4,
                                      '0')
                            FROM MMA1NOTI
                           WHERE MM_OAU_CODIGO = T.ORGAO_AUTUADOR
                             AND MU_MUL_NUMERO = T.MU_MUL_NUMERO
                             AND MU_MUL_SEQUENCIAL = T.MU_MUL_SEQUENCIAL),
                         T.ORGAO_AUTUADOR,
                         CASE WHEN T.SNE_ATIVO = 'S' THEN 'C' ELSE 'A' END,
                         CASE WHEN T.SNE_ATIVO = 'S' THEN NULL ELSE P_DATA_POSTAGEM END,
                         CASE WHEN T.SNE_ATIVO = 'S' THEN 
                                   NULL
                              WHEN UTILIZA_AR_DIGITAL = 'S' THEN
                                  SUBSTR(T.NUMERO_AR,3,9)
                         ELSE
                              T.NUMERO_AR
                         END,
                         REMESSA_NOTIFICACAO,
                         TO_CHAR(SYSDATE,
                                 'YYYYMMDD'),
                         T.NRO_NOTIFICACAO
                    FROM T_SGM_NOTIFICACAO T
                   WHERE TRIM(T.NOME_PROPRIETARIO) IS NOT NULL
                     -- valida o endere�o
                     AND ((T.UF_LOGRADOURO = P_UF_OPERADOR AND LENGTH(TRIM(T.NOME_LOGRADOURO || T.COMPLEMENTO_LOGRADOURO)) > 2) OR
                          (T.UF_LOGRADOURO <> P_UF_OPERADOR AND TRIM(T.NOME_LOGRADOURO || T.COMPLEMENTO_LOGRADOURO) IS NOT NULL));
            
            -- ATUALIZANDO A TABELA MMA1LMUL
            INSERT INTO MMA1LMUL
                (MU_MUL_NUMERO,
                 MU_MUL_SEQUENCIAL,
                 MU_LMU_DATA,
                 MU_LMU_HORA_MIN_SEG,
                 MU_LMU_SITUACAO,
                 MU_LMU_OPERADOR,
                 MU_LMU_ESTACAO,
                 MU_LMU_FUNCAO,
                 MM_OAU_CODIGO)
                SELECT T.MU_MUL_NUMERO,
                       T.MU_MUL_SEQUENCIAL,
                       TO_CHAR(SYSDATE,
                               'YYYYMMDD'),
                       TO_CHAR(SYSDATE,
                               'HH24MISS'),
                       '131',
                       P_OPERADOR,
                       P_ESTACAO,
                       P_FUNCAO,
                       T.ORGAO_AUTUADOR
                  FROM T_SGM_NOTIFICACAO T
                 WHERE TRIM(T.NOME_PROPRIETARIO) IS NOT NULL
                   -- valida o endere�o
                   AND ((T.UF_LOGRADOURO = P_UF_OPERADOR AND LENGTH(TRIM(T.NOME_LOGRADOURO || T.COMPLEMENTO_LOGRADOURO)) > 2) OR
                        (T.UF_LOGRADOURO <> P_UF_OPERADOR AND TRIM(T.NOME_LOGRADOURO || T.COMPLEMENTO_LOGRADOURO) IS NOT NULL));
            
            IF UTILIZA_AR_DIGITAL = 'N' THEN
              INSERT INTO MM_NOTIFICACAO_ESPELHO
                  (MM_OAU_CODIGO,
                   MU_MUL_NUMERO,
                   MU_MUL_SEQUENCIAL,
                   TIPO_NOTIFICACAO,
                   DATA_GERACAO,
                   ESPELHO_ATIVO,
                   DESC_ORGAO_AUTUADOR,
                   ENDERECO_ORGAO_AUTUADOR,
                   BAIRRO_ORGAO_AUTUADOR,
                   CIDADE_ORGAO_AUTUADOR,
                   UF_ORGAO_AUTUADOR,
                   CEP_ORGAO_AUTUADOR,
                   NUMERO_AR,
                   DT_PESSOA,
                   NOME_PROPRIETARIO,
                   NOME_LOGRADOURO,
                   COMPLEMENTO_LOGRADOURO,
                   ENDERECO_BAIRRO,
                   MUNICIPIO_LOGRADOURO,
                   UF_LOGRADOURO,
                   ENDERECO_CEP,
                   CPF_CGC,
                   NOME_MARCA_MODELO,
                   CHASSI,
                   PLACA,
                   PLACA_UF,
                   ABREV_COMBUSTIVEL,
                   ANO_FABRICACAO,
                   ANO_MODELO,
                   ESPECIE,
                   COR,
                   RENAVAM,
                   DT_MUNIC_CODIGO,
                   DT_MUNIC_DESC,
                   DATA,
                   HORA,
                   COD_RENAINF,
                   COD_RETORNO,
                   INFRACAO,
                   INFRACAO_DESDOBRAMENTO,
                   INFRACAO_DESCRICAO,
                   INFRACAO_REGULAMENTO,
                   DESCRICAO_LOCAL,
                   OBSERVACAO_MULTA,
                   AGENTE,
                   COD_EQUIPAMENTO,
                   MEDICAO_PERMITIDA,
                   MEDICAO_AFERIDA,
                   MEDICAO_CONSIDERADA,
                   UNIDADE_MEDIDA,
                   DOC_INFRATOR,
                   UF_INFRATOR,
                   NOME_INFRATOR,
                   MM_GRM_DESCRICAO,
                   MM_GRM_PONTOS,
                   DATA_LIMITE_DEF_PREVIA,
                   VALOR,
                   VALOR_COM_DESCONTO,
                   NRO_NOTIFICACAO,
                   REMESSA_AR,
                   REMESSA_NOTIFICACAO,
                   MU_REM_NUMERO,
                   DATA_NOTIFICACAO,
                   DATA_AUTUACAO,
                   DATA_POSTAGEM,
                   NUMERO_AR_VIA_CORREIO,
                   CONDUTOR_HABILITADO, 
                   DOC_CONDUTOR, 
                   TIPO_DOC_CONDUTOR,
                   DESC_TIPO_DOC_CONDUTOR, 
                   UF_DOC_CONDUTOR,
                   NOME_CONDUTOR, 
                   CPF_CONDUTOR,
                   IMPRIME_FORMULARIO_CONDUTOR_SN,
                   VERSAO_EMISSOR,
                   AVISO_TIPO_ENVIO,
                   ENDERECO_NUMERO,
                   SUSPENSIVA )
                  SELECT T.ORGAO_AUTUADOR,
                         T.MU_MUL_NUMERO,
                         T.MU_MUL_SEQUENCIAL,
                         'A',
                         SYSDATE,
                         'S',
                         T.DESC_ORGAO_AUTUADOR,
                         CASE WHEN UF_LOCAL = 'RR' THEN 
                                 'Av. Brigadeiro Eduardo Gomes 4.214'
                         ELSE 
                             'Avenida Cear�, n� 3059'
                        END,
                        CASE WHEN UF_LOCAL = 'RR' THEN
                           'Mecejana'
                        ELSE
                           'Jardim Nazle'
                        END,
                         CASE WHEN UF_LOCAL = 'RR' THEN
                             'Boa Vista'
                         ELSE
                             'Rio Branco'
                         END,
                         UF_LOCAL,
                         CASE WHEN UF_LOCAL = 'RR' THEN
                             '69304650'
                         ELSE
                             '69918093'
                         END,
                         T.NUMERO_AR,
                         T.DT_PESSOA,
                         T.NOME_PROPRIETARIO,
                         T.NOME_LOGRADOURO,
                         T.COMPLEMENTO_LOGRADOURO,
                         T.ENDERECO_BAIRRO,
                         T.MUNICIPIO_LOGRADOURO,
                         T.UF_LOGRADOURO,
                         T.ENDERECO_CEP,
                         T.CPF_CGC,
                         T.NOME_MARCA_MODELO,
                         T.CHASSI,
                         T.PLACA,
                         T.PLACA_UF,
                         T.ABREV_COMBUSTIVEL,
                         T.ANO_FABRICACAO,
                         T.ANO_MODELO,
                         T.ESPECIE,
                         T.COR,
                         T.RENAVAM,
                         T.DT_MUNIC_CODIGO,
                         T.DT_MUNIC_DESC,
                         T.DATA,
                         T.HORA,
                         T.COD_RENAINF,
                         T.COD_RETORNO,
                         T.INFRACAO,
                         T.INFRACAO_DESDOBRAMENTO,
                         T.INFRACAO_DESCRICAO,
                         T.INFRACAO_REGULAMENTO,
                         T.DESCRICAO_LOCAL,
                         T.OBSERVACAO_MULTA,
                         T.AGENTE,
                         T.COD_EQUIPAMENTO,
                         T.MEDICAO_PERMITIDA,
                         T.MEDICAO_AFERIDA,
                         T.MEDICAO_CONSIDERADA,
                         T.UNIDADE_MEDIDA,
                         T.DOC_INFRATOR,
                         T.UF_INFRATOR,
                         T.NOME_INFRATOR,
                         T.MM_GRM_DESCRICAO,
                         T.MM_GRM_PONTOS,
                         T.DATA_LIMITE_DEF_PREVIA,
                         T.VALOR,
                         T.VALOR_COM_DESCONTO,
                         T.NRO_NOTIFICACAO,
                         T.REMESSA_AR,
                         T.REMESSA_NOTIFICACAO,
                         T.MU_REM_NUMERO,
                         T.DATA_AUTUACAO,
                         T.DATA_AUTUACAO,
                         P_DATA_POSTAGEM,
                         T.NUMERO_AR_CORREIO,
                         T.CONDUTOR_HABILITADO, 
                         T.DOC_CONDUTOR, 
                         T.TIPO_DOC_CONDUTOR,
                         T.DESC_TIPO_DOC_CONDUTOR, 
                         T.UF_DOC_CONDUTOR,
                          T.NOME_CONDUTOR, 
                         T.CPF_CONDUTOR,
                         T.IMPRIME_FORMULARIO_CONDUTOR_SN,
                         VERSAO_EMISSOR,
                         CASE WHEN UTILIZA_AR_DIGITAL = 'S' THEN '1' ELSE '4' END,
                         T.ENDERECO_NUMERO,
                         T.SUSPENSIVA
                    FROM T_SGM_NOTIFICACAO T
                   WHERE T.SNE_ATIVO <> 'S';
            ELSE
              INSERT INTO MM_NOTIFICACAO_ESPELHO
                (MM_OAU_CODIGO,
                 MU_MUL_NUMERO,
                 MU_MUL_SEQUENCIAL,
                 TIPO_NOTIFICACAO,
                 DATA_GERACAO,
                 ESPELHO_ATIVO,
                 DESC_ORGAO_AUTUADOR,
                 ENDERECO_ORGAO_AUTUADOR,
                 BAIRRO_ORGAO_AUTUADOR,
                 CIDADE_ORGAO_AUTUADOR,
                 UF_ORGAO_AUTUADOR,
                 CEP_ORGAO_AUTUADOR,
                 NUMERO_AR,
                 DT_PESSOA,
                 NOME_PROPRIETARIO,
                 NOME_LOGRADOURO,
                 COMPLEMENTO_LOGRADOURO,
                 ENDERECO_BAIRRO,
                 MUNICIPIO_LOGRADOURO,
                 UF_LOGRADOURO,
                 ENDERECO_CEP,
                 CPF_CGC,
                 NOME_MARCA_MODELO,
                 CHASSI,
                 PLACA,
                 PLACA_UF,
                 ABREV_COMBUSTIVEL,
                 ANO_FABRICACAO,
                 ANO_MODELO,
                 ESPECIE,
                 COR,
                 RENAVAM,
                 DT_MUNIC_CODIGO,
                 DT_MUNIC_DESC,
                 DATA,
                 HORA,
                 COD_RENAINF,
                 COD_RETORNO,
                 INFRACAO,
                 INFRACAO_DESDOBRAMENTO,
                 INFRACAO_DESCRICAO,
                 INFRACAO_REGULAMENTO,
                 DESCRICAO_LOCAL,
                 OBSERVACAO_MULTA,
                 AGENTE,
                 COD_EQUIPAMENTO,
                 MEDICAO_PERMITIDA,
                 MEDICAO_AFERIDA,
                 MEDICAO_CONSIDERADA,
                 UNIDADE_MEDIDA,
                 DOC_INFRATOR,
                 UF_INFRATOR,
                 NOME_INFRATOR,
                 MM_GRM_DESCRICAO,
                 MM_GRM_PONTOS,
                 DATA_LIMITE_DEF_PREVIA,
                 VALOR,
                 VALOR_COM_DESCONTO,
                 NRO_NOTIFICACAO,
                 REMESSA_AR,
                 REMESSA_NOTIFICACAO,
                 MU_REM_NUMERO,
                 DATA_NOTIFICACAO,
                 DATA_AUTUACAO,
                 DATA_POSTAGEM,
                 NUMERO_AR_VIA_CORREIO,
                 CONDUTOR_HABILITADO, 
                 DOC_CONDUTOR, 
                 TIPO_DOC_CONDUTOR,
                 DESC_TIPO_DOC_CONDUTOR, 
                 UF_DOC_CONDUTOR,
                 NOME_CONDUTOR, 
                 CPF_CONDUTOR,
                 IMPRIME_FORMULARIO_CONDUTOR_SN,
                 VERSAO_EMISSOR,
                 SUSPENSIVA )
                SELECT T.ORGAO_AUTUADOR,
                       T.MU_MUL_NUMERO,
                       T.MU_MUL_SEQUENCIAL,
                       'A',
                       SYSDATE,
                       'S',
                       T.DESC_ORGAO_AUTUADOR,
                       CASE WHEN UF_LOCAL = 'RR' THEN 
                               'Av. Brigadeiro Eduardo Gomes 4.214'
                       ELSE 
                           'Avenida Cear�, n� 3059'
                      END,
                      CASE WHEN UF_LOCAL = 'RR' THEN
                         'Mecejana'
                      ELSE
                         'Jardim Nazle'
                      END,
                       CASE WHEN UF_LOCAL = 'RR' THEN
                           'Boa Vista'
                       ELSE
                           'Rio Branco'
                       END,
                       UF_LOCAL,
                       CASE WHEN UF_LOCAL = 'RR' THEN
                           '69304650'
                       ELSE
                           '69918093'
                       END,
                       T.NUMERO_AR,
                       T.DT_PESSOA,
                       T.NOME_PROPRIETARIO,
                       T.NOME_LOGRADOURO,
                       T.COMPLEMENTO_LOGRADOURO,
                       T.ENDERECO_BAIRRO,
                       T.MUNICIPIO_LOGRADOURO,
                       T.UF_LOGRADOURO,
                       T.ENDERECO_CEP,
                       T.CPF_CGC,
                       T.NOME_MARCA_MODELO,
                       T.CHASSI,
                       T.PLACA,
                       T.PLACA_UF,
                       T.ABREV_COMBUSTIVEL,
                       T.ANO_FABRICACAO,
                       T.ANO_MODELO,
                       T.ESPECIE,
                       T.COR,
                       T.RENAVAM,
                       T.DT_MUNIC_CODIGO,
                       T.DT_MUNIC_DESC,
                       T.DATA,
                       T.HORA,
                       T.COD_RENAINF,
                       T.COD_RETORNO,
                       T.INFRACAO,
                       T.INFRACAO_DESDOBRAMENTO,
                       T.INFRACAO_DESCRICAO,
                       T.INFRACAO_REGULAMENTO,
                       T.DESCRICAO_LOCAL,
                       T.OBSERVACAO_MULTA,
                       T.AGENTE,
                       T.COD_EQUIPAMENTO,
                       T.MEDICAO_PERMITIDA,
                       T.MEDICAO_AFERIDA,
                       T.MEDICAO_CONSIDERADA,
                       T.UNIDADE_MEDIDA,
                       T.DOC_INFRATOR,
                       T.UF_INFRATOR,
                       T.NOME_INFRATOR,
                       T.MM_GRM_DESCRICAO,
                       T.MM_GRM_PONTOS,
                       T.DATA_LIMITE_DEF_PREVIA,
                       T.VALOR,
                       T.VALOR_COM_DESCONTO,
                       T.NRO_NOTIFICACAO,
                       T.REMESSA_AR,
                       T.REMESSA_NOTIFICACAO,
                       T.MU_REM_NUMERO,
                       T.DATA_AUTUACAO,
                       T.DATA_AUTUACAO,
                       P_DATA_POSTAGEM,
                       T.NUMERO_AR_CORREIO,
                       T.CONDUTOR_HABILITADO, 
                       T.DOC_CONDUTOR, 
                       T.TIPO_DOC_CONDUTOR,
                       T.DESC_TIPO_DOC_CONDUTOR, 
                       T.UF_DOC_CONDUTOR,
                        T.NOME_CONDUTOR, 
                       T.CPF_CONDUTOR,
                       T.IMPRIME_FORMULARIO_CONDUTOR_SN,
                       VERSAO_EMISSOR,
                       T.SUSPENSIVA
                  FROM T_SGM_NOTIFICACAO T
                 WHERE T.SNE_ATIVO <> 'S';
            END IF;
        END IF;
            IF (UTILIZA_AR_DIGITAL = 'S') THEN  
              -- Somente para o estado do AC
              -- Gato para atualizar as tabelas inserindo o nome do arquivo correio.
               CASE WHEN P_UF_OPERADOR = 'AC' AND P_ORGAO_AUTUADOR <> '201390' THEN IDENT_CLIENTE_AR := 'DE';
                    WHEN P_UF_OPERADOR = 'AC' AND P_ORGAO_AUTUADOR = '201390' THEN IDENT_CLIENTE_AR := 'ACA';
                    WHEN P_UF_OPERADOR = 'RR' AND LPAD(P_ORGAO_AR,4,'0') = '0177' THEN IDENT_CLIENTE_AR := 'OD';
                    WHEN P_UF_OPERADOR = 'RR' AND LPAD(P_ORGAO_AR,4,'0') = '9916' THEN IDENT_CLIENTE_AR := 'VB';
                    ELSE NULL;
               END CASE;

               GERA_ARQUIVO_CORREIO_2019 := NVL(PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/' || P_ORGAO_AUTUADOR || '/GERAARQUIVOCORREIO2019'),'');
               SIGLA_AR := PKG_AR_GERAL.FNC_PEGAR_SIGLA_OBJETO(P_UF_OPERADOR, P_ORGAO_AR);
               
               IF GERA_ARQUIVO_CORREIO_2019 = 'S' THEN
                 -- atualiza o nome do arquivo
                 UPDATE MMA1REMJ REMJ
                 SET REMJ.MM_REMJ_NOME_ARQUIVO = IDENT_CLIENTE_AR || '1' ||TO_CHAR(SYSDATE, 'DDMM') ||LPAD(P_REMESSA_AR, 6, '0') || '.SD1'
                 WHERE REMJ.MM_REMJ_CODIGO = P_REMESSA_AR;
                 -- atualiza o nome do arquivo
                 UPDATE MMA1AVIS AVIS
                 SET AVIS.MM_AVISO_NOME_ARQUIVO_ECT = IDENT_CLIENTE_AR || '1' || TO_CHAR(SYSDATE, 'DDMM') ||LPAD(P_REMESSA_AR, 6, '0') || '.SD1'
                 WHERE AVIS.MM_REMJ_CODIGO = P_REMESSA_AR;

                 ARQUIVO_CORREIO := IDENT_CLIENTE_AR || '1' || TO_CHAR(SYSDATE, 'DDMM') || LPAD(P_REMESSA_AR, 6, '0') || '.SD1';  
                 
                 PRC_GERA_ARQUIVO_CORREIO_2019(P_DATA_POSTAGEM, ARQUIVO_CORREIO,SIGLA_AR, P_REMESSA_AR, 'BR', P_UF_OPERADOR, P_ORGAO_AR, IDENT_CLIENTE_AR, P_ORGAO_AUTUADOR);
               ELSE
                 -- atualiza o nome do arquivo
                 UPDATE MMA1REMJ REMJ
                 SET REMJ.MM_REMJ_NOME_ARQUIVO = IDENT_CLIENTE_AR||TO_CHAR(SYSDATE, 'DDMM') ||LPAD(P_REMESSA_AR, 6, '0') || '.SD1'
                 WHERE REMJ.MM_REMJ_CODIGO = P_REMESSA_AR;
                 -- atualiza o nome do arquivo
                 UPDATE MMA1AVIS AVIS
                 SET AVIS.MM_AVISO_NOME_ARQUIVO_ECT = IDENT_CLIENTE_AR|| TO_CHAR(SYSDATE, 'DDMM') ||LPAD(P_REMESSA_AR, 6, '0') || '.SD1'
                 WHERE AVIS.MM_REMJ_CODIGO = P_REMESSA_AR;

                 ARQUIVO_CORREIO := IDENT_CLIENTE_AR || TO_CHAR(SYSDATE, 'DDMM') || LPAD(P_REMESSA_AR, 6, '0') || '.SD1';  
                     
                 PRC_GERA_ARQUIVO_CORREIO(P_DATA_POSTAGEM, ARQUIVO_CORREIO,SIGLA_AR, P_REMESSA_AR, 'BR', P_UF_OPERADOR, P_ORGAO_AR, IDENT_CLIENTE_AR, P_ORGAO_AUTUADOR); 
               END IF;
             ELSIF UTILIZA_AR_DIGITAL = 'N' THEN 
               -- TRATAMENTO PARA GERA��O DE ARQUIVO CORREIOS CARTA SIMPLES
                   
               SELECT PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/'|| UF_LOCAL ||'/'|| P_ORGAO_AUTUADOR|| '/CODIGOADMINISTRATIVOCONTRATO') 
                INTO CAC_FAC
                FROM DUAL;
                    
               SELECT PKG_SPA_CONSULTAR_VALOR.BUSCA_VALOR_SIMPLES('SGM/'|| UF_LOCAL ||'/'|| P_ORGAO_AUTUADOR|| '/CODIGODR') 
                INTO DR_FAC
                FROM DUAL;       
                   
               ARQUIVO_CORREIO := LPAD(CAC_FAC, 8, 0) || '_' || LPAD(LOTE_FAC, 5, 0) || '_UNICA_' || LPAD(DR_FAC, 2, 0) || '.TXT';
                                        
               -- atualiza o nome do arquivo
               UPDATE MMA1REMJ REMJ
               SET REMJ.MM_REMJ_NOME_ARQUIVO = ARQUIVO_CORREIO
               WHERE REMJ.MM_REMJ_CODIGO = P_REMESSA_AR;
               -- atualiza o nome do arquivo
               UPDATE MMA1AVIS AVIS
               SET AVIS.MM_AVISO_NOME_ARQUIVO_ECT = ARQUIVO_CORREIO
               WHERE AVIS.MM_REMJ_CODIGO = P_REMESSA_AR;
               PRC_GERA_ARQUIVO_CORREIO_FAC(DR_FAC, 
                                            CAC_FAC,
                                            LOTE_FAC,
                                            ARQUIVO_CORREIO,
                                            P_REMESSA_AR,
                                            P_DATA_POSTAGEM,
                                            P_UF_OPERADOR,
                                            P_ORGAO_AUTUADOR);
             END IF;
        -- RETORNA AS INFRA��ES NOTIFICADAS PARA IMPRESS�O
        OPEN RETORNO FOR
            SELECT T.*,
                   NUMERO_TAREFA AS NUMERO_TAREFA,
                   VERSAO_EMISSOR AS VERSAO_EMISSOR,
                   CASE WHEN UTILIZA_AR_DIGITAL = 'S' THEN '1' ELSE '4' END AVISO_TIPO_ENVIO,
                   NVL(AVIS.MM_AVISO_TIPO_ENVIO, ' ') TIPO_ENVIO_AVISO
              FROM T_SGM_NOTIFICACAO T
              LEFT OUTER JOIN MMA1AVIS AVIS ON AVIS.MM_AVISO_NUMERO_AR = T.NUMERO_AR;
            -- GATO PARA NAO IMPRIMIR AS MULTAS DO RENAINF
            -- WHERE (NVL(ENVIA_RENAINF, 'S') = 'S' OR TRIM(T.COD_RENAINF) IS NULL);
            
        -- LIMPA A TABELA TEMPOR�RIA
        DELETE FROM T_SGM_NOTIFICACAO;
    
        RETURN RETORNO;
    END;