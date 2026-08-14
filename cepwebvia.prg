// +--------------------------------------------------------------------
// +
// +
// +
// +    Programa  : cepwebvia.prg
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


/*  Msxml2.XMLHTTP.6.0 Msxml2.XMLHTTP.3.0
1. Microsoft XML, v 3.0.
2. Microsoft XML, v 4.0 (if you have installed MSXML 4.0 separately).
3. Microsoft XML, v 5.0 (if you have installed Office 2003 – 2007 which provides MSXML 5.0 for Microsoft Office Applications).
4. Microsoft XML, v 6.0 for latest versions of MS Office.
*/

/*
   lCHECKVIACEP := MSGYESNO( "Usar viacep" )        https://viacep.com.br/ws/01001000/json/
   lCHECKREPVIR  := MSGYESNO( "Usar RepVirtual" )    http://cep.republicavirtual.com.br/web_cep.php?cep=" + xCep + "&formato=xml
   lCHECKAPICEP  := MSGYESNO( "Usar apicep" )       https://cdn.apicep.com/file/apicep/06233-030.json
   lCHECKAPIAWE  := MSGYESNO( "Usar apiAWE" )        https://cep.awesomeapi.com.br/json/" + cCEP
   lBrasilAberto := MSGYESNO( "Usar BrasilAberto" ) https://api.brasilaberto.com/v1/zipcode/01001000
   lopencep      := MSGYESNO( "Usar opencep" )      https://opencep.com/v1/15050305
   lBrasilAPI    := MSGYESNO( "Usar BrasilAPI" )   https://brasilapi.com.br/api/cep/v2/01001000

// https://cdn.apicep.com/file/apicep/06233-030.json
*/

#include "tshead.ch"
#include "try.ch"

REQUEST HB_CODEPAGE_PTISO
REQUEST DBFCDX


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function Main()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION Main()

   PRIVATE cCep, cBairro, cCidade, cEndereco, cUF, cID

   Set( _SET_CODEPAGE, "PTISO" )
   SetMode( 25, 80 )
   CLS   // necessario as vezes trava apos a mudanca para 25,80
   hb_idleState()
   rddSetDefault( "DBFCDX" )
   Set( _SET_OPTIMIZE, .T. )
   Set( _SET_DELETED, .T. )
   Set( _SET_SOFTSEEK, .T. )
   __SetCentury( .T. )
   Set( _SET_EPOCH, Year( Date() ) - 60 )
   Set( _SET_DATEFORMAT, "dd/mm/yyyy" )



   nERRO := 0

   IF !File( "cepruaimp.dbf" )
      Alert( "Falta cepruaimp.dbf" )
      QUIT
   ENDIF

   lRUAVAZIA    := MSGYESNO( "Checar Ruas Em Branco" )
   lBAIRROVAZIO := MSGYESNO( "Checar Bairro em Branco" )
   lNOMECURTO   := MSGYESNO( "Checar Ruas com nomes menores que 5 letras" )
   lAPAGANAO    := MSGYESNO( "Apaga Nao encontrado" )

   lCHECKVIACEP := MSGYESNO( "Usar viacep" )
   lCHECKREPVIR  := MSGYESNO( "Usar RepVirtual" )
   lCHECKAPICEP  := MSGYESNO( "Usar apicep" )
   lCHECKAPIAWE  := MSGYESNO( "Usar apiAWE" )
   lBrasilAberto := MSGYESNO( "Usar BrasilAberto" )
   lopencep      := MSGYESNO( "Usar opencep" )
   lBrasilAPI    := MSGYESNO( "Usar BrasilAPI" )

   lGERACEPTXT := MSGYESNO( "Gerar ceps.csv" )
   lGERACEPRUA := MSGYESNO( "Gerar cepruaimp.csv " )


   IF lGERACEPTXT
      nFILECEPS := FCreate( "ceps.csv" )
   ENDIF

   IF lGERACEPRUA
      nGRAVA := FCreate( "cepruaimp.csv" )
      cLINHA := "cep,ibge,rua,complemento,bairro,cidade,uf" + hb_osNewLine()
      FWrite( nGRAVA, cLINHA )
   ENDIF


   IF File( "cepruaimp.cdx" )  // apaga o indice caso algum importador use outra chave para o index primario
      FErase( "cepruaimp.cdx" )
   ENDIF

   USE cepruaimp NEW EXCLUSIVE

   dbRecall()  // retorna os que nao achou na busca anterior pois uf cidade estao em branco e o cepruaimp deleta para tratativas
// o web service tem limite diario de consultas assim nao busca novamente nao consumindo o web service
   INDEX ON CEP TAG cep


   OpenCepjason()



   mArquivo  := 'C*.dbf'
   mListaArq := Directory( mArquivo )
   nFIMARQ   := Len( mListaArq )
   FOR KK := 1 TO nFIMARQ  // LEN(mListaArq)
      cFILECEP := Lower( mListaArq[ KK, 1 ] )
      cFILECEP := StrTran( cFILECEP, ".dbf", "" )

      IF cFILECEP <> "cepbai" .AND. cFILECEP <> "ceprua" .AND. cFILECEP <> "cidconv" .AND. cFILECEP <> "cepruaimp" .AND. cFILECEP <> "cepgeo" .AND. cFILECEP <> "ce_f"
         dbUseArea( .T., "DBFCDX", cFILECEP,, .F. )
         ordListAdd( cFILECEP )
         @ 23, 00 SAY cFILECEP
         cFILTRO := ""
         cFILTRO += IF( lRUAVAZIA, " EMPTY(RUA) ", "" )
         cFILTRO += IF( lBAIRROVAZIO, IF( Empty( cFILTRO ), "", " .OR. " ) + " EMPTY(CHVBAI) ", "" )
         cFILTRO += IF( lNOMECURTO, IF( Empty( cFILTRO ), "", " .OR. " ) + " LEN(ALLTRIM(RUA))<=5 ", "" )
         SET FILTER TO &cFILTRO.   // EMPTY(RUA) .or. empty(field->chvbai)
         ntotrec := RecCount()
         NRECUSO := 0

         dbGoTop()
         WHILE !Eof()
            nRECUSO++
            @ 24, 00 SAY cFILECEP
            @ 24, 10 SAY nTOTREC
            @ 24, 20 SAY nRECUSO

            lTEMCEP := .T.   // marca true para nao apagar se consultra cep nao encontrar vira false
            cCEP    := field->cep



            dbSelectAr( "cepruaimp" )
            dbGoTop()
            IF !dbSeek( cCEP )   // Ja pesquisado

               cBairro      := ""
               cCidade      := ""
               cEndereco    := ""
               cUF          := ""
               cIBGE        := ""
               cComplemento := ""
               cTIPORUA     := ""
               cDDD         := ""
               cLATITUDE    := ""
               cLONGITUDE   := ""

               lTEMCEP := .F.


               IF lCHECKVIACEP   // via cep web segunda busca
                  ? '  CEPVIA:' + cCEP
                  ?
                  oCep := cepWeb( cCEP )
                  IF !oCep == NIL
                     cCIDADE      := oCep:cLocalidade
                     cENDERECO    := oCep:cLogradouro
                     cBAIRRO      := oCep:cBairro
                     cComplemento := oCep:cComplemento
                     cUF          := oCep:cUF
                     cIBGE        := oCep:cIBGE
                     GRAVARUAIMP()
                     lTEMCEP := .T.
                  ELSE
                     GRAVARUANAO( 'nao localizado viacep' )
                  ENDIF
               ENDIF

               IF lCHECKREPVIR
                  ? '  CEPREP:' + cCEP
                  ?
                  CepRepublica( cCEP )
                  IF !Empty( cEndereco + cBairro )
                     GRAVARUAIMP()
                     lTEMCEP := .T.
                  ELSE
                     GRAVARUANAO( 'nao localizado rep Virtual' )
                  ENDIF
               ENDIF

               IF lCHECKAPICEP
                  ? '  APICEP:' + cCEP
                  ?
                  CepAPICEP( cCEP )
                  IF !Empty( cEndereco + cBairro )
                     GRAVARUAIMP()
                     lTEMCEP := .T.
                  ELSE
                     GRAVARUANAO( 'nao localizado apicep' )
                  ENDIF
               ENDIF

               IF lCHECKAPIAWE
                  ? '  APIAWE:' + cCEP
                  ?
                  CepAPIAWE( cCEP )
                  IF !Empty( cEndereco + cBairro )
                     GRAVARUAIMP()
                     lTEMCEP := .T.
                  ELSE
                     GRAVARUANAO( 'nao localizado apiAWE' )
                  ENDIF
               ENDIF

               IF LBrasilAberto
                  ? '  BrasilAberto:' + cCEP
                  ?
                  CEPBrasilAberto( cCEP )
                  IF !Empty( cEndereco + cBairro )
                     GRAVARUAIMP()
                     lTEMCEP := .T.
                  ELSE
                     GRAVARUANAO( 'nao localizado BrasilAberto' )
                  ENDIF
               ENDIF

               IF Lopencep
                  ? '  opencep:' + cCEP
                  ?
                  CEPopencep( cCEP )
                  IF !Empty( cEndereco + cBairro )
                     GRAVARUAIMP()
                     lTEMCEP := .T.
                  ELSE
                     GRAVARUANAO( 'nao localizado opencep' )
                  ENDIF
               ENDIF

               IF LBrasilAPI
                  ? '  BrasilAPI:' + cCEP
                  ?
                  CEPBrasilAPI( cCEP )
                  IF !Empty( cEndereco + cBairro )
                     GRAVARUAIMP()
                     lTEMCEP := .T.
                  ELSE
                     GRAVARUANAO( 'nao localizado BrasilAPI' )
                  ENDIF
               ENDIF


               IF lGERACEPTXT .AND. lTEMCEP .AND. !Empty( cEndereco + cBairro )
                  FWrite( nFILECEPS, cCEP + hb_osNewLine() )
               ENDIF


               IF lGERACEPRUA .AND. lTEMCEP .AND. !Empty( cEndereco + cBairro )
                  cLINHA := cCEP + "," + cIBGE + "," + cENDERECO + "," + cComplemento + "," + cBairro + "," + cCIDADE + "," + Left( cUF, 2 ) + hb_osNewLine()
                  FWrite( nGRAVA, cLINHA )
               ENDIF


            ENDIF
            dbSelectAr( cFILECEP )
            IF lapaganao .AND. !lTEMCEP
               dbDelete()
            ENDIF
            dbSkip()
         ENDDO
         dbSelectAr( cFILECEP )
         dbCloseArea()
      ENDIF
   NEXT KK

   IF lGERACEPRUA
      FClose( nGRAVA )
   ENDIF

   IF lGERACEPTXT
      FClose( nFILECEPS )
   ENDIF

   dbSelectAr( "cepruaimp" )
   DELETE ALL FOR Empty( rua ) .AND. Empty( bairro )
   PACK
   dbCloseAll()


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function FormataCEP()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +

FUNCTION FormataCEP( eCEP )

   IF ValType( eCEP ) = "N"
      eCEP := StrZero( eCEP, 8 )
   ENDIF
   eCEP := AllTrim( eCEP )
   IF At( "-", eCEP ) = 0 .AND. Len( eCEP ) = 8
      eCEP := Left( eCEP, 5 ) + "-" + Right( eCEP, 3 )
   ENDIF

   RETURN eCEP


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function GRAVARUANAO()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION GRAVARUANAO( cMENSAGEM )

   ? cMENSAGEM
   ?
   dbSelectAr( "cepruaimp" )   // grava para nao buscr online novamente
   IF !dbSeek( cCEP )
      dbAppend()
      field->cep := cCEP
      IF !Empty( cCIDADE ) .AND. !Empty( cUF )
         field->cidade := cCIDADE
         field->uf     := cUF
      ENDIF
   ENDIF

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function GRAVARUAIMP()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION GRAVARUAIMP()

   IF cENDERECO = "ull,"   // alguns web service trazem null
      cENDERECO := ""
   ENDIF
   IF cBAIRRO = "ull,"   // alguns web service trazem null
      cBAIRRO := ""
   ENDIF
   dbSelectAr( "cepruaimp" )
   IF !dbSeek( cCEP )
      dbAppend()
      field->cep := cCEP
   ENDIF
   IF Empty( field->codibge ) .AND. !Empty( cIBGE )
      field->codibge := cIBGE
   ENDIF
   IF Empty( field->rua ) .AND. !Empty( cENDERECO )
      field->rua := cENDERECO
   ENDIF
   IF Empty( field->obs ) .AND. !Empty( cComplemento )
      field->obs := cComplemento
   ENDIF
   IF Empty( field->bairro ) .AND. !Empty( cBairro )
      field->bairro := cBairro
   ENDIF
   IF Empty( field->cidade ) .AND. !Empty( cCIDADE )
      field->cidade := cCIDADE
   ENDIF
   IF Empty( field->uf ) .AND. !Empty( cUF )
      field->uf := cUF
   ENDIF
   IF Empty( field->tipo ) .AND. !Empty( cTIPORUA )
      field->tipo := cTIPORUA
   ENDIF

   IF Empty( field->DDD ) .AND. !Empty( cDDD )
      field->DDD := cDDD
   ENDIF
   IF Empty( field->LATITUDE ) .AND. !Empty( cLATITUDE )
      field->LATITUDE := cLATITUDE
   ENDIF
   IF Empty( field->LONGITUDE ) .AND. !Empty( cLONGITUDE )
      field->LONGITUDE := cLONGITUDE
   ENDIF

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Procedure CepRepublica()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
PROCEDURE CepRepublica( xCep )

   LOCAL oHttp, cXML
   LOCAL xRes, xResTxt, xUf, xCidade, xTipo, xEnde, xBairro, xRetorno := {}

   xCep  := StrTran( xCep, "-" )
   oHttp := TIpClientHttp():new( "http://cep.republicavirtual.com.br/web_cep.php?cep=" + xCep + "&formato=xml" )
   IF !oHttp:open()
      RETURN .F.
   ENDIF
   Inkey( .5 )

   cXML := oHttp:readAll()
   oHttp:close()

   cXML := XmlTransform( cXML )

   IF Empty( cXML )
      RETURN .F.
   ENDIF
   cBairro   := XmlNode( cXml, "bairro" )
   cCidade   := XmlNode( cXml, "cidade" )
   cEndereco := XmlNode( cXml, "logradouro" )
   cUF       := XmlNode( cXml, "uf" )
   cTIPORUA  := XmlNode( cXml, "tipo_logradouro" )

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function AppVersaoExe()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION AppVersaoExe()

   RETURN ""

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function AppUserName()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION AppUserName()

   RETURN ""



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function CEPapicEp()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION CEPapicEp( cCEP )

   TRY
    // https://cdn.apicep.com/file/apicep/06233-030.json //api necessita traco usado formatacep abaico
       cURL := "https://cdn.apicep.com/file/apicep/" + formatacep( cCEP ) + ".json"
       oPg  := CreateObject( "Msxml2.XMLHTTP.6.0" )  // oPg  := CreateObject("Msxml2.XMLHTTP.3.0") atualizado para versao 6
       oPg:Open( "GET", cUrl, .F. )
       oPg:Send()
       cXMl := oPg:ResponseBody
    // {"code":"06233-030","state":"SP","city":"Osasco","district":"Piratininga","address":"Rua Paula Rodrigues","status":200,"ok":true,"statusText":"ok"}
       cXMl := XmlTransform( cXMl )


       CUF       := pegnodojason( cXMl, 'state":' )
       cCIDADE   := pegnodojason( cXMl, 'city":' )
       cBairro   := pegnodojason( cXMl, 'district":' )
       cENDERECO := pegnodojason( cXMl, 'address":' )
     catch oEr  
      // mdt("Erro de conexão na API send")
     end
   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function cepapiawe()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION cepapiawe( cCEP )

// https://cep.awesomeapi.com.br/json/05424020
// https://cep.awesomeapi.com.br/xml/05424020
// https://cep.awesomeapi.com.br/05424020

   TRY
         cURL := "https://cep.awesomeapi.com.br/json/" + cCEP
         oPg  := CreateObject( "Msxml2.XMLHTTP.6.0" )  // oPg  := CreateObject("Msxml2.XMLHTTP.3.0") atualizado para versao 6
         oPg:Open( "GET", cUrl, .F. )
         oPg:Send()
         cXMl := oPg:ResponseBody
    catch oEr  
      // mdt("Erro de conexão na API send")
       RETURN .F.
     end
     
     
     cXMl := XmlTransform( cXMl )
        IF At( "not_found", cXML ) > 0 .OR. At( "nao foi encontrado", cXML ) > 0
            RETURN .F.
         ENDIF

      // {"cep":"05424020","address_type":"Rua","address_name":"Professor Carlos Reis","address":"Rua Professor Carlos Reis","state":"SP",
      // "district":"Pinheiros","lat":"-23.57021","lng":"-46.69685","city":"São Paulo","city_ibge":"3550308","ddd":"11"}
      // disponiveis ddd latitude longitude
      // 123456789012345


         CUF        := pegnodojason( cXML, 'state":' )
         cCIDADE    := pegnodojason( cXML, 'city":' )
         cBairro    := pegnodojason( cXML, 'district":' )
         cENDERECO  := pegnodojason( cXML, 'address_name":' )
         cTIPORUA   := pegnodojason( cXML, 'address_type":' )
         cIBGE      := pegnodojason( cXML, 'city_ibge":' )
         cDDD       := pegnodojason( cXML, 'ddd":' )
         cLATITUDE  := pegnodojason( cXML, 'lat":' )
         cLONGITUDE := pegnodojason( cXML, 'lng":' )


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
FUNCTION pegnodojason( cTEXTO, cNODO )

   cTEXTO := SubStr( cTEXTO, At( cNODO, cTEXTO ) + Len( cNODO ) + 1 )
   CTEXTO := SubStr( cTEXTO, 1, At( '"', cTEXTO ) - 1 )
// ALERT(cTEXTO)

   RETURN cTEXTO


/*******************************************************************************
 *
 *  The engine of this is the contrib 'hbtip'
 *
 *  It uses the free service: ViaCEP (http://viacep.com.br)
 *
 */

// +--------------------------------------------------------------------
// +
// +
// +
// +    Function cepWeb()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION cepWeb( cCEP )

   LOCAL oCEP := ViaCEP():New( cCEP )

   RETURN oCEP


/*
 *  ViaCEP Class
 */

#include 'hbclass.ch'


// +--------------------------------------------------------------------
// +
// +
// +
// +    Create Class ViaCEP()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
CREATE CLASS ViaCEP

   VAR oCep
   VAR cCep INIT ''
   VAR cIBGE INIT ''
   VAR cLogradouro INIT ''
   VAR cComplemento INIT ''
   VAR cBairro INIT ''
   VAR cLocalidade INIT ''
   VAR cUF INIT ''
   VAR cDDD INIT ''
   METHOD New( cCEP )

ENDCLASS


METHOD New( cCEP )

   IF nERRO > 10
      ? 'Open erro >10'
      ?
      RETURN NIL
   ENDIF

   oHttp := TIPClientHTTP():new( "http://viacep.com.br/ws/" + cCEP + "/piped/" )

   IF !oHttp:open()
      ? 'open erro'
      ?
      nERRO++
      RETURN NIL
   ENDIF

   cHtml := oHttp:readAll()
   oHttp:close()

   IF Empty( cHtml )
      RETURN NIL
   ENDIF
   cHtml := XmlTransform( cHtml )
   aHtml := hb_ATokens( cHtml, '|' )

   IF Len( aHtml ) < 7
      RETURN NIL
   ENDIF

// cep:01001-000|logradouro:Praça da Sé|complemento:lado ímpar|bairro:Sé|localidade:São Paulo|uf:SP|ibge:3550308|gia:1004|ddd:11|siafi:7107

   cCEP         := SubStr( aHtml[ 1 ], At( ':', aHtml[ 1 ] ) + 1 )
   cLogradouro  := SubStr( aHtml[ 2 ], At( ':', aHtml[ 2 ] ) + 1 )
   cComplemento := SubStr( aHtml[ 3 ], At( ':', aHtml[ 3 ] ) + 1 )
   cBairro      := SubStr( aHtml[ 4 ], At( ':', aHtml[ 4 ] ) + 1 )
   cLocalidade  := SubStr( aHtml[ 5 ], At( ':', aHtml[ 5 ] ) + 1 )
   cUF          := SubStr( aHtml[ 6 ], At( ':', aHtml[ 6 ] ) + 1 )
   cIBGE        := SubStr( aHtml[ 7 ], At( ':', aHtml[ 7 ] ) + 1 )
   cDDD         := SubStr( aHtml[ 9 ], At( ':', aHtml[ 9 ] ) + 1 )

   ::cCEP         := cCEP
   ::cLogradouro  := cLogradouro
   ::cComplemento := cComplemento
   ::cBairro      := cBairro
   ::cLocalidade  := cLocalidade
   ::cUF          := cUF
   ::cIBGE        := cIBGE
   ::cDDD         := cDDD

   RETURN Self


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function CEPBrasilAberto()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION CEPBrasilAberto( cCEP )

/*
// https://api.brasilaberto.com/v1/zipcode/01001000

{
  "meta": {
    "currentPage": 1,
    "itemsPerPage": 1,
    "totalOfItems": 1,
    "totalOfPages": 1
  },
  "result": {
    "street": "Praça da Sé",
    "complement": "lado ímpar",
    "district": "Sé",
    "districtId": 1,
    "city": "São Paulo",
    "cityId": 1,
    "ibgeId": 3550308,
    "state": "São Paulo",
    "stateShortname": "SP",
    "zipcode": "01001000"
  }
}
*/

TRY
   cURL := "https://api.brasilaberto.com/v1/zipcode/" + cCEP
   oPg  := CreateObject( "Msxml2.XMLHTTP.6.0" )
   oPg:Open( "GET", cUrl, .F. )
   oPg:Send()
   cXMl := oPg:ResponseBody


  catch oEr  
      // mdt("Erro de conexão na API send")
       return .f.
     end
     
    
   cXMl := XmlTransform( cXMl )

   IF At( 'error', cXML ) > 0
      RETURN
   ENDIF


   CUF          := pegnodojason( cXMl, 'stateShortname":' )
   cCIDADE      := pegnodojason( cXMl, 'city":' )
   cBairro      := pegnodojason( cXMl, 'district":' )
   cENDERECO    := pegnodojason( cXMl, 'street":' )
   cIBGE        := pegnodojason( cXMl, 'ibgeId":' )
   cComplemento := pegnodojason( cXMl, 'complement":' ) 
     
   RETURN .T.




// +--------------------------------------------------------------------
// +
// +
// +
// +    Function CEPOpenCep()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION CEPOpenCep( cCEP )

/*
// https://opencep.com/v1/15050305

{
  "cep": "15050-305",
  "logradouro": "Rua Josina Teixeira de Carvalho",
  "complemento": "",
  "bairro": "Vila Anchieta",
  "localidade": "São José do Rio Preto",
  "uf": "SP",
  "ibge": "3549805"
}
*/
 TRY
   cURL := "https://opencep.com/v1/" + cCEP
   oPg  := CreateObject( "Msxml2.XMLHTTP.6.0" )
   oPg:Open( "GET", cUrl, .F. )
   oPg:Send()
   cXMl := oPg:ResponseBody



  catch oEr  
      // mdt("Erro de conexão na API send")
       RETURN .F.
    end
    
      cXMl := XmlTransform( cXMl )

   IF At( 'error', cXML ) > 0
      RETURN .F.
   ENDIF

// altd()
// aqui e necesssario espaco depois dos dois ponto `: `
   CUF          := pegnodojason( cXMl, '"uf": ' )
   cCIDADE      := pegnodojason( cXMl, '"localidade": ' )
   cBairro      := pegnodojason( cXMl, 'bairro": ' )
   cENDERECO    := pegnodojason( cXMl, '"logradouro": ' )
   cIBGE        := pegnodojason( cXMl, '"ibge": ' )
   cComplemento := pegnodojason( cXMl, '"complemento": ' )
 
    
   RETURN .T.



// +--------------------------------------------------------------------
// +
// +
// +
// +    Function CEPBrasilApi()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION CEPBrasilApi( cCEP )

/*
// https://brasilapi.com.br/api/cep/v2/01001000

{
  "cep": "01001000",
  "state": "SP",
  "city": "São Paulo",
  "neighborhood": "Sé",
  "street": "Praça da Sé - lado ímpar",
  "service": "correios-alt",
  "location": {
    "type": "Point",
    "coordinates": {

    }
  }
}
*/

try
   cURL := "https://brasilapi.com.br/api/cep/v2/" + cCEP
   oPg  := CreateObject( "Msxml2.XMLHTTP.6.0" )
   oPg:Open( "GET", cUrl, .F. )
   oPg:Send()
   cXMl := oPg:ResponseBody


  catch oEr  
       //mdt("Erro de conexão na API send")
       return .f.
     end
     
     cXMl := XmlTransform( cXMl )

   IF At( 'error', cXML ) > 0
      RETURN
   ENDIF

   CUF       := pegnodojason( cXMl, 'state":' )
   cCIDADE   := pegnodojason( cXMl, '"city":' )
   cBairro   := pegnodojason( cXMl, 'neighborhood":' )
   cENDERECO := pegnodojason( cXMl, 'street":' )


   IF At( 'latitude":', cXML ) > 0 .AND. At( 'longitude":', cXML ) > 0
      cLATITUDE  := pegnodojason( cXMl, 'latitude":' )
      cLONGITUDE := pegnodojason( cXMl, 'longitude":' )
   ENDIF
   

   RETURN .T.


// +--------------------------------------------------------------------
// +
// +
// +
// +    Function OpenCepjason()
// +
// +
// +
// +--------------------------------------------------------------------
// +
// +
// +
FUNCTION OpenCepjason()

/*
// https://opencep.com/v1/15050305

{
  "cep": "15050-305",
  "logradouro": "Rua Josina Teixeira de Carvalho",
  "complemento": "",
  "bairro": "Vila Anchieta",
  "localidade": "São José do Rio Preto",
  "uf": "SP",
  "ibge": "3549805"
}
*/

   LOCAL kk

   kk := 1

   mArquivo  := '*.json'
   mListaArq := Directory( mArquivo, "D" )
   nFIMARQ   := Len( mListaArq )

   FOR kk := 1 TO nFIMARQ
      cFILECEP := Lower( mListaArq[ kk, 1 ] )
      cXMl     := MemoRead( cFILECEP )
      cXMl     := XmlTransform( cXMl )

      ? '  opencep:' + cFILECEP
      ?

      cBairro      := ""
      cCidade      := ""
      cEndereco    := ""
      cUF          := ""
      cIBGE        := ""
      cComplemento := ""
      cTIPORUA     := ""
      cDDD         := ""
      cLATITUDE    := ""
      cLONGITUDE   := ""


      // aqui e necesssario espaco depois dos dois ponto `: `
      cCEP         := tirAOUT( pegnodojason( cXMl, '"cep": ' ) )
      CUF          := pegnodojason( cXMl, '"uf": ' )
      cCIDADE      := pegnodojason( cXMl, '"localidade": ' )
      cBairro      := pegnodojason( cXMl, 'bairro": ' )
      cENDERECO    := pegnodojason( cXMl, '"logradouro": ' )
      cIBGE        := pegnodojason( cXMl, '"ibge": ' )
      cComplemento := pegnodojason( cXMl, '"complemento": ' )

      // alert(Cuf)
      // alert(Ccidade)
      // alert(Cendereco)

      GRAVARUAIMP()

      FErase( cFILECEP )
   NEXT kk

   RETURN .T.


/*
FUNCTION GetDadosJson( cJson )
   LOCAL hData := {=>}
   hb_jsonDecode( cJson, @hData )
   
   // Acesso direto e seguro
   cCIDADE   := hb_HGetDef( hData, "city", "" )
   cUF       := hb_HGetDef( hData, "state", "" )
   cENDERECO := hb_HGetDef( hData, "street", "" )
RETURN hData
*/



// + EOF: cepwebvia.prg
// +
