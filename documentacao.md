# 📘 Documentacao Tecnica do Projeto
> Gerado em: 06/05/26 17:17:13

## 🏗️ Estrutura de Modulos (PRGs)

### 📄 Arquivo: `cepruaimp.prg`
- Function Main()
- Function tratacidade()
- Function vertxt()

### 📄 Arquivo: `cepwebvia.prg`
- Function Main()
- Function FormataCEP()
- Function GRAVARUANAO()
- Function GRAVARUAIMP()
- Procedure CepRepublica()
- Function AppVersaoExe()
- Function AppUserName()
- Function CEPapicEp()
- Function cepapiawe()
- Function pegnodojason()
- Function cepWeb()
- Create Class ViaCEP()
- Function CEPBrasilAberto()
- Function CEPOpenCep()
- Function CEPBrasilApi()
- Function OpenCepjason()

### 📄 Arquivo: `convcep.prg`
- Function Main()
- Function JasonCountry()
- Function pegnodojason()
- Function help()
- Function cidconvinc()

## 📊 Dicionario de Dados e Acessos

**Fonte:** `cepruaimp.prg`
> Tables: USE cepruaerr NEW EXCLUSIVE
> USE cepruaimp NEW EXCLUSIVE
> dbUseArea(.T.,"DBFCDX",cARQUIVO,,.T.)
> dbUseArea(.T.,"DBFCDX",cARQRUA,,.T.)
> dbUseArea(.T.,"DBFCDX",cARQGEO,,.T.)
> Indexes: INDEX ON UF+CIDADE+CEP TAG ufcidade
> INDEX ON RUA TAG &cARQRUA.1
> INDEX ON CEP TAG &cARQRUA.2
> INDEX ON CEP TAG &cARQGEO.1

**Fonte:** `cepwebvia.prg`
> Tables: USE cepruaimp NEW EXCLUSIVE
> dbUseArea(.T.,"DBFCDX",cFILECEP,,.F.)
> Indexes: INDEX ON CEP TAG cep

**Fonte:** `convcep.prg`
> Tables: USE md10imp NEW EXCLUSIVE
> USE ce_f NEW EXCLUSIVE
> USE md10imp NEW SHARED
> Indexes: INDEX ON RUA TAG &cFILECEP.1 EVAL ZEI_FORT(nLASTREC,,,1)
> INDEX ON CEP TAG &cFILECEP.2 EVAL ZEI_FORT(nLASTREC,,,1)
> INDEX ON RUA TAG &cARQRUA.1 EVAL ZEI_FORT(nLASTREC,,,1)
> INDEX ON CEP TAG &cARQRUA.2 EVAL ZEI_FORT(nLASTREC,,,1)

## 🕸️ Diagrama de Relacionamento (Mermaid)
```mermaid
graph TD
    convcep_prg --> flinecount()    <unresolved function>
    convcep_prg --> hb_langselect() in harbour.lib
    convcep_prg --> jasoncountry()  in convcep.prg
    convcep_prg --> mdg()           <unresolved function>
    convcep_prg --> mvinfoconftela( <unresolved function>
    convcep_prg --> netgrvcam()     <unresolved function>
    convcep_prg --> netgrvz()       <unresolved function>
    convcep_prg --> netpack()       <unresolved function>
    convcep_prg --> netrecapp()     <unresolved function>
    convcep_prg --> netrecdel()     <unresolved function>
    convcep_prg --> netreclock()    in xhb.lib
    convcep_prg --> netregosok()    <unresolved function>
    convcep_prg --> netuse()        <unresolved function>
    convcep_prg --> pegcidconv()    <unresolved function>
    convcep_prg --> zei_fort()      <unresolved function>
```
