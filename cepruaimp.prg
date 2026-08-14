// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : cepruaimp.prg
// +
// +
// +
// +     Sistema:
// +
// +     Linguagem: Harbour
// +
// +     Autor: jcassiano
// +
// +     Copyright (c) 2024,  jcassiano
// +
// +
// +
// +
// +
// +    Documentado em 27-Dez-2024 as  9:21 pm
// +
// +
// +
// +--------------------------------------------------------------------
// +

REQUEST HB_CODEPAGE_PTISO
REQUEST DBFCDX


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function main()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION Main()

   hb_idleState()

   Set( _SET_CODEPAGE, "PTISO" )

   SetMode( 25, 80 )
   cls

   rddSetDefault( "DBFCDX" )
   Set( _SET_OPTIMIZE, .T. )
   Set( _SET_DELETED, .T. )
   Set( _SET_SOFTSEEK, .T. )
   __SetCentury( .T. )
   Set( _SET_EPOCH, Year( Date() ) - 60 )
   Set( _SET_DATEFORMAT, "dd/mm/yyyy" )


   IF !File( "cepruaimp.dbf" )
      Alert( "Falta cepruaimp.dbf" )
      QUIT
   ENDIF

   IF !File( "cepruaerr.dbf" )
      Alert( "Falta cepruaerr.dbf" )
      QUIT
   ENDIF

   IF !File( "MD10.dbf" ) .OR. !File( "MD10.CDX" )
      Alert( "Falta MD10.dbf ou md10.cdx" )
      QUIT
   ENDIF

   IF !File( "cidconv.dbf" ) .OR. !File( "cidconv.CDX" )
      Alert( "Falta cidconv.dbf ou cidconv.cdx" )
      QUIT
   ENDIF

   IF !File( "cepbai.dbf" ) .OR. !File( "cepbai.CDX" )
      Alert( "Falta cepbai.dbf ou cepbai.cdx" )
      QUIT
   ENDIF

   IF !File( "cepbailx.dbf" ) .OR. !File( "cepbailx.CDX" )
      Alert( "Falta cepbailx.dbf ou cepbailx.cdx" )
      QUIT
   ENDIF

   nUSO := FCreate( "erro.txt" )
  IF nUSO == -1
      Alert( "Erro ao criar arquivo de log!" )
     dbcloseall()
     RETURN NIL
  ENDIF


   USE cepruaerr NEW EXCLUSIVE
   ZAP


   IF File( "cepruaimp.cdx" )  // apaga o indice caso algum importador use outra chave para o index primario
      FErase( "cepruaimp.cdx" )
   ENDIF
   USE cepruaimp NEW EXCLUSIVE
   INDEX ON UF + CIDADE + CEP TAG ufcidade
   nLASTREC := LastRec()
   IF File( "logradouro.dbf" )
      APPEND FROM logradouro
   ENDIF

   cARQUIVO := "MD10"
   dbUseArea( .T., "DBFCDX", cARQUIVO,, .T. )
   ordListAdd( cARQUIVO )
   dbSetOrder( 1 )   //

   cARQUIVO := "CIDCONV"
   dbUseArea( .T., "DBFCDX", cARQUIVO,, .T. )
   ordListAdd( cARQUIVO )
   dbSetOrder( 1 )   //

   cARQUIVO := "CEPBAILX"
   dbUseArea( .T., "DBFCDX", cARQUIVO,, .T. )
   ordListAdd( cARQUIVO )

   cARQUIVO := "CEPBAI"
   dbUseArea( .T., "DBFCDX", cARQUIVO,, .T. )
   ordListAdd( cARQUIVO )
// trabalhando por id para preenher vaos depois retornar pelo ultimo id
   dbSetOrder( 1 )
   dbGoBottom()
   nLASTBAIRRO:=cepbai->bai_nu_seq
   nLASTBAIRRO++
   dbSetOrder( 2 )



// 01/02/2O21 ajusta  cidade esta junto com o estado separado pela barra Ex: SAO PAULO/SP antes de comecar a importacao
// manter a tratativa abaixo tambem pois algum registro pode estar sem a barra
   dbSelectAr( "cepruaimp" )
   dbSetOrder( 0 )
   dbGoTop()
   lPROCESSA := Empty( cepruaimp->UF ) .AND. At( "/", CEPRUAIMP->CIDADE ) > 0   // checa o primeiro registro pra evitar loop descnecesario
   IF lPROCESSA
      WHILE !Eof()
         @ 24, 00 SAY Str( RecNo(), 10 ) + "/" + Str( nLASTREC, 10 ) + " - " + CEPRUAIMP->CIDADE
         cCIDADE := CEPRUAIMP->CIDADE
         IF Empty( cepruaimp->UF ) .AND. At( "/", cCIDADE ) > 0
            IF At( "  - DISTRITO", cCIDADE ) > 0 .AND. At( "(", cCIDADE ) > 0  // NOSSA SENHORA DO REMEDIO (SALESOPOLIS)/SP  - DISTRITO
               nPOS    := At( "(", cCIDADE )
               cCIDADE := SubStr( cCIDADE, nPOS + 1 )
               cCIDADE := StrTran( cCIDADE, ")", "" )
            ENDIF
            IF At( "  - POVOADO", cCIDADE ) > 0 .AND. At( "(", cCIDADE ) > 0   // NOSSA SENHORA DO REMEDIO (SALESOPOLIS)/SP  - POVOADO
               nPOS    := At( "(", cCIDADE )
               cCIDADE := SubStr( cCIDADE, nPOS + 1 )
               cCIDADE := StrTran( cCIDADE, ")", "" )
            ENDIF
            nPOS              := At( "/", cCIDADE )
            cepruaimp->UF     := Left( SubStr( cCIDADE, nPOS + 1 ), 2 )
            CEPRUAIMP->CIDADE := SubStr( cCIDADE, 1, nPOS - 1 )
         ENDIF
         dbSkip()
      ENDDO
   ENDIF

// alguns importadores tranzem somente o ibge gravando a cidade para usar o cidlooop
   dbSelectAr( "cepruaimp" )
   dbGoTop()
   WHILE !Eof()
      cCODIBGE := CEPRUAIMP->CODIBGE
      @ 24, 00 SAY Str( RecNo(), 10 ) + "/" + Str( nLASTREC, 10 ) + " - " + cCODIBGE
      IF Empty( cepruaimp->UF ) .AND. Empty( CEPRUAIMP->CIDADE )
         dbSelectAr( "MD10" )
         dbSetOrder( 3 )
         dbGoTop()
         IF dbSeek( cCODIBGE )
            cepruaimp->UF     := MD10->UF
            CEPRUAIMP->CIDADE := MD10->NOME
         ENDIF
      ENDIF
      dbSelectAr( "cepruaimp" )
      dbSkip()
   ENDDO

   dbSelectAr( "MD10" )  // retorna ordem 1 pois a 3 foi usada acima
   dbSetOrder( 1 )
   cCODIBGE := ""  // zera a variavel do loop acima

// //algumas vem com nome no parentes distrito(cidade)
   dbSelectAr( "cepruaimp" )
   dbGoTop()
   WHILE !Eof()
      cCIDADE := CEPRUAIMP->CIDADE
      @ 24, 00 SAY Str( RecNo(), 10 ) + "/" + Str( nLASTREC, 10 ) + " - " + cCIDADE
      IF At( "(", cCIDADE ) > 0
         CEPRUAIMP->CIDADE := TRATACIDADE( CEPRUAIMP->uf, cCIDADE )
      ENDIF
      dbSelectAr( "cepruaimp" )
      dbSkip()
   ENDDO
   cCidade := ""   // zera a variavel do loop acima


   dbSelectAr( "cepruaimp" )
   dbSetOrder( 1 )
   dbGoTop()
   WHILE !Eof()

      // IF RECNO()=579443
      // ALTD()
      // ENDIF
      cUF      := cepruaimp->UF
      cUFLOOP  := cepruaimp->UF
      cCIDLOOP := cepruaimp->CIDADE  // nome usado para o loop usar sem nenhum tratamento
      cCIDADE  := Upper( TRATANOME( cepruaimp->CIDADE ) )
      // 01/02/2021 07:27 a cidade esta junto com o estado separado pela barra Ex: SAO PAULO/SP
      IF Empty( cUF ) .AND. At( "/", cCIDADE ) > 0
         nPOS    := At( "/", cCIDADE )
         cUSO    := cCIDADE
         cCIDADE := SubStr( cUSO, 1, nPOS - 1 )
         cUF     := Left( SubStr( cUSO, nPOS + 1 ), 2 )
         // Tratado com cufloop pois quando alterado a chave do uf cidade reposicionava o recno()
         // IF EMPTY(cepruaimp->UF) //grava a uf obtida para nao ficar travado no loop do while abaixo implantar futuramente cUFLOOP para melhorar tratativa
         // cepruaimp->UF:=cUF
         // ENDIF
      ENDIF

      // erro tamanho codigo zera para nao gravar errado
      cCODIBGE := AllTrim( cepruaimp->CODIBGE )
      IF Len( cCODIBGE ) < 7
         cCODIBGE := ""
      ENDIF

      // 01/02/2021 os dois numeros iniciais do ibge sao invalidos sera o codigo para nao zerar erro
      IF !Empty( cCODIBGE ) .AND. coduf( cCODIBGE, "UF" ) = "??"
         cCODIBGE := ""
      ENDIF

      // 01/02/2021 a sigla do estado ibge sao invalidos sera o codigo para nao zerar erro
      IF !Empty( cCODIBGE ) .AND. coduf( cCODIBGE ) = "??"
         cCODIBGE := ""
      ENDIF

      // 01/02/2021 07:32 a uf esta em branco mas tem o ibge para a sigla da uf pelo ibge
      IF !Empty( cCODIBGE ) .AND. Empty( cUF )
         cUF := coduf( cCODIBGE, "UF" )
      ENDIF

      ncodibge  := 0   // sequencia sempre zero pois agora e o ibge como sequencia
      eLOCALBAI := 0
      lACHEI    := .F.
      @ 24, 00 SAY cUF + PadR( cCIDADE, 30 ) + Str( RecNo(), 10 ) + "/" + Str( nLASTREC, 10 )
      IF !Empty( cUF ) .AND. !Empty( cCIDADE )
         cCIDBUSCA := TRATANOME( cCIDADE )
         cCODIBGE  := BUSCAIBGE( cUF, cCIDBUSCA )   // 1a tentativa com o nome  tratanome
         IF !Empty( cCODIBGE )
            ncodibge := Val( cCODIBGE )
            cCIDADE  := cCIDBUSCA
            lACHEI   := .T.
         ENDIF

         IF ncodibge = 0 .AND. At( "(", cCIDLOOP ) > 0
            cCIDBUSCA := TRATACIDADE( cUF, cCIDADE )
            cCODIBGE  := BUSCAIBGE( cUF, cCIDBUSCA )  // 2a. tentativa //cidades com nome parentes tratacidade
            IF !Empty( cCODIBGE )
               ncodibge := Val( cCODIBGE )
               cCIDADE  := cCIDBUSCA
               lACHEI   := .T.
            ENDIF
         ENDIF
      ENDIF

      IF ncodibge = 0 .AND. !Empty( cCODIBGE ) .AND. !Empty( cCIDLOOP )  // no comeca tras a cidade pelo codigo ibge //aqui e necessario ibge e nome da cidade para o cidloop while abaixo
         dbSelectAr( "MD10" )
         dbSetOrder( 3 )
         dbGoTop()
         IF dbSeek( cCODIBGE )
            IF Val( MD10->CODIBGE ) > 0
               ncodibge := Val( MD10->CODIBGE )
            ENDIF
            IF Empty( cUF ) .OR. Empty( cCIDADE )
               cUF     := MD10->UF
               cCIDADE := MD10->NOME
               // cCIDLOOP :=MD10->NOME // se cidloop manter da base para nao entrar em loop no  while abaixo
            ENDIF
            lACHEI := .T.
         ENDIF
      ENDIF


      IF ncodibge = 0 .AND. lACHEI
         ncodibge := 9999999   // tratado abaixo pois ibge 7 digitos cepnrua 6
      ENDIF
      lCEPRUA := .F.
      lCEPGEO := .F.

      IF ncodibge > 0  // agora sempre ibge
         cARQRUA  := "c" + cCODIBGE
         ncodibge := Val( cCODIBGE )
         IF !File( cARQRUA + ".dbf" )
            fileCOPY( "CEPRUA.DBF", cARQRUA + ".dbf" )
            dbUseArea( .T., "DBFCDX", cARQRUA,, .T. )
            INDEX ON RUA TAG &cARQRUA.1
            INDEX ON CEP TAG &cARQRUA.2
            dbCloseArea()
         ENDIF
         IF !File( cARQRUA + ".cdx" )
            dbUseArea( .T., "DBFCDX", cARQRUA,, .T. )
            INDEX ON RUA TAG &cARQRUA.1
            INDEX ON CEP TAG &cARQRUA.2
            dbCloseArea()
         ENDIF
         IF File( cARQRUA + ".dbf" ) .AND. File( cARQRUA + ".cdx" )
            lCEPRUA := .T.
            dbUseArea( .T., "DBFCDX", cARQRUA,, .T. )
            ordListAdd( cARQRUA )
            dbSetOrder( 2 )  // cep
         ENDIF
         // dados adcionais de
         cARQGEO := "g" + cCODIBGE
         IF !File( cARQGEO + ".dbf" )
            fileCOPY( "CEPGEO.DBF", cARQGEO + ".dbf" )
            dbUseArea( .T., "DBFCDX", cARQGEO,, .T. )
            INDEX ON CEP TAG &cARQGEO.1
            dbCloseArea()
         ENDIF
         IF !File( cARQGEO + ".cdx" )
            dbUseArea( .T., "DBFCDX", cARQGEO,, .T. )
            INDEX ON CEP TAG &cARQGEO.1
            dbCloseArea()
         ENDIF
         IF File( cARQGEO + ".dbf" ) .AND. File( cARQGEO + ".cdx" )
            lCEPGEO := .T.
            dbUseArea( .T., "DBFCDX", cARQGEO,, .T. )
            ordListAdd( cARQGEO )
            dbSetOrder( 1 )  // cep
         ENDIF
      ENDIF

      IF !lCEPRUA .OR. ( Empty( cUF ) .OR. Empty( cCIDADE ) )  //
         IF !Empty( AllTrim( cUF + " " + cCIDADE + " " + cCODIBGE ) )
            FWrite( nUSO, cUF + " " + cCIDLOOP + " " + cCODIBGE + hb_osNewLine() )
         ENDIF
         IF !Empty( cepruaimp->RUA ) .AND. !Empty( cepruaimp->bairro )
            dbSelectAr( "cepruaerr" )
            dbAppend()
            cepruaerr->cep     := cepruaimp->cep
            cepruaerr->obs     := cepruaimp->obs
            cepruaerr->RUA     := cepruaimp->RUA
            cepruaerr->Bairro  := cepruaimp->bairro
            cepruaerr->codibge := cepruaimp->codibge
            cepruaerr->uf      := cepruaimp->uf
            cepruaerr->cidade  := cepruaimp->cidade
         ENDIF
         dbSelectAr( "cepruaimp" )
         dbDelete()  // deletando os erros para nao fazer na proxima rodada
         dbSkip()
         LOOP
      ENDIF

      dbSelectAr( "cepruaimp" )
      WHILE cUFLOOP = cepruaimp->UF .AND. cCIDLOOP = AllTrim( cepruaimp->CIDADE ) .AND. !Eof()
         @ 24, 00 SAY cUF + PadR( cCIDADE, 30 ) + CEP + Str( RecNo(), 10 ) + "/" + Str( nLASTREC, 10 )
         IF lCEPRUA  // grava ou skip abaixo uf/cidade
            cCEP    := AllTrim( TIRAOUT( CEP ) )
            cRUA    := TRATANOME( cepruaimp->RUA )
            cBAIRRO := TRATANOME( cepruaimp->BAIRRO )
            cBAIRRO := StrTran( AllTrim( cBAIRRO ), "'", " " )
            cBAIRRO := StrTran( AllTrim( cBAIRRO ), '"', " " )
            cTIPO   := AllTrim( cepruaimp->TIPO )  // rua avenida .....
            cOBS    := AllTrim( cepruaimp->OBS )

            IF cRUA = "ull,"   // alguns web service trazem null
               cRUA := ""
            ENDIF

            IF cBAIRRO = "ull,"  // alguns web service trazem null
               cBAIRRO := ""
            ENDIF

            IF lCEPGEO .AND. ( !Empty( cepruaimp->DDD ) .OR. !Empty( cepruaimp->LATITUDE ) .OR. !Empty( cepruaimp->LONGITUDE ) )
               dbSelectAr( cARQGEO )
               dbGoTop()
               IF !dbSeek( cCEP )
                  dbAppend()
                  FIELD->CEP := cCEP
               ELSE
                  dbRLock()
               ENDIF
               IF Empty( field->DDD ) .AND. !Empty( cepruaimp->DDD )
                  field->DDD := cepruaimp->DDD
               ENDIF
               IF Empty( field->LATITUDE ) .AND. !Empty( cepruaimp->LATITUDE )
                  field->LATITUDE := cepruaimp->LATITUDE
               ENDIF

               IF Empty( field->LONGITUDE ) .AND. !Empty( cepruaimp->LONGITUDE )
                  field->LONGITUDE := cepruaimp->LONGITUDE
               ENDIF

               dbUnlock()
            ENDIF

            dbSelectAr( cARQRUA )
            dbGoTop()
            IF !dbSeek( cCEP )
               dbAppend()
               FIELD->CEP := cCEP
            ELSE
               dbRLock()
            ENDIF
            IF Empty( field->rua )
               field->rua := cRUA
            ENDIF
            IF Len( AllTrim( field->rua ) ) < 5 .AND. Len( AllTrim( cRUA ) ) > 5   // ruas que iram A B 1 UM ... e passaram a ter nome
               field->rua := cRUA
            ENDIF


            IF Empty( field->tipo )
               field->tipo := cTIPO
            ENDIF
            IF At( "LADO PAR", cOBS ) > 0 .AND. Empty( field->PARID )
               field->PARID := "P"
               cOBS         := StrTran( cOBS, "LADO PAR", "" )
               cOBS         := StrTran( cOBS, " - ", "" )
            ENDIF

            IF At( "(NUMERACAO COM ZERO A ESQUERDA)", cOBS ) > 0 .AND. Empty( field->PARID )
               field->PARID := "E"
               cOBS         := StrTran( cOBS, "(NUMERACAO COM ZERO A ESQUERDA)", "" )
               cOBS         := StrTran( cOBS, " - ", "" )
            ENDIF

            IF At( "LADO IMPAR", cOBS ) > 0 .AND. Empty( field->PARID )
               field->PARID := "I"
               cOBS         := StrTran( cOBS, "LADO IMPAR", "" )
               cOBS         := StrTran( cOBS, " - ", "" )
            ENDIF

            IF At( "AO FIM", cOBS ) > 0 .AND. Empty( field->NFIM )
               field->NFIM := 99999
               cOBS        := StrTran( cOBS, "AO FIM", "" )
            ENDIF

            // FLORENCA SEIS   DE 7700/7701 A 8099/8100 trata quando a observacao
            IF At( " DE ", cobs ) > 0 .AND. At( " A ", cobs ) > 0 .AND. At( "/", cobs ) > 0
               nPOS    := At( "DE ", cOBS )
               nvalini := 0
               NVALFIM := 0
               CINI    := ""
               CFIM    := ""
               IF nPOS > 0
                  cINI := SubStr( cOBS, nPOS + 3 )  // 7700/7701 A 8099/8100 separa a parde de
                  cOBS := SubStr( cOBS, nPOS + 3 )  // 7700/7701 A 8099/8100 se for lado para o impar pega o para para o inicial que e menor
                  nPOS := At( "/", cINI )   // quando nao e separado para ou impar nao tem o traco
                  IF nPOS > 0
                     cINI    := SubStr( cINI, 1, nPOS - 1 )  // 7700
                     nVALINI := Val( cINI )
                  ENDIF
                  nPOS := At( " A ", cOBS )
                  IF nPOS > 0  // //7700/7701 A 8099/8100 separa a parde A
                     cFIM := SubStr( cOBS, nPOS + 3 )   // 8099/8100
                  ENDIF
                  nPOS := At( "/", cFIM )
                  IF nPOS > 0
                     cFIM    := SubStr( cFIM, 1, nPOS - 1 )  // 8099
                     nVALFIM := Val( cFIM )
                  ENDIF
                  IF Nvalini > 0 .AND. NVALFIM > 0
                     FIELD->NINI := Nvalini
                     FIELD->NFIM := NvalFIM
                  ENDIF
               ENDIF

            ENDIF





            // usando nvalini,nvalfim para nao confundir com os campos NINI,NFIM
            IF At( " A ", cOBS ) > 0 .AND. Empty( field->NFIM )
               nVALINI := 0
               nVALFIM := 0
               nPOS    := At( " A ", cOBS )
               cOBS    := StrTran( cOBS, "LADO IMPAR", "" )  // tratados acima mas o parid pode ja estar preenchido ajustando aqui novamente
               cOBS    := StrTran( cOBS, " - ", "" )
               cOBS    := StrTran( cOBS, "LADO PAR", "" )
               cOBS    := StrTran( cOBS, " - ", "" )
               cOBS    := StrTran( cOBS, "(NUMERACAO COM ZERO A ESQUERDA)", "" )
               cOBS    := StrTran( cOBS, " - ", "" )
               cOBS    := StrTran( cOBS, "AO FIM", "" )
               cOBS    := StrTran( cOBS, " - ", "" )
               IF nPOS > 0
                  cFIM := SubStr( cOBS, nPOS + 3 )
                  nPOS := At( "/", cFIM )
                  IF nPOS > 0
                     cFIM := SubStr( cFIM, nPOS + 1 )
                  ENDIF
                  nVALFIM := Val( cFIM )
                  cOBS    := SubStr( cOBS, 1, nPOS - 1 )
                  nPOS    := At( "DE ", cOBS )
                  IF nPOS > 0
                     cINI := SubStr( cOBS, nPOS + 3 )
                     nPOS := At( "/", cINI )
                     IF nPOS > 0
                        cINI := SubStr( cINI, 1, nPOS - 1 )
                     ENDIF
                     nVALINI := Val( cINI )
                     cOBS    := SubStr( cOBS, 1, nPOS - 1 )
                  ENDIF
               ENDIF
               IF nVALFIM > 0 .AND. Empty( field->NFIM )
                  field->NFIM := nVALFIM
               ENDIF
               IF nVALINI > 0 .AND. Empty( field->NINI )
                  field->NINI := nVALINI
               ENDIF
            ENDIF


            IF At( "DE ", cOBS ) > 0 .AND. Empty( field->NINI )
               nVALINI := 0
               nPOS    := At( "DE ", cOBS )
               cOBS    := StrTran( cOBS, "LADO IMPAR", "" )  // tratados acima mas o parid pode ja estar preenchido ajustando aqui novamente
               cOBS    := StrTran( cOBS, " - ", "" )
               cOBS    := StrTran( cOBS, "LADO PAR", "" )
               cOBS    := StrTran( cOBS, " - ", "" )
               cOBS    := StrTran( cOBS, "(NUMERACAO COM ZERO A ESQUERDA)", "" )
               cOBS    := StrTran( cOBS, " - ", "" )
               cOBS    := StrTran( cOBS, "AO FIM", "" )
               cOBS    := StrTran( cOBS, " - ", "" )
               IF nPOS > 0
                  cINI := SubStr( cOBS, nPOS + 3 )
                  nPOS := At( "/", cINI )
                  IF nPOS > 0
                     cINI := SubStr( cINI, 1, nPOS - 1 )
                  ENDIF
                  nVALINI := Val( cINI )
                  cOBS    := SubStr( cOBS, 1, nPOS - 1 )
               ENDIF
               IF nVALINI > 0 .AND. Empty( field->NINI )
                  field->NINI := nVALINI
               ENDIF
            ENDIF


            IF Empty( field->chvbai ) .AND. !Empty( cBAIRRO )
               nCHVBAI := 0
               eBUSCA  := AllTrim( cBAIRRO )   // antes a chave era a cidade e o bairro STR(ncodibge,7)+cBAIRRO agora so o nome do bairro
               dbSelectAr( "cepbai" )
               dbSetOrder( 2 )   // 4 cep_bai_old nome bairro agora na cep_bai nova e o indice 2
               dbGoTop()
               IF dbSeek( eBUSCA )
                  nCHVBAI := bai_nu_seq
               ENDIF
               // if nCHVBAI=0  //as tabelas novas e buscas web nao trazem mais o nome reduzido utilizando agora so nome
               // eBUSCA:=STR(ncodibge,7)+cBAIRRO
               // dbselectar("cepbai")
               // dbsetorder(5) // nome bairro abreviado
               // dbgotop()
               // if dbseek(eBUSCA)
               // nCHVBAI:=bai_nu_seq
               // endif
               // endif
               IF nCHVBAI = 0  // inclui o bairro
                  //idbairro()   // utilizando idbairro ate completar os vaos no id
                  nLASTBAIRRO++
                  dbSelectAr( "cepbai" )
                  dbAppend()
                  cepbai->bai_nu_seq := nLASTBAIRRO
                  cepbai->bai_no     := cBAIRRO
                  // cepbai->loc_nu_seq:=ncodibge //agora a chave e so o nome do bairro
                  // cepbai->bai_no_abr:=cBAIRRO  //as bases nao trazem mais o bairro abreviado
                  nCHVBAI := bai_nu_seq
                  dbUnlock()
               ENDIF
               // Grava a chave
               dbSelectAr( cARQRUA )
               IF nCHVBAI > 0 .AND. ( Empty( field->chvbai ) .OR. field->chvbai <> nCHVBAI )   // sem o codigo do bairro ou bairro trocou de nome
                  field->chvbai := nCHVBAI
               ENDIF
               IF nCHVBAI > 0  // grava tambem na cepbailx (bairros cidades)
                  eBUSCA := cCODIBGE + Str( nCHVBAI, 7 )
                  dbSelectAr( "cepbailx" )
                  dbSetOrder( 1 )  // ibge chave bairro
                  dbGoTop()
                  IF !dbSeek( eBUSCA )
                     dbAppend()
                     cepbailx->BAI_NU_NEW := nCHVBAI
                     cepbailx->CODIBGE    := cCODIBGE
                  ENDIF
                  dbUnlock()
               ENDIF
               dbSelectAr( cARQRUA )
            ENDIF
            dbUnlock()
         ENDIF
         dbSelectAr( "cepruaimp" )
         dbSkip()
      ENDDO
      IF lCEPRUA
         dbSelectAr( cARQRUA )
         dbCloseArea()
      ENDIF
      IF lCEPGEO
         dbSelectAr( cARQGEO )
         dbCloseArea()
      ENDIF

      dbSelectAr( "cepruaimp" )  // skip no loop acima linhas acima
   ENDDO
   dbCloseAll()
   FClose( nUSO )



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function tratacidade()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION tratacidade( cUF, cNOME )   // algumas vem com nome no parentes distrito(cidade)

   cDISTRITO := ""
   cNOME     := tratanome( cNOME )
   npOS      := At( "(", cNOME )
   IF npOS > 0
      cDISTRITO := SubStr( cNOME, 1, nPOS - 1 )
      cNOME     := SubStr( cNOME, nPOS + 1 )
      cNOME     := AllTrim( cNOME )
   ENDIF
   cNOME := StrTran( cNOME, ")", "" )
   dbSelectAr( "cidconv" )
   dbGoTop()
   IF !dbSeek( cUF + cDISTRITO )
      dbAppend()
      cidconv->ESTADO := cUF
      cidconv->CIDORI := cDISTRITO
      cidconv->ESTDES := cUF
      cidconv->CIDDES := cNOME
   ENDIF

   RETURN cNOME


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function idbairro()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
//FUNCTION idbairro

  // dbSelectAr( "cepbai" )
  // dbSetOrder( 1 )
  // dbGoBottom()
  // nLASTBAIRRO:=cepbai->bai_nu_seq
  // nLASTBAIRRO++
  // @ 24, 00 SAY "bairro: " + Str( nlastbairro )
   //dbGoTop()
   //WHILE dbSeek( nLASTBAIRRO )
   //   nLASTBAIRRO++
   //   @ 24, 00 SAY "bairro: " + Str( nlastbairro )
   //ENDDO
   //dbSetOrder( 2 )   // antes 4 localcep ibge + nome agora so o nome index 2

   //RETURN


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function vertxt()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION vertxt

   RETURN .T.

// + EOF: cepruaimp.prg
// +
