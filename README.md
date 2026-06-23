# MOTIVA

<p align="center">
  <img src="flutter_app/assets/images/app_icon.png" alt="Ícone do aplicativo MOTIVA" width="160" />
</p>

<p align="center">
  <strong>Um aplicativo para atletas, coaches e boxes acompanharem treinos, evolução e engajamento no CrossFit.</strong>
</p>

<p align="center">
  <a href="#sobre-o-projeto">Sobre</a> •
  <a href="#principais-funcionalidades">Funcionalidades</a> •
  <a href="#acesso-antecipado">Acesso antecipado</a> •
  <a href="#tecnologias">Tecnologias</a> •
  <a href="#contexto-acadêmico">TCC</a>
</p>

---

## Sobre o projeto

O **MOTIVA** é um aplicativo mobile desenvolvido para apoiar a rotina de atletas
e coaches de CrossFit. A proposta é centralizar em uma única experiência o
registro de treinos, o acompanhamento da evolução, a comunicação com o box e a
geração de insights personalizados com apoio de inteligência artificial.

O projeto nasce da observação de um problema comum na prática esportiva:
informações importantes sobre desempenho, presença, fadiga, evolução e
planejamento costumam ficar espalhadas entre aplicativos, planilhas, mensagens e
percepções individuais. O MOTIVA busca transformar esses dados em uma experiência
mais clara, organizada e útil para quem treina e para quem orienta.

## Para quem é

- **Atletas** que querem acompanhar sua evolução, registrar resultados e receber
  orientações mais contextualizadas.
- **Coaches** que precisam entender melhor a turma, planejar treinos e acompanhar
  sinais de esforço, frequência e desempenho.
- **Boxes de CrossFit** que desejam melhorar organização, engajamento e
  relacionamento com seus praticantes.

## Principais funcionalidades

### Para atletas

- Registro de resultados de treinos e WODs.
- Acompanhamento de evolução individual.
- Visualização de histórico, frequência e desempenho.
- Insights semanais personalizados com IA.
- Insights de evolução com base no histórico do atleta.
- Insights pré-treino para ajudar o atleta a chegar mais preparado ao WOD.
- Notificações internas para alertas e novas análises.

### Para coaches

- Cadastro e publicação de treinos.
- Importação de treinos a partir de PDF.
- Organização de treinos em rascunho e publicados.
- Acompanhamento de resultados dos atletas.
- Apoio à análise da turma com dados de esforço, presença e desempenho.
- Recursos de IA para apoiar decisões de planejamento e leitura do contexto da
  turma.

### Para análise e validação do produto

- Scripts de análise de UX a partir de respostas reais de formulário.
- Gráficos em PNG e PDF para uso no TCC.
- Heatmaps, perfis de respondentes e análises por gênero, idade, tempo de
  prática, atletas e coaches.

## Acesso antecipado

O MOTIVA está em fase de desenvolvimento, validação acadêmica e testes com
usuários reais.

Para solicitar acesso antecipado ao aplicativo ou participar dos testes, entre
em contato:

> **E-mail:** `leonardosaracino@id.uff.br`

## Status do projeto

> Em desenvolvimento e validação.

O aplicativo já possui fluxos implementados para autenticação, perfis de usuário,
treinos, resultados, notificações e módulos de inteligência artificial. Algumas
funcionalidades ainda podem estar em fase de teste, ajuste visual ou validação
com usuários.

## Tecnologias

O MOTIVA combina desenvolvimento mobile, backend serverless, banco em nuvem e
análises de dados.

| Área                    | Tecnologias                                   |
| ----------------------- | --------------------------------------------- |
| Aplicativo mobile       | Flutter, Dart                                 |
| Backend                 | Firebase, Cloud Functions                     |
| Banco de dados          | Cloud Firestore                               |
| Autenticação            | Firebase Authentication, Google Sign-In       |
| Notificações            | Firebase Cloud Messaging                      |
| Inteligência Artificial | Gemini, módulos próprios de contexto e prompt |
| Análise de dados        | Python, Pandas, Matplotlib, Seaborn           |
| Distribuição de testes  | Firebase App Distribution, TestFlight         |

## Estrutura do repositório

```text
.
├── flutter_app/
│   ├── lib/                         # Aplicativo Flutter
│   ├── functions/                   # Cloud Functions e módulos de IA
│   └── assets/                      # Imagens, ícones e fontes do app
├── scripts_gerais/
│   ├── respostas_formulario.csv      # Base de respostas usada nas análises
│   ├── ux_tests/                    # Scripts e gráficos originais
│   └── ux_tests_refatoracao/         # Versão isolada/refatorada dos gráficos
├── docs/                            # Documentações auxiliares
└── README.md
```

## Análises de UX e TCC

Além do aplicativo, o repositório contém scripts usados para analisar respostas
de usuários e gerar gráficos para o Trabalho de Conclusão de Curso.

A versão refatorada dos gráficos fica em:

```text
scripts_gerais/ux_tests_refatoracao/
```

Ela gera:

- gráficos em **PNG** com 300 dpi;
- gráficos em **PDF** para uso em LaTeX ou documentos acadêmicos;
- CSVs derivados para conferência dos dados;
- heatmaps e análises por perfil de usuário.

Comando principal:

```bash
python scripts_gerais/ux_tests_refatoracao/gerar_todos_graficos.py
```

## Contexto acadêmico

Este projeto foi desenvolvido como parte de um **Trabalho de Conclusão de
Curso**, com foco em produto digital, experiência do usuário, análise de dados e
aplicação de inteligência artificial no contexto do CrossFit.

O objetivo acadêmico é investigar como uma solução mobile pode apoiar atletas,
coaches e boxes na organização da rotina esportiva, no acompanhamento da
evolução e na melhoria do engajamento.

## Desenvolvimento local

Esta seção é voltada para pessoas que precisam executar o projeto localmente.
Para usuários interessados em testar o produto, veja a seção
[Acesso antecipado](#acesso-antecipado).

### Aplicativo Flutter

```bash
cd flutter_app
flutter pub get
flutter run
```

### Cloud Functions

```bash
cd flutter_app/functions
```

Configure o ambiente Python e as credenciais necessárias antes de executar ou
fazer deploy das funções.

### Testes dos gráficos de UX

```bash
python -m pytest -q scripts_gerais/ux_tests_refatoracao/tests
```

## Privacidade e dados sensíveis

Este projeto utiliza dados de formulário e integrações com Firebase. Antes de
publicar o repositório ou compartilhar o código, confira se não há chaves,
credenciais, dados pessoais ou arquivos sensíveis versionados.

Recomendações:

- não publicar arquivos de service account;
- não expor chaves privadas;
- anonimizar dados pessoais usados em análises;
- manter variáveis sensíveis em ambientes seguros.

## Roadmap

- Ampliar os testes com usuários reais.
- Refinar a experiência visual do aplicativo.
- Evoluir os módulos de IA para atletas e coaches.
- Melhorar os painéis de evolução e métricas.
- Consolidar feedbacks obtidos nos testes de usabilidade.
- Preparar uma versão mais estável para distribuição controlada.

## Autor

Desenvolvido por **Leonardo Saracino** como parte do projeto MOTIVA.

> Adicione aqui curso, instituição, orientador e ano, se desejar.

---

<p align="center">
  MOTIVA — tecnologia, dados e inteligência para uma rotina de treino mais clara.
</p>
