# Requisitos do Projeto MOTIVA

## Visao geral

O MOTIVA e um aplicativo voltado para praticantes e coaches de CrossFit. A proposta do projeto e ajudar o atleta a acompanhar treinos, registrar resultados, visualizar sua evolucao e receber orientacoes personalizadas. Para o coach, o app apoia o cadastro e a publicacao de treinos, a leitura dos resultados dos alunos e a analise dos ciclos de treino.

O sistema trabalha com dois perfis principais:

- **Atleta:** usuario que acompanha treinos, registra resultados, acompanha progresso, PRs e insights.
- **Coach:** usuario que cadastra, importa, edita e publica treinos, alem de acompanhar dados do ciclo.

Tambem existem perfis hibridos, como atleta/coach e atleta/estagiario, que podem alternar entre visoes conforme a permissao da conta.

## Requisitos funcionais

### Conta e acesso

| Codigo | Requisito |
|---|---|
| RF01 | O app deve permitir cadastro de usuario com nome, e-mail, senha e tipo de perfil. |
| RF02 | O app deve permitir login com e-mail e senha. |
| RF03 | O app deve permitir login com conta Google. |
| RF04 | O app deve permitir que o usuario escolha seu perfil inicial: atleta, coach, estagiario ou perfil hibrido. |
| RF05 | O app deve direcionar o usuario para a area correta apos o login, de acordo com seu perfil. |
| RF06 | O app deve permitir recuperacao ou redefinicao de senha. |
| RF07 | O app deve permitir logout da conta. |
| RF08 | O app deve bloquear ou limitar o acesso de contas desativadas. |
| RF09 | O app deve permitir reativacao de conta quando aplicavel. |
| RF10 | O app deve disponibilizar telas de termos de uso e politica de privacidade. |

### Area do atleta

| Codigo | Requisito |
|---|---|
| RF11 | O atleta deve visualizar uma tela inicial com saudacao, resumo do treino, pendencias, insights e atalhos principais. |
| RF12 | O atleta deve consultar o treino do dia por data. |
| RF13 | O atleta deve visualizar o treino dividido em partes, como aquecimento, treino extra, skill e WOD. |
| RF14 | O atleta deve visualizar detalhes do treino, incluindo tipo, duracao, movimentos, cargas e observacoes. |
| RF15 | O atleta deve registrar o resultado de um treino realizado. |
| RF16 | O registro de resultado deve permitir informar categoria, horario, adaptacoes, conclusao do treino, tipo de resultado e nivel de esforco. |
| RF17 | O atleta deve registrar resultados de diferentes formatos de treino, como For Time, AMRAP e EMOM. |
| RF18 | O atleta pode registrar descanso quando nao treinar. |
| RF19 | O atleta pode registrar outras atividades fisicas alem do treino principal. |
| RF20 | O atleta deve consultar historico de treinos e registros ja realizados. |
| RF21 | O atleta deve poder remover registros quando necessario. |
| RF22 | O atleta deve visualizar indicadores semanais, como frequencia, esforco, pontos, PRs e estimulos trabalhados. |
| RF23 | O atleta deve acompanhar sua evolucao em graficos e resumos por periodo. |
| RF24 | O atleta deve visualizar insights semanais sobre seu desempenho. |
| RF25 | O atleta deve visualizar insights de evolucao com base no historico de semanas anteriores. |
| RF26 | O atleta deve visualizar insights pre-treino quando houver treino publicado para o dia. |
| RF27 | O atleta deve registrar e acompanhar PRs pessoais. |
| RF28 | O atleta deve consultar detalhes de PRs, benchmarks, historico e graficos relacionados. |

### Area do coach

| Codigo | Requisito |
|---|---|
| RF29 | O coach deve visualizar uma tela inicial com resumo do dia, treinos, ciclo atual, insights e atalhos principais. |
| RF30 | O coach deve importar treinos por arquivo PDF. |
| RF31 | O sistema deve processar o PDF importado e transformar as paginas validas em treinos. |
| RF32 | O sistema deve ignorar paginas sem treino valido, como capas, dias sem treino ou box fechado. |
| RF33 | Treinos importados devem iniciar como rascunho antes de serem liberados aos atletas. |
| RF34 | O coach deve visualizar treinos cadastrados por data. |
| RF35 | O coach deve visualizar treinos em rascunho e treinos publicados. |
| RF36 | O coach deve poder editar treinos antes ou depois da publicacao. |
| RF37 | A edicao de treino deve permitir alterar secoes, nomes, modalidades, duracao, rounds, movimentos, repeticoes e cargas. |
| RF38 | O coach deve publicar um treino para que ele fique disponivel aos atletas. |
| RF39 | Ao publicar um treino, o sistema deve marcar data de publicacao e usuario responsavel. |
| RF40 | O coach deve poder excluir treinos cadastrados. |
| RF41 | O coach deve consultar detalhes de um treino publicado ou em rascunho. |
| RF42 | O coach deve visualizar insights e analises relacionadas ao treino. |
| RF43 | O coach deve visualizar ciclos mensais de treino. |
| RF44 | O coach deve visualizar detalhes de um ciclo, incluindo categorias, tipos de treino e pontos de atencao. |
| RF45 | O coach deve gerenciar informacoes de perfil, especialidades e certificacoes. |

### Inteligencia e analises

| Codigo | Requisito |
|---|---|
| RF46 | O sistema deve analisar treinos cadastrados para identificar estrutura, estimulos e informacoes importantes. |
| RF47 | O sistema deve gerar insights para o atleta com linguagem simples e util. |
| RF48 | O sistema deve gerar insights semanais apos o registro de resultados. |
| RF49 | O sistema deve gerar insights de evolucao considerando um periodo maior do historico do atleta. |
| RF50 | O sistema deve gerar insights pre-treino quando um treino for publicado. |
| RF51 | O sistema deve evitar gerar insights personalizados quando o usuario desativar a personalizacao por IA. |
| RF52 | O sistema deve considerar historico, frequencia, esforco, PRs, categoria e resultados anteriores para montar os insights. |
| RF53 | O sistema deve evitar inventar dados quando o perfil do atleta estiver incompleto. |
| RF54 | O sistema deve identificar alertas como repeticao de estimulo, queda de frequencia, carga excessiva, descanso insuficiente e baixa consistencia. |
| RF55 | O sistema deve comparar atletas com perfis semelhantes para apoiar analises e previsoes, quando houver dados suficientes. |

### Notificacoes

| Codigo | Requisito |
|---|---|
| RF56 | O app deve exibir uma tela de notificacoes internas. |
| RF57 | O app deve indicar notificacoes nao lidas. |
| RF58 | O usuario deve poder marcar uma notificacao como lida. |
| RF59 | O usuario deve poder marcar todas as notificacoes como lidas. |
| RF60 | O sistema deve enviar notificacoes sobre treinos, registros pendentes e insights, conforme configuracao do usuario. |
| RF61 | O sistema deve evitar notificacoes duplicadas para o mesmo evento. |
| RF62 | O sistema deve remover notificacoes antigas automaticamente. |

### Configuracoes, privacidade e suporte

| Codigo | Requisito |
|---|---|
| RF63 | O atleta deve poder configurar o recebimento de insights semanais, insights de evolucao, insights pre-treino e lembretes de treino. |
| RF64 | O coach deve poder configurar analises de treino diario, analises de ciclo e lembretes relacionados a treinos pendentes. |
| RF65 | O usuario deve poder ativar ou desativar personalizacao por IA. |
| RF66 | O usuario deve poder ativar ou desativar compartilhamento de diagnosticos. |
| RF67 | O usuario deve poder solicitar download/exportacao de seus dados. |
| RF68 | O usuario deve poder solicitar desativacao da conta. |
| RF69 | O usuario deve poder solicitar exclusao permanente da conta. |
| RF70 | O usuario deve poder enviar mensagem de suporte. |
| RF71 | O usuario deve poder enviar feedback sobre o app. |
| RF72 | O usuario deve poder relatar problemas ou bugs. |
| RF73 | O app deve informar as permissoes usadas pelo aplicativo, como notificacoes e galeria. |

## Requisitos nao funcionais

| Codigo | Requisito |
|---|---|
| RNF01 | O app deve ter linguagem clara, amigavel e em portugues do Brasil. |
| RNF02 | A navegacao deve ser simples, separando bem a experiencia do atleta e a experiencia do coach. |
| RNF03 | O app deve funcionar principalmente em dispositivos moveis Android e iOS. |
| RNF04 | O app deve manter padrao visual consistente entre telas, botoes, cards, formularios e menus. |
| RNF05 | O app deve proteger dados pessoais, permitindo que cada usuario acesse apenas suas proprias informacoes. |
| RNF06 | O app deve diferenciar permissoes de atleta, coach, estagiario, perfil hibrido e administrador. |
| RNF07 | Atletas devem visualizar apenas treinos publicados; rascunhos devem ficar restritos a coaches e perfis autorizados. |
| RNF08 | Contas desativadas nao devem conseguir alterar dados ou usar recursos principais. |
| RNF09 | O usuario deve ter controle sobre o uso de IA e diagnosticos. |
| RNF10 | O sistema nao deve usar dados pessoais para insights quando a personalizacao por IA estiver desativada. |
| RNF11 | O app deve tratar falhas de conexao ou carregamento sem travar a experiencia do usuario. |
| RNF12 | Operacoes demoradas, como importacao de PDF e geracao de insights, devem acontecer em segundo plano sempre que possivel. |
| RNF13 | O processamento de PDFs deve preservar informacoes importantes do treino e reduzir erros de leitura. |
| RNF14 | Treinos importados automaticamente devem passar por revisao do coach antes de aparecerem para atletas. |
| RNF15 | O sistema deve evitar repeticao desnecessaria de processamento e notificacoes. |
| RNF16 | O sistema deve suportar crescimento no numero de atletas, coaches, treinos e resultados sem depender de processamento manual. |
| RNF17 | O app deve salvar datas, registros e atualizacoes de forma organizada para permitir historico confiavel. |
| RNF18 | O sistema deve manter compatibilidade com dados antigos quando houver mudanca no formato dos treinos. |
| RNF19 | As respostas de IA devem ser curtas, humanas, coerentes e sem termos excessivamente tecnicos para o atleta. |
| RNF20 | O sistema deve evitar mostrar insights antigos como se fossem atuais. |
| RNF21 | O app deve permitir manutencao e evolucao do codigo por meio de separacao entre telas, servicos, modelos e regras de negocio. |
| RNF22 | O projeto deve possuir testes para partes sensiveis, como parser de PDF, notificacoes, configuracoes, conta e insights. |
| RNF23 | O app deve respeitar formatos brasileiros de data, idioma e exibicao de informacoes. |
| RNF24 | Arquivos enviados pelo coach devem ter restricoes de tipo e tamanho para reduzir riscos de uso indevido. |
| RNF25 | O sistema deve registrar eventos importantes, como criacao de conta, publicacao de treino, geracao de insights e notificacoes. |

## Regras de negocio principais

- Apenas usuarios autenticados podem acessar as areas internas do app.
- O perfil do usuario define a tela inicial e os recursos disponiveis.
- Treinos importados por PDF entram como rascunho.
- Atletas so visualizam treinos publicados.
- A publicacao de um treino pode disparar analises e insights pre-treino.
- O registro de resultados alimenta estatisticas, carga semanal e insights futuros.
- A desativacao da personalizacao por IA impede a criacao de insights personalizados.
- A desativacao de uma notificacao especifica impede apenas aquele aviso, nao necessariamente a geracao do dado no sistema.
- Notificacoes internas podem existir mesmo quando o envio push para o celular falhar.
- O sistema deve evitar duplicar insights e notificacoes para o mesmo treino ou evento.

## Observacoes sobre o estado atual do projeto

Durante a analise do codigo, algumas partes aparecem implementadas com dados reais no Firebase, enquanto outras ainda usam dados simulados ou possuem marcacoes de evolucao futura.

Recursos mais consolidados:

- Autenticacao com e-mail/senha e Google.
- Separacao de perfil entre atleta, coach e perfis hibridos.
- Importacao de PDF pelo coach.
- Processamento de treino no backend.
- Fluxo de rascunho e publicacao de treinos.
- Registro de resultados do atleta.
- Estatisticas, carga semanal e historico.
- Insights de atleta usando IA.
- Notificacoes internas.
- Configuracoes, privacidade, suporte, exportacao e conta.

Recursos que ainda parecem estar parcial ou temporariamente simulados:

- Alguns dados de PRs, benchmarks e graficos especificos.
- Perfil detalhado de coach e atleta em algumas telas.

Essas partes podem continuar como requisitos do projeto, mas precisam de integracao completa com banco de dados e regras finais antes de serem consideradas totalmente prontas para uso real.
