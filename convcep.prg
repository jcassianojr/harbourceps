// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : convcep.prg
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


//
//
// arquivos do correio na maioria tem header e footer por isso
// e deletado o primeiro e ultima na importacaoCE
#include "INKEY.CH"
#include "tshead.ch"


REQUEST HB_CODEPAGE_PTISO
REQUEST HB_LANG_PT
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

   MVINFOConfTela( "convcep - atualizador de cep" )

   netregosok()

   hb_idleState()
   Set( _SET_CODEPAGE, "PTISO" )
   hb_langSelect( 'PT' )
   rddSetDefault( "DBFCDX" )
   Set( _SET_OPTIMIZE, .T. )
   Set( _SET_DELETED, .T. )
   Set( _SET_SOFTSEEK, .T. )
   __SetCentury( .T. )
   Set( _SET_EPOCH, Year( Date() ) - 60 )
   Set( _SET_DATEFORMAT, "dd/mm/yyyy" )
   SetCursor( .T. )

   IF mdg( "Importar jason country" )
      JasonCountry()
   ENDIF

   aUF := { "AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", ;
      "MA", "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR", ;
      "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO", "EX", "XX" }

   aIBGE := { "12", "27", "13", "16", "29", "23", "53", "32", "52", ;
      "21", "31", "50", "51", "15", "25", "26", "22", "41", ;
      "33", "24", "11", "14", "43", "42", "28", "35", "17", "99", "99" }  // ex xx 99.99999 padrao speds alguns no lugar de 54


   Lmunicipios := .F.
   IF File( "municipios.dbf" ) .AND. File( "md10imp.dbf" ) .AND. MsgYesNo( "importar municipios/sped" )
      USE md10imp NEW EXCLUSIVE
      ZAP
      APPEND FROM municipios
      dbCloseArea()
      Lmunicipios := .T.
   ENDIF

   lpgcn := .F.
   IF File( "pgcn.dbf" ) .AND. File( "md10imp.dbf" ) .AND. MsgYesNo( "importar pgcn ddd dados.gov" )
      // pesquisar anatel ddd na dados.gov
      // Codigo IBGE;UF;MUNICiPIO;CoDIGO_NACIONAL
      // CODIBGE;UF;NOME;DDD
      // psapad trocar cabecario acima
      // remover acentos
      // fixar ansi e delimitador linha dos
      // trocar '' para espaco e ' para nada (ajustar nome com 'd''aqua' ou semelantes
      USE md10imp NEW EXCLUSIVE
      ZAP
      APPEND FROM pgcn
      dbCloseArea()
      lpgcn := .T.
   ENDIF

/* CE_F anatel  https://sistemas.anatel.gov.br/areaarea/N_Download/Tela.asp?varMod=Publico&SISQSmodulo=7179
1 Sigla UF                            char 02
02 Sigla CNL                           char 04
03 Codigo CNL                          char 05
04 Nome da Localidade                  char 50
05 Nome do Municipio                   char 50
06 Cod. da Area Tarifacao              char 05   2 primeiros digitos DDD  CE_F dois campos ddd 2 CODARTAR 3
07 Prefixo                             char 07
08 Prestadora                          char 30
09 Num. da Faixa Inicial               char 04
10 Num. da Faixa Final                 char 04
11 Latitude                            char 08 (*)
12 Hemisferio                          char 05
13 Longitude                           char 08 (*)
14 Sigla CNL da Área Local             char 04

OBSERVAÇÕES:
1) Os campos marcados com (*), Latitude e Longitude foram
   alterados para o formato GGMMSSCC,
   onde:
   GG = Grau,
   MM = Minuto,
   SS = Segundo e
   CC = Centésimos de Segundo
*/

   lCE_F := .F.
   IF File( "ce_f.txt" ) .AND. File( "CE_F.dbf" ) .AND. File( "md10imp.dbf" ) .AND. MsgYesNo( "importar CE_F anatel" )
      nLASTREC := 0
      IF MsgYesNo( "importar CE_F.txt para ce_f.dbf" )
         USE ce_f NEW EXCLUSIVE
         nLASTREC := FLINECOUNT( "ce_f.txt" )
         zei_fort( nLASTREC,,, 0 )
         APPEND FROM ce_f.txt SDF WHILE zei_fort( nLASTREC,,, 1 )
         dbCloseArea()
      ENDIF

      IF MsgYesNo( "importar CE_F.DBF para MD10IMP.dbf" )
         zei_fort( nLASTREC,,, 0 )
         USE md10imp NEW EXCLUSIVE
         ZAP
         APPEND FROM CE_F WHILE zei_fort( nLASTREC,,, 1 )
         dbCloseArea()
      ENDIF
      lCE_F := .T.
   ENDIF

   IF ( File( "md10imp.dbf" ) .AND. ( lpgcn .OR. Lmunicipios .OR. lCE_F .OR. MsgYesNo( "Importar Cidades md10imp.dbf" ) ) )
      nUSO := FCreate( "MD10IMP.TXT" )
      USE md10imp NEW SHARED
      netuse( "cidconv" )
      netuse( "MD10" )
      dbSelectAr( "md10imp" )
      dbGoTop()
      WHILE !Eof()
         mNOME    := md10imp->nome
         mUF      := md10imp->uf
         mNOME    := tratanome( mNOME, .T., .T. ,.T.)
         mDDD     := md10imp->DDD
         mCODIBGE := md10imp->CODIBGE

         // mCODTSE   := md10imp->CODTSE     mesmo codigo codirrf
         mCODBACEN := md10imp->CODBACEN
         mCODIRRF  := md10imp->CODIRRF
         mCODSIAFI := md10imp->CODSIAFI

         mINICEP := md10imp->INICEP
         mFIMCEP := md10imp->FIMCEP

         mAREA   := md10imp->AREA
         mNOMTEL := md10imp->NOMTEL
         mCODTEL := md10imp->CODTEL

         mlatitude   := md10imp->latitude
         mlongitude  := md10imp->longitude
         mhemisferio := md10imp->hemisferio

         mCENTROI := md10imp->CENTROI  // "POINT(-46.3739271518483 -23.5609457306696)"
         IF !Empty( mCENTROI )
            mCENTROI := StrTran( mCENTROI, "POINT", "" )
            mCENTROI := StrTran( mCENTROI, "(", "" )
            mCENTROI := StrTran( mCENTROI, ")", "" )

            nPOSGEO := At( " ", mCENTROI )
            IF nPOSGEO > 0
               mLATITUDE  := SubStr( mCENTROI, nPOSGEO + 1 )  // 23
               mLONGITUDE := SubStr( mCENTROI, 1, nPOSGEO - 1 )  // 46
            ENDIF
         ENDIF



         IF !Empty( mUF ) .AND. AScan( aIBGE, mUF ) > 0   // A uf esta com codigo e nao com a sigla
            mUF := CODUF( mUF, "UF" )
         ENDIF
         IF Empty( mUF ) .AND. !Empty( mCODIBGE ) .AND. AScan( aIBGE, Left( mCODIBGE, 2 ) ) > 0  // pega uf pelo ibge
            mUF := CODUF( mCODIBGE, "UF" )
         ENDIF
         @ MaxRow(), 00 SAY mUF + " " + mNOME
         lACHEI := .F.
         IF !lACHEI .AND. !Empty( mUF ) .AND. !Empty( mNOME )
            dbSelectAr( "md10" )
            dbSetOrder( 1 )  // nome
            dbGoTop()
            IF dbSeek( mUF + mNOME )
               netreclock()
               lACHEI := .T.
            ENDIF
         ENDIF
         IF !lACHEI .AND. !Empty( mUF ) .AND. !Empty( mNOME )
            mNOME := pegcidconv( mUF, mNOME )   // nome convertido
            dbSelectAr( "md10" )
            dbSetOrder( 1 )
            dbGoTop()
            IF dbSeek( mUF + mNOME )
               netreclock()
               lACHEI := .T.
            ENDIF
         ENDIF
         IF !lACHEI .AND. !Empty( mCODIbGE )
            dbSelectAr( "md10" )
            dbSetOrder( 3 )
            dbGoTop()
            IF dbSeek( mCODIBGE )
               netreclock()
               lACHEI := .T.
            ELSE
               dbAppend()
               lACHEI        := .T.
               md10->NOME    := mNOME
               md10->UF      := mUF
               md10->CodIBGE := mCODIBGE
            ENDIF
         ENDIF
         IF lACHEI
            IF !Empty( mDDD ) .AND. Empty( md10->DDD )
               md10->DDD := mDDD
            ENDIF
            IF !Empty( mCODIBGE ) .AND. Empty( md10->CODIBGE )
               md10->CODIBGE := mCODIBGE
            ENDIF

            IF !Empty( mCODIRRF ) .AND. Empty( md10->CODIRRF )
               md10->CODIRRF := mCODIRRF
            ENDIF
            // if ! empty(mCODTSE)   .AND. EMPTY(md10->CODTSE)       mesmo codigo codirrf
            // md10->CODTSE := mCODTSE
            // endif
            IF !Empty( mCODBACEN ) .AND. Empty( md10->CODBACEN )
               md10->CODBACEN := mCODBACEN
            ENDIF
          
            IF !Empty( mCODSIAFI ) .AND. Empty( md10->CODSIAFI )
               md10->CODSIAFI := mCODSIAFI
            ENDIF
          
            
            IF !Empty( mINICEP ) .AND. Val( md10->INICEP ) = 0
               md10->INICEP := mINICEP
            ENDIF
            IF !Empty( mFIMCEP ) .AND. Val( md10->FIMCEP ) = 0
               md10->FIMCEP := mFIMCEP
            ENDIF
            IF !Empty( mINICEP ) .AND. !Empty( mFIMCEP )
               IF Val( mINICEP ) = Val( md10->INICEP ) .AND. Val( md10->INICEP ) = Val( md10->FIMCEP )
                  IF Val( mFIMCEP ) > Val( md10->FIMCEP )
                     md10->FIMCEP := mFIMCEP
                     FWrite( nUSO, "CODIBGE: " + MCodiBGE + " " + MUF + " " + MNOME + "Faixa:= " + mINICEP + "-" + mFIMCEP + hb_osNewLine() )
                  ENDIF
               ENDIF
            ENDIF
            IF !Empty( mNOMTEL ) .AND. Val( md10->NOMTEL ) = 0
               md10->NOMTEL := mNOMTEL
            ENDIF
            IF !Empty( mCODTEL ) .AND. Val( md10->CODTEL ) = 0
               md10->CODTEL := mCODTEL
            ENDIF
            IF AT("-",mLATITUDE)>0
               mLATITUDE:=STRTRAN(mLATITUDE,"-","")
               IF EMPTY(MHEMISFERIO)
                  MHEMISFERIO:="S"
               ENDIF
            ENDIF
            IF AT("+",mLATITUDE)>0
               mLATITUDE:=STRTRAN(mLATITUDE,"+","")
               IF EMPTY(MHEMISFERIO)
                  MHEMISFERIO:="N"
               ENDIF
            ENDIF
     
            IF AT("-",mLONGITUDE)>0
               mLONGITUDE:=STRTRAN(mLONGITUDE,"-","")
            ENDIF       
             IF AT("+",mLONGITUDE)>0
               mLONGITUDE:=STRTRAN(mLONGITUDE,"+","")
            ENDIF     
            
            IF !Empty( mLATITUDE ) .AND. Val( md10->LATITUDE ) = 0
               md10->LATITUDE := MLATITUDE
            ENDIF
            IF !Empty( mLONGITUDE ) .AND. Val( md10->LONGITUDE ) = 0
               md10->LONGITUDE := MLONGITUDE
            ENDIF
            IF !Empty( mHEMISFERIO ) .AND. Val( md10->HEMISFERIO ) = 0
               md10->HEMISFERIO := MHEMISFERIO
            ENDIF
            IF mAREA > 0 .AND. md10->AREA = 0
               md10->AREA := mAREA
            ENDIF
            dbUnlock()
         ELSE
            FWrite( nUSO, "CODIBGE: " + MCodiBGE + " " + MUF + " " + MNOME + hb_osNewLine() )
         ENDIF
         dbSelectAr( "md10imp" )
         dbSkip()
      ENDDO
      dbCloseAll()
      FClose( nUSO )
   ENDIF

   IF MsgYesNo( "Ajustar Arquivo Checagem 5 Digitos MD10->MD11" )
      netuse( "MD10" )
      netuse( "MD11" )
      dbSelectAr( "MD10" )
      dbGoTop()
      WHILE !Eof()
         @ 24, 70 SAY RecNo()
         mCEPINI := Left( INICEP, 5 )
         mCEPFIM := Left( FIMCEP, 5 )
         IF !Empty( mCEPINI )
            dbSelectAr( "MD11" )
            mCEPINI := Val( mCEPINI )
            mCEPFIM := Val( mCEPFIM )
            FOR X := mCEPINI TO mCEPFIM
               cCHAVE := StrZero( X, 5 )
               @ 24, 60 SAY cCHAVE
               dbGoTop()
               IF !dbSeek( cCHAVE )
                  netrecapp()
                  field->CEP := cCHAVE
               ENDIF
            NEXT X
         ENDIF
         dbSelectAr( "MD10" )
         dbSkip()
      ENDDO
      dbCloseAll()
   ENDIF


   IF MsgYesNo( "Ajustar tipos de rua" )
      lAPAGAMIL    := MsgYesNo( "Apagar ceps menores que 10000" )  // Agiliza processo recomendado para novas importacao pois pode tre trazido ceps errados
      lAPAGASEMRUA := MsgYesNo( "Apagar ceps sem nome de rua e bairro" )   // alguns ceps como prefeitura posto caixa postal nao tem rua mas tem bairro
      aTIT         := {}
      aCOD         := {}
      netuse( "mdtip" )
      dbGoTop()
      WHILE !Eof()
         AAdd( aTIT, AllTrim( NOME ) )
         AAdd( aCOD, AllTrim( CODIGO ) )
         dbSkip()
      ENDDO
      dbCloseArea()
      mArquivo  := 'C*.dbf'
      mListaArq := Directory( mArquivo, "D" )
      nFIMARQ   := Len( mListaArq )
      FOR i := 1 TO nfimARQ
         cFILECEP := Lower( mListaArq[ i, 1 ] )
         cFILECEP := StrTran( cFILECEP, ".dbf", "" )
         @ 24, 00 SAY Space( 80 )

         // 01/02/2021 06:26 cria o arquivo de indexes caso ele nao exista
         IF !File( cFILECEP + ".CDX" ) .AND. File( cFILECEP + ".DBF" )
            NETUSE( cFILECEP,,,,, .F., )
            nLASTREC := LastRec()
            zei_fort( nLASTREC,,, 0 )
            INDEX ON RUA TAG &cFILECEP.1 EVAL ZEI_FORT( nLASTREC,,, 1 )
            INDEX ON CEP TAG &cFILECEP.2 EVAL ZEI_FORT( nLASTREC,,, 1 )
            dbCloseArea()
         ENDIF

         IF cFILECEP <> "ceprua" .AND. cFILECEP <> "cepbai" .AND. cFILECEP <> "cidconv" .AND. NETUSE( cFILECEP )   // nao considerar arquivos que nao de rua
            nLASTREC := LastRec()
            zei_fort( nLASTREC,,, 0 )
            IF lAPAGAMIL
               dbEval( {|| netrecdel() }, {|| Val( cep ) < 10000 }, {|| zei_fort( nLASTREC,,, 1 ) } )
               zei_fort( nLASTREC,,, 0 )  // zera pois e exibito novamente
            ENDIF
            dbSetOrder( 0 )  // deixa sem ordencao pois o nome sofre replace e um dos indices
            @ 23, 00 SAY cFILECEP + " " + Str( i ) + "/" + Str( nfimARQ )
            dbGoTop()
            WHILE !Eof()
               // @ 24,09 SAY RECNO() PICT "99999"
               @ 24, 00 SAY Left( RUA, 30 )
               zei_fort( nLASTREC,,, 1 )
               NETRECLOCK()
               IF Upper( RUA ) <> RUA
                  FIELD->RUA := Upper( RUA )
               ENDIF
               nPOS := At( "LADO IMPAR", RUA )
               IF nPOS > 0
                  FIELD->PARID := "I"
                  FIELD->RUA   := StrTran( RUA, "LADO IMPAR", "" )
               ENDIF
               nPOS := At( "LADO PAR", RUA )
               IF nPOS > 0
                  FIELD->PARID := "P"
                  FIELD->RUA   := StrTran( RUA, "LADO PAR", "" )
               ENDIF

               nPOS := At( "LADO ESQUERDO", RUA )
               IF nPOS > 0
                  IF Empty( FIELD->PARID )
                     FIELD->PARID := "E"
                  ENDIF
                  FIELD->RUA := StrTran( RUA, "LADO ESQUERDO", "" )
               ENDIF

               nPOS := At( "LADO DIREITO", RUA )
               IF nPOS > 0
                  IF Empty( FIELD->PARID )
                     FIELD->PARID := "D"
                  ENDIF
                  FIELD->RUA := StrTran( RUA, "LADO DIREITO", "" )
               ENDIF

               nPOS := At( "LADO IMP", RUA )
               IF nPOS > 0
                  FIELD->PARID := "I"
                  FIELD->RUA   := StrTran( RUA, "LADO IMPAR", "" )
               ENDIF

               IF Right( AllTrim( RUA ), 3 ) = "- D"
                  FIELD->RUA := StrTran( RUA, "- D", "" )
                  IF Empty( FIELD->PARID )
                     FIELD->PARID := "D"
                  ENDIF
               ENDIF

               IF Right( AllTrim( RUA ), 3 ) = "- E"
                  FIELD->RUA := StrTran( RUA, "- E", "" )
                  IF Empty( FIELD->PARID )
                     FIELD->PARID := "E"
                  ENDIF
               ENDIF

               // 31/01/2021 22:00 ajustar rua que ficam com espaco traco " -"  no final
               IF Right( AllTrim( RUA ), 2 ) = " -"
                  FIELD->RUA := SubStr( RUA, 1, Len( AllTrim( RUA ) ) - 2 )
               ENDIF

               IF At( "AO FIM", RUA ) > 0
                  field->NFIM := 99999
                  FIELD->RUA  := StrTran( RUA, "AO FIM", "" )
               ENDIF

               // FLORENCA SEIS   DE 7700/7701 A 8099/8100 trata quando a observacao veio junto com o nome da rua
               IF At( " DE ", RUA ) > 0 .AND. At( " A ", RUA ) > 0 .AND. At( "/", RUA ) > 0 .AND. At( "CAIXA POSTAL", RUA ) = 0
                  cOBS    := FIELD->RUA
                  nPOS    := At( "DE ", cOBS )
                  nvalini := 0
                  NVALFIM := 0
                  CINI    := ""
                  CFIM    := ""
                  IF nPOS > 0
                     cINI       := SubStr( cOBS, nPOS + 3 )   // 7700/7701 A 8099/8100 separa a parde de
                     FIELD->RUA := SubStr( cOBS, 1, nPOS - 2 )   // FLORENCA SEIS grava somente a rua
                     cOBS       := SubStr( cOBS, nPOS + 3 )   // 7700/7701 A 8099/8100 se for lado para o impar pega o para para o inicial que e menor
                     nPOS       := At( "/", cINI )  // quando nao e separado para ou impar nao tem o traco
                     IF nPOS > 0
                        cINI    := SubStr( cINI, 1, nPOS - 1 )   // 7700
                        nVALINI := Val( cINI )
                     ENDIF
                     nPOS := At( " A ", cOBS )
                     IF nPOS > 0   // //7700/7701 A 8099/8100 separa a parde A
                        cFIM := SubStr( cOBS, nPOS + 3 )  // 8099/8100
                     ENDIF
                     nPOS := At( "/", cFIM )
                     IF nPOS > 0
                        cFIM    := SubStr( cFIM, 1, nPOS - 1 )   // 8099
                        nVALFIM := Val( cFIM )
                     ENDIF
                     IF Nvalini > 0 .AND. NVALFIM > 0
                        FIELD->NINI := Nvalini
                        FIELD->NFIM := NvalFIM
                     ENDIF
                  ENDIF
               ENDIF


               IF At( " DE ", RUA ) > 0 .AND. At( " ATE ", RUA ) > 0 .AND. At( "/", RUA ) > 0 .AND. At( "CAIXA POSTAL", RUA ) = 0
                  cOBS    := FIELD->RUA
                  nPOS    := At( "DE ", cOBS )
                  nvalini := 0
                  NVALFIM := 0
                  CINI    := ""
                  CFIM    := ""
                  IF nPOS > 0
                     cINI       := SubStr( cOBS, nPOS + 3 )   // 7700/7701 A 8099/8100 separa a parde de
                     FIELD->RUA := SubStr( cOBS, 1, nPOS - 2 )   // FLORENCA SEIS grava somente a rua
                     cOBS       := SubStr( cOBS, nPOS + 3 )   // 7700/7701 A 8099/8100 se for lado para o impar pega o para para o inicial que e menor
                     nPOS       := At( "/", cINI )  // quando nao e separado para ou impar nao tem o traco
                     IF nPOS > 0
                        cINI    := SubStr( cINI, 1, nPOS - 1 )   // 7700
                        nVALINI := Val( cINI )
                     ENDIF
                     nPOS := At( " ATE ", cOBS )
                     IF nPOS > 0   // //7700/7701 A 8099/8100 separa a parde A
                        cFIM := SubStr( cOBS, nPOS + 3 )  // 8099/8100
                     ENDIF
                     nPOS := At( "/", cFIM )
                     IF nPOS > 0
                        cFIM    := SubStr( cFIM, 1, nPOS - 1 )   // 8099
                        nVALFIM := Val( cFIM )
                     ENDIF
                     IF Nvalini > 0 .AND. NVALFIM > 0
                        FIELD->NINI := Nvalini
                        FIELD->NFIM := NvalFIM
                     ENDIF
                  ENDIF
               ENDIF
               // PARQUE   ATE 481
               IF At( " DE ", RUA ) = 0 .AND. At( " ATE ", RUA ) > 0 .AND. At( "/", RUA ) = 0 .AND. At( "CAIXA POSTAL", RUA ) = 0
                  cOBS    := FIELD->RUA
                  nPOS    := At( " ATE ", cOBS )
                  nvalini := 0
                  NVALFIM := 0
                  CINI    := ""
                  CFIM    := ""
                  IF nPOS > 0
                     FIELD->RUA := SubStr( cOBS, 1, nPOS - 1 )
                     cFIM       := SubStr( cOBS, nPOS + 5 )
                     nVALFIM    := Val( cFIM )
                  ENDIF
                  IF Nvalini = 0 .AND. NVALFIM > 0
                     FIELD->NFIM := NvalFIM
                  ENDIF
               ENDIF

               // PARQUE   DE 1003 A 1531
               IF At( " DE ", RUA ) > 0 .AND. At( " A ", RUA ) > 0 .AND. At( "/", RUA ) = 0 .AND. At( "CAIXA POSTAL", RUA ) = 0
                  cOBS    := FIELD->RUA
                  nPOS    := At( " DE ", cOBS )
                  nvalini := 0
                  NVALFIM := 0
                  CINI    := ""
                  CFIM    := ""
                  IF nPOS > 0
                     FIELD->RUA := SubStr( cOBS, 1, nPOS - 1 )   // PARQUE
                     cOBS       := SubStr( cOBS, nPOS + 4 )   // 1003 A 1531
                     nPOS       := At( " A ", cOBS )
                     IF nPOS > 0
                        cINI    := SubStr( cOBS, 1, nPOS - 1 )
                        cFIM    := SubStr( cOBS, nPOS + 3 )
                        nVALINI := Val( cINI )
                        nVALFIM := Val( cFIM )
                     ENDIF
                     IF Nvalini > 0 .AND. NVALFIM > 0
                        FIELD->NINI := Nvalini
                        FIELD->NFIM := NvalFIM
                     ENDIF
                  ENDIF
               ENDIF

               // PARQUE   ATE 481/1233
               IF At( " DE ", RUA ) = 0 .AND. At( " ATE ", RUA ) > 0 .AND. At( "/", RUA ) > 0 .AND. At( "CAIXA POSTAL", RUA ) = 0
                  cOBS    := FIELD->RUA
                  nPOS    := At( " ATE ", cOBS )
                  nvalini := 0
                  NVALFIM := 0
                  CINI    := ""
                  CFIM    := ""
                  IF nPOS > 0
                     FIELD->RUA := SubStr( cOBS, 1, nPOS - 1 )
                     cobs       := SubStr( cOBS, nPOS + 5 )
                     nPOS       := At( "/", cOBS )
                     IF nPOS > 0
                        cFIM    := SubStr( COBS, nPOS + 1 )
                        nVALFIM := Val( cFIM )
                     ENDIF
                  ENDIF
                  IF Nvalini = 0 .AND. NVALFIM > 0
                     FIELD->NFIM := NvalFIM
                  ENDIF
               ENDIF







               nPOS := At( " ", RUA )   // nao processa se so tiver uma palavra sem necessidade de verificar
               IF nPOS > 0
                  cTIPO := AllTrim( Left( RUA, nPOS - 1 ) )   // pega a primeira palavra para verifica se e um tipo
                  cRUA  := AllTrim( SubStr( RUA, nPOS + 1 ) )
                  @ 24, 00 SAY Left( cRUA, 30 )
                  @ 24, 31 SAY cTIPO
                  IF Len( cRUA ) > 0 .AND. Len( cTIPO ) > 2
                     IF AScan( aTIT, cTIPO ) > 0
                        FIELD->RUA  := cRUA
                        FIELD->TIPO := cTIPO
                     ENDIF
                  ENDIF
                  IF Len( cRUA ) > 1 .AND. Len( cTIPO ) < 3 .AND. !Empty( cTIPO )
                     nPOSCOD := AScan( aCOD, cTIPO )
                     IF nPOSCOD > 0
                        FIELD->RUA  := cRUA
                        FIELD->TIPO := aTIT[ nPOSCOD ]
                     ENDIF
                  ENDIF
               ENDIF
               IF Empty( TIPO )
                  nPOS := RAt( " ", AllTrim( RUA ) )
                  IF nPOS > 0
                     cTIPO := AllTrim( SubStr( RUA, nPOS + 1 ) )
                     cRUA  := AllTrim( SubStr( RUA, 1, nPOS - 1 ) )
                     @ 24, 50 SAY Left( cRUA, 19 )
                     @ 24, 70 SAY cTIPO
                     IF Len( cRUA ) > 0 .AND. Len( cTIPO ) > 2
                        IF AScan( aTIT, cTIPO ) > 0
                           FIELD->RUA  := cRUA
                           FIELD->TIPO := cTIPO
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
               cTIPO := AllTrim( TIPO )
               IF Len( cTIPO ) < 3 .AND. !Empty( cTIPO )
                  nPOSCOD := AScan( aCOD, cTIPO )
                  IF nPOSCOD > 0
                     FIELD->TIPO := aTIT[ nPOSCOD ]
                  ENDIF
               ENDIF
               nPOS := At( " ", AllTrim( FIELD->RUA ) )   // checar se só o tipo esta na rua e exemplo rua="AVENIDA" deixando em rua em  branco para próxima importação ajustar
               IF nPOS = 0
                  Nposcod := AScan( aCOD, AllTrim( FIELD->RUA ) )
                  IF Nposcod > 0 .AND. AllTrim( FIELD->RUA ) = AllTrim( Acod[ nPOSCOD ] )
                     FIELD->RUA  := ""
                     FIELD->TIPO := Atit[ nPOSCOD ]
                     cRUA        := ""
                  ENDIF
                  Nposcod := AScan( aTIT, AllTrim( FIELD->RUA ) )
                  IF Nposcod > 0 .AND. AllTrim( FIELD->RUA ) = AllTrim( ATIT[ nPOSCOD ] )
                     FIELD->RUA  := ""
                     FIELD->TIPO := Atit[ nPOSCOD ]
                     cRUA        := ""
                  ENDIF
               ENDIF

               // TIPO = RUA deixando em rua em  branco para próxima importação ajustar
               IF AllTrim( FIELD->RUA ) = AllTrim( FIELD->TIPO )
                  FIELD->RUA := ""
               ENDIF

               nPOS := At( ",", FIELD->RUA )
               IF nPOS > 0 .AND. nPOS > 3
                  FIELD->RUA := SubStr( FIELD->RUA, 1, nPOS - 1 )
               ENDIF

               nPOS := At( "(", FIELD->RUA )
               IF nPOS > 0 .AND. nPOS > 3
                  FIELD->RUA := SubStr( FIELD->RUA, 1, nPOS - 1 )
               ENDIF


               nPOS := At( " S/N", FIELD->RUA )
               IF nPOS > 0 .AND. nPOS > 3
                  FIELD->RUA := SubStr( FIELD->RUA, 1, nPOS - 1 )
               ENDIF

               nPOS := At( Lower( "ull," ), FIELD->RUA )
               IF nPOS > 0
                  FIELD->RUA := ""
               ENDIF

               // 28/01/2021 11:08 checa se e um tipo valido se nao e limpa
               IF !Empty( field->tipo )
                  IF AScan( aTIT, AllTrim( field->tipo ) ) = 0 .AND. AScan( acod, AllTrim( field->tipo ) ) = 0
                     FIELD->TIPO := ""
                  ENDIF
               ENDIF

               // 31/01/201 21:59 opcao para apagar ceps com rua em branco
               IF lAPAGASEMRUA .AND. Empty( field->rua ) .AND. Empty( field->chvbai )  // alguns ceps como prefeitura posto caixa postal nao tem rua mas tem bairro
                  dbDelete()
               ENDIF
               dbUnlock()
               dbSkip()
            ENDDO
            dbCloseArea()
            IF lAPAGAMIL .OR. lAPAGASEMRUA
               NETPACK( cFILECEP )
            ENDIF
         ENDIF
      NEXT i
   ENDIF



   IF MsgYesNo( "Cruzar md10xmd10NAO" )
      netuse( "MD10" )
      netuse( "MD10NAO" )
      dbSelectAr( "md10nao" )
      WHILE !Eof()
         mNOME   := NOME
         mUF     := UF
         lTEM    := .F.
         aCAMPOS := { "DDD", "CODIBGE", "CODTEL", "NOMTEL", "LATITUDE", "LONGITUDE", "HEMISFERIO" }
         aDADOS  := { DDD, CODIBGE, CODTEL, NOMTEL, LATITUDE, LONGITUDE, HEMISFERIO }
         dbSelectAr( "md10" )
         IF dbSeek( mUF + mNOME )
            lTEM := .T.
            netreclock()
            FOR x := 1 TO Len( aCAMPOS )
               cCAMPO := ACAMPOS[ X ]
               IF Empty( &cCAMPO. ) .AND. !Empty( aDADOS[ X ] )
                  MD10->&cCAMPO. := aDADOS[ X ]
               ENDIF
            NEXT x
            dbUnlock()
         ENDIF
         dbSelectAr( "md10nao" )
         IF lTEM
            netrecdel()
         ENDIF
         dbSkip()
      ENDDO
      dbCloseAll()
   ENDIF

   IF MsgYesNo( "Gerar Log Duplicidades/Ajustes" )
      nAJUSTE := 35
      @ 24, 00 SAY "Fator Checagem"
      @ 24, 20 GET nAJUSTE
      READ
      nUSO := FCreate( "CONVCEP.TXT" )
      netuse( "MD10" )
      dbGoTop()
      WHILE !Eof()
         @ 24, 00 SAY UF + NOME
         mNOME     := AllTrim( NOME )
         cANTERIOR := INICEP + " " + UF + " " + NOME + hb_osNewLine()
         cCEPANT   := INICEP
         dbSkip()
         IF !Eof()
            IF Left( mNOME, nAJUSTE ) = Left( AllTrim( NOME ), nAJUSTE )
               FWrite( nUSO, "CEP: 1_" + cANTERIOR )
               FWrite( nUSO, "CEP: 2_" + INICEP + " " + UF + " " + NOME + hb_osNewLine() )
               FWrite( nUSO, "" + hb_osNewLine() )
               IF MsgYesNo( "Apagar " + Left( cANTERIOR, 40 ) + " " + UF + " " + NOME )
                  netrecdel()
               ENDIF
            ENDIF
         ENDIF
      ENDDO


      // codibge
      dbSetOrder( 3 )
      dbGoTop()
      WHILE !Eof()
         @ 24, 00 SAY UF + NOME
         nSEQ    := Codibge
         nRECOLD := RecNo()
         IF !Empty( CODIBGE )
            cUFCOD := CODUF( CODIBGE, "UF" )
            IF cUFCOD <> UF  // Checagem 2 digitos inicial da codibge do estado
               FWrite( nUSO, "CodIBGE <> UF : " + Codibge + " " + UF + "<>" + cUFCOD + " " + NOME+hb_osNewLine() )
            ENDIF
         ENDIF
         dbSkip()
         IF !Eof()
            IF nSEQ = CodIBGE
               IF UF <> "XX" .AND. !Empty( codibge )   // ibge duplicado
                  FWrite( nUSO, "CODIBGE: " + CodiBGE + " " + UF + " " + NOME+hb_osNewLine() )
               ENDIF
            ENDIF
         ENDIF

      ENDDO


      // codirrf
      dbSetOrder( 4 )
      dbGoTop()
      WHILE !Eof()
         @ 24, 00 SAY UF + NOME
         nSEQ := Codirrf
         dbSkip()
         IF !Eof()
            IF nSEQ = Codirrf
               IF UF <> "XX" .AND. !Empty( codirrf )   // irrf duplicado
                  FWrite( nUSO, "IRRF: " + Codirrf + " " + UF + " " + NOME+hb_osNewLine() )
               ENDIF
            ENDIF
         ENDIF
      ENDDO

      // ajustando ceps
      dbGoTop()
      WHILE !Eof()
         @ 24, 00 SAY UF + NOME
         IF Empty( INICEP )
            netgrvcam( "INICEP", repl( "0", 8 ) )
         ENDIF
         IF Empty( FIMCEP )
            netgrvcam( "FIMCEP", repl( "0", 8 ) )
         ENDIF
         IF !Empty( hemisferio )
            IF hemisferio = "N" .OR. hemisferio = "S"
            ELSE
               netgrvcam( "hemisferio", "" )
            ENDIF
         ENDIF
         dbSkip()
      ENDDO
      dbCloseArea()



      FClose( nUSO )
   ENDIF

   IF MsgYesNo( "Reindexar Arquivos Ruas" )
      FOR X := 1 TO 10000
         cARQRUA := "C" + StrZero( X, 6 )
         @ 24, 00 SAY cARQRUA
         IF File( cARQRUA + ".DBF" )
            NETPACK( cARQRUA )
            IF FErase( cARQRUA + ".CDX" ) = 0 .OR. !File( cARQRUA + ".CDX" )
               NETUSE( cARQRUA,,,,, .F., )
               nLASTREC := LastRec()
               zei_fort( nLASTREC,,, 0 )
               INDEX ON RUA TAG &cARQRUA.1 EVAL ZEI_FORT( nLASTREC,,, 1 )
               INDEX ON CEP TAG &cARQRUA.2 EVAL ZEI_FORT( nLASTREC,,, 1 )
               dbCloseArea()
            ENDIF
         ENDIF
      NEXT
   ENDIF

   IF MsgYesNo( "Contar Cidades" )
      @ 24, 00 SAY PadR( "Importando cidades" )
      NETUSE( "MD10" )
      NETUSE( "MD05" )
      dbSelectAr( "MD10" )
      dbGoTop()
      WHILE !Eof()
         nQTDECID := 0
         cUF      := UF
         WHILE cUF = UF .AND. !Eof()   // todos agora na MD1O sao M com codigo ibge
            nQTDECID++
            @ 24, 00 SAY UF + " " + NOME
         /* rodado apenas para ajuste
          IF LEN(ALLTRIM(MD10->CODIRRF))=4 .AND. LEN(ALLTRIM(MD10->CODTSE))=5
             netreclock()
             MD10->CODIRRF:=MD10->CODTSE
             DBUNLOCK()
          ENDIF
          */
            dbSkip()
         ENDDO
         dbSelectAr( "MD05" )
         dbGoTop()
         IF dbSeek( cUF )
            netgrvcam( "QTDECID", nQTDECID )
         ENDIF
         dbSelectAr( "MD10" )
      ENDDO
      dbCloseAll()
   ENDIF
   IF MsgYesNo( "Atualizar cidirrf" )
      @ 24, 00 SAY PadR( "atualizando cidirrf" )
      NETUSE( "MD10" )
      NETUSE( "CIDIRRF" )
      dbSelectAr( "MD10" )
      dbGoTop()
      WHILE !Eof()
         cCODCID  := Left( MD10->CODIRRF, 4 )
         cCODIRRF := MD10->CODIRRF
         cCODIBGE := MD10->CODIBGE
         cNOMECID := MD10->NOME
         dbSelectAr( "CIDIRRF" )
         dbGoTop()
         IF !dbSeek( cCODCID )
            netrecapp()
            CIDIRRF->CODCID := cCODCID
         ELSE
            netreclock()
         ENDIF
         IF Empty( CIDIRRF->CODIRRF )
            CIDIRRF->CODIRRF := cCODIRRF
         ENDIF
         IF Empty( CIDIRRF->CODIBGE )
            CIDIRRF->CODIBGE := cCODIBGE
         ENDIF
         IF Empty( CIDIRRF->NOMECID )
            CIDIRRF->NOMECID := cNOMECID
         ENDIF
         dbUnlock()
         dbSelectAr( "MD10" )
         dbSkip()
      ENDDO
      dbCloseAll()
   ENDIF
   IF MsgYesNo( "Atualizar prcid" )
      @ 24, 00 SAY PadR( "atualizando prcid" )
      NETUSE( "MD10" )
      NETUSE( "prcid" )
      dbSetOrder( 2 )
      dbSelectAr( "MD10" )
      dbGoTop()
      WHILE !Eof()
         IF MD10->UF = "PR"
            cCODIRRF := MD10->CODIRRF
            cCODIBGE := MD10->CODIBGE
            cNOMECID := AllTrim( MD10->NOME )
            dbSelectAr( "prcid" )
            dbGoTop()
            IF !dbSeek( cNOMECID )
               netrecapp()
               prcid->MUNICIPIO := cNOMECID
            ELSE
               netreclock()
            ENDIF
            IF Empty( prcid->CODIRRF )
               prcid->CODIRRF := cCODIRRF
            ENDIF
            IF Empty( prcid->CODIBGE )
               prcid->CODIBGE := cCODIBGE
            ENDIF
            dbUnlock()
         ENDIF
         dbSelectAr( "MD10" )
         dbSkip()
      ENDDO
      dbCloseAll()
   ENDIF

   RETURN NIL



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function JasonCountry()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION JasonCountry()

   LOCAL kk

   kk := 1

   netuse( "PAISES" )
   dbSetOrder( 2 )   // ISO3166B BRA

   mArquivo  := '*.json'
   mListaArq := Directory( mArquivo, "D" )
   nFIMARQ   := Len( mListaArq )

   FOR kk := 1 TO nFIMARQ
      cFILECEP := Lower( mListaArq[ kk, 1 ] )
      cXMl     := MemoRead( cFILECEP )


      cPOPULACAO := pegnodojason( cXMl, '"population":' )
      cAREA      := pegnodojason( cXMl, '"area":' )
      cREGION    := pegnodojason( cXMl, '"region":' )
      cCONTINENT := pegnodojason( cXMl, '"subregion":' )
      cMOEDA     := pegnodojason( cXMl, '"currencies":' )
      cISO3166A  := pegnodojason( cXMl, '"alpha2":' )
      cISO3166B  := pegnodojason( cXMl, '"alpha3":' )
      cddd       := pegnodojason( cXMl, '"callingCodes":' )
      cNOME      := TRATANOME( pegnodojason( cXMl, '"nativeName":' ), .F., .T., .T. )
      cNOME      := StrTran( cNOME, "'", " " )
      cNOME      := StrTran( cNOME, ",", " " )
      cNOME      := StrTran( cNOME, "(", " " )
      cNOME      := StrTran( cNOME, ")", " " )
      cnomeINT   := TRATANOME( pegnodojason( cXMl, '"name":' ), .F., .T., .T. )
      cNOMEINT   := StrTran( cNOMEINT, "'", " " )
      cNOMEINT   := StrTran( cNOMEINT, ",", " " )
      cNOMEINT   := StrTran( cNOMEINT, "(", " " )
      cNOMEINT   := StrTran( cNOMEINT, ")", " " )
      ccapital   := TRATANOME( pegnodojason( cXMl, '"capital":' ), .F., .T., .T. )
      cDOMINIO   := pegnodojason( cXMl, '"tld":' )

      dbSelectAr( "paises" )
      dbGoTop()
      IF !dbSeek( cISO3166B )
         netrecapp()
         field->ISO3166B := cISO3166B
         field->UF       := "XX"
      ELSE
         netreclock()
      ENDIF
      netgrvz( "NOMEINT", cNOMEINT, .F. )
      netgrvz( "DDD", cDDD, .F. )
      netgrvz( "NOME", cNOME, .F. )
      netgrvz( "AREA", Val( cAREA ), .F. )
      netgrvz( "CONTINENT", cCONTINENT, .F. )
      netgrvz( "ISO3166A", cISO3166A, .F. )
      netgrvz( "capital", ccapital, .F. )
      netgrvz( "URLPAIS", cDOMINIO, .F. )
      netgrvz( "CONTREGIAO", cREGION, .F. )
      netgrvz( "MOEDA", cMOEDA, .F. )

      dbUnlock()
      FErase( cFILECEP )
   NEXT kk

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function pegnodojason()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION pegnodojason( cTEXTO, cNODO )   // difeRente pegnodojason webcep pois aqui o nodo pode ter listas entre []

   LOCAL nPOSNODO

   nPOSNODO := At( cNODO, cTEXTO )
   IF nPOSNODO > 0
      cTEXTO := SubStr( cTEXTO, nPOSNODO + Len( cNODO ) )   // LEN(cNODO)+1
      DO CASE
      CASE SubStr( cTEXTO, 1, 1 ) = '"'
         cTEXTO := SubStr( cTEXTO, 2 )  // "BRA"
         CTEXTO := SubStr( cTEXTO, 1, At( '"', cTEXTO ) - 1 )
      CASE SubStr( cTEXTO, 1, 1 ) = '['
         cTEXTO := SubStr( cTEXTO, 3 )  // "[BRL]"
         CTEXTO := SubStr( cTEXTO, 1, At( ']', cTEXTO ) - 2 )
      CASE SubStr( cTEXTO, 1, 1 ) $ '0123456789'
         cTEXTO := SubStr( cTEXTO, 1, At( ",", cTEXTO ) - 1 )
      ENDCASE
   ENDIF
   nPOSNODO := At( '",', cTEXTO )
   IF nPOSNODO > 0   // nodos com mais de um exemplo dominio pega o primeiro
      cTEXTO := SubStr( cTEXTO, 1, nPOSNODO - 1 )
   ENDIF
   IF At( "{", cTEXTO ) > 0   // zera nodos invalidos
      cTEXTO := ""
   ENDIF

   RETURN cTEXTO


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function help()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION help

   RETU .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function cidconvinc()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION cidconvinc()

   LOCAL cALIAS, lRETU := .F.

   cALIAS := Alias()
   dbSelectAr( "cidconv" )
   dbGoTop()
   IF !dbSeek( mUF + mNOME )
      netrecapp()
      FIELD->ESTADO := mUF
      FIELD->CIDORI := mNOME
      FIELD->ESTDES := mUF
      FIELD->CIDDES := mCIDDES
      lRETU         := .T.
   ENDIF
   dbSelectAr( cALIAS )

   RETURN lRETU





// + EOF: convcep.prg
// +
