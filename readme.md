# Rotinas de CEP

Rotinas em [Harbour](https://harbour.github.io/) para importar, atualizar,
validar e consultar cadastros brasileiros de CEP, municípios, bairros e
logradouros. Os dados principais são armazenados em arquivos DBF com índices
CDX.

## Funcionalidades

- Atualização do cadastro de municípios a partir de fontes externas.
- Importação e normalização de dados de CEP e logradouros.
- Associação de municípios a códigos IBGE, UF e DDD.
- Consulta de CEP por serviços web, com suporte a:
  - ViaCEP;
  - República Virtual;
  - API CEP;
  - AwesomeAPI;
  - Brasil Aberto;
  - OpenCEP;
  - BrasilAPI.
- Geração de arquivos CSV para exportação e integração com outros sistemas.
- Registro de inconsistências em `cepruaerr.dbf` e `erro.txt`.

## Programas

| Programa | Descrição | Arquivo de projeto |
| --- | --- | --- |
| `convcep` | Atualiza municípios, dados telefônicos e faixas de CEP. | `convcep.hbp` |
| `cepruaimp` | Importa e normaliza logradouros, bairros, municípios e CEPs. | `cepruaimp.hbp` |
| `cepwebvia` | Consulta CEPs em serviços web e completa os dados locais. | `cepwebvia.hbp` |

Os fontes correspondentes são `convcep.prg`, `cepruaimp.prg` e
`cepwebvia.prg`.

## Requisitos

- Windows, para os scripts `.bat` fornecidos.
- Harbour com `hbmk2`.
- GCC/MinGW compatível com a instalação do Harbour.
- Bibliotecas Harbour usadas pelos projetos, incluindo `DBFCDX`, `xhb`,
  `gtwvg`, `hbct` e `hbtip`.
- Arquivos DBF e CDX de apoio exigidos por cada rotina.
- Acesso à internet para as consultas aos serviços de CEP.

Os arquivos `.hbp` atualmente referenciam bibliotecas e fontes auxiliares
locais, como `cepsutil.prg`, `comp.prg`, `netdbf.prg` e `ze_xmlfunc.prg`.
Antes de compilar, ajuste esses caminhos para a estrutura da sua instalação.

## Compilação

Com o ambiente Harbour configurado, execute na raiz do projeto:

```bat
hbmk2 convcep.hbp
hbmk2 cepruaimp.hbp
hbmk2 cepwebvia.hbp
```

Também existem scripts prontos para ambientes de 32 e 64 bits:

```bat
convcep64.bat
convcep32.bat
cepruaimp64.bat
cepwebvia64.bat
```

Os scripts pressupõem instalações em caminhos específicos, como
`d:\devprg\hb` e `c:\devprg\hb64`. Edite os scripts se o Harbour estiver
instalado em outro diretório.

## Fluxo recomendado

1. Disponibilize os arquivos de origem e as tabelas DBF auxiliares na pasta de
   execução.
2. Execute `convcep` para atualizar `md10imp.dbf` e preparar os dados de
   municípios.
3. Execute `cepruaimp` para importar e normalizar os logradouros.
4. Execute `cepwebvia` para consultar os CEPs pendentes e, opcionalmente,
   gerar `ceps.csv` e `cepruaimp.csv`.
5. Revise `cepruaerr.dbf` e `erro.txt` antes de publicar os dados.

Os programas são interativos e exibem perguntas para selecionar fontes,
filtros, consultas e exportações.

## Arquivos de dados

As tabelas mais importantes são:

| Arquivo | Finalidade |
| --- | --- |
| `md10imp.dbf` | Municípios, UF, DDD, IBGE e faixas de CEP. |
| `cepruaimp.dbf` | Logradouros importados e normalizados. |
| `cepruaerr.dbf` | Registros que não puderam ser processados. |
| `ceprua.dbf` | Cadastro consolidado de ruas e CEPs. |
| `cepgeo.dbf` | Coordenadas e DDD associados ao CEP. |
| `ce_f.dbf` | Dados telefônicos importados da Anatel. |
| `ceprua.cdx`, `cepgeo.cdx` e outros `.cdx` | Índices DBF necessários às buscas. |

O dicionário completo das estruturas está em
[`documentacao_dados.md`](documentacao_dados.md).

## Fontes de entrada e saída

Dependendo do fluxo escolhido, os programas podem ler arquivos como
`municipios.dbf`, `pgcn.dbf`, `ce_f.txt` e `logradouro.dbf`. As exportações
geradas incluem:

- `MD10IMP.TXT`;
- `ceps.csv`;
- `cepruaimp.csv`;
- `erro.txt`.

Não remova ou sobrescreva os DBFs originais sem manter uma cópia de segurança.
Algumas etapas usam `ZAP` e reindexação para reconstruir tabelas durante a
importação.

## Documentação adicional

- [`documentacao.md`](documentacao.md): módulos, funções e acessos às tabelas.
- [`documentacao_dados.md`](documentacao_dados.md): dicionário das tabelas DBF.
- [`git_util_api.md`](git_util_api.md): anotações sobre a API de integração.
- [`git_util_repos.md`](git_util_repos.md): anotações sobre repositórios.

## Observações

- O código utiliza a página de código `PTISO` e o idioma `PT`; valide a
  configuração regional do ambiente antes de processar caracteres acentuados.
- Os serviços web podem impor limites de consulta ou ficar indisponíveis.
  Selecione mais de uma fonte somente quando isso fizer sentido para a carga.
- As consultas já realizadas são mantidas em `cepruaimp.dbf` para evitar
  chamadas repetidas aos serviços.
- Os arquivos `.dbf`, `.cdx` e `.zip` versionados no repositório podem ser
  grandes; trate-os como dados de entrada e não como código-fonte.


