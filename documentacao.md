# 📘 Documentacao Tecnica do Projeto
> Gerado em: 23/10/2026 10:51:08

## 🏗️ Estrutura de Modulos (PRGs)

### 📄 Arquivo: `cepruaimp`
- Function Main()
- Function tratacidade()
- Function vertxt()

### 📄 Arquivo: `cepwebvia`
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
- Method New()
- Function CEPBrasilAberto()
- Function CEPOpenCep()
- Function CEPBrasilApi()
- Function OpenCepjason()
- Function RequisicaoHTTP()

### 📄 Arquivo: `convcep`
- Function Main()
- Function JasonCountry()
- Function pegnodojason()
- Function help()
- Function cidconvinc()

## 📊 Dicionario de Dados e Acessos

## 🕸️ Diagrama de Relacionamento (Mermaid)
```mermaid
graph TD
    cepweb --> _new[":new          <externa>"]
    main --> buscaibge["buscaibge     <externa>"]
    main --> cepapiawe["cepapiawe     in cepwebvia.prg"]
    main --> cepapicep["cepapicep     in cepwebvia.prg"]
    main --> cepapicep["cepapicep     in cepwebvia.prg"]
    main --> cepbrasilapi["cepbrasilapi  in cepwebvia.prg"]
    main --> cepopencep["cepopencep    in cepwebvia.prg"]
    main --> ceprepublica["ceprepublica  in cepwebvia.prg"]
    main --> cepweb["cepweb        in cepwebvia.prg"]
    main --> coduf["coduf         <externa>"]
    requisicaohttp --> createobject["createobject  <externa>"]
    main --> filecopy["filecopy      <externa>"]
    main --> flinecount["flinecount    <externa>"]
    cepapicep --> formatacep["formatacep    in cepwebvia.prg"]
    main --> gravaruaimp["gravaruaimp   in cepwebvia.prg"]
    main --> gravaruanao["gravaruanao   in cepwebvia.prg"]
    new --> hb_atokens["hb_atokens    in harbour.lib"]
    requisicaohttp --> hb_idlesleep["hb_idlesleep  in harbour.lib"]
    main --> hb_idlestate["hb_idlestate  in harbour.lib"]
    main --> hb_langselect["hb_langselect in harbour.lib"]
    main --> jasoncountry["jasoncountry  in convcep.prg"]
    main --> mdg["mdg           <externa>"]
    main --> msgyesno["msgyesno      <externa>"]
    main --> mvinfoconftela["mvinfoconftela <externa>"]
    main --> netgrvcam["netgrvcam     <externa>"]
    jasoncountry --> netgrvz["netgrvz       <externa>"]
    main --> netpack["netpack       <externa>"]
    cidconvinc --> netrecapp["netrecapp     <externa>"]
    main --> netrecdel["netrecdel     <externa>"]
    jasoncountry --> netreclock["netreclock    in xhb.lib"]
    main --> netregosok["netregosok    <externa>"]
    jasoncountry --> netuse["netuse        <externa>"]
    cepweb --> new["new           in cepwebvia.prg"]
    requisicaohttp --> ohttp_close["ohttp:close   <externa>"]
    requisicaohttp --> ohttp_open["ohttp:open    <externa>"]
    requisicaohttp --> ohttp_readall["ohttp:readall <externa>"]
    main --> opencepjason["opencepjason  in cepwebvia.prg"]
    requisicaohttp --> opg_open["opg:open      <externa>"]
    requisicaohttp --> opg_send["opg:send      <externa>"]
    main --> pegcidconv["pegcidconv    <externa>"]
    cepapiawe --> pegnodojason["pegnodojason  in convcep.prg"]
    cepapiawe --> requisicaohttp["requisicaohttp in cepwebvia.prg"]
    requisicaohttp --> tipclienthttp["tipclienthttp in hbtip.lib"]
    main --> tiraout["tiraout       <externa>"]
    main --> tratacidade["tratacidade   in cepruaimp.prg"]
    main --> tratanome["tratanome     <externa>"]
    cepweb --> viacep["viacep        <externa>"]
    ceprepublica --> xmlnode["xmlnode       in sefazclass.lib"]
    cepapiawe --> xmltransform["xmltransform  in sefazclass.lib"]
    main --> zei_fort["zei_fort      <externa>"]
    main --> __setcentury["__setcentury  <externa>"]
```
