# RAIOS - Dashboard e gerenciamento no Node-RED

O RAIOS usará o Node-RED já existente como plataforma web e camada de processamento. O dashboard será ampliado com gestão de potência, relatórios e uma árvore de decisão orientada por regras. O SQLite armazenará estações, carregadores, telemetria, alertas e decisões.

## Estrutura prevista

```text
ESP32/Wokwi -- MQTT --> Node-RED -- SQLite
                           ├── FlowFuse Dashboard: operação e relatórios
                           └── regras: recomendação, simulação e registro de decisão
```

O Node-RED continua responsável por receber/validar mensagens, calcular indicadores e servir a interface. O banco SQLite é um arquivo local lido e escrito pelos fluxos. O esquema está em `database/schema.sql`.

## Módulos do dashboard

1. **Visão geral:** demanda total, limite, geração solar, potência da rede, utilização, estado e alertas.
2. **Gerenciamento de potência:** limite configurável, meta segura e estratégias de alocação proporcional ou por prioridade.
3. **Árvore de decisão:** verificar demanda contra meta; se estiver no limite, recomendar acompanhamento; se superar a meta, apresentar a redução necessária, efeito por carregador e estimativa de custo por hora antes de registrar a decisão.
4. **Relatórios:** períodos de 24 horas, 7 dias e 30 dias; demanda média e de pico, geração solar, contribuição da rede, ocorrências acima do alerta e decisões registradas.

Na primeira versão, a árvore apenas simula e registra recomendações. Ela não envia comandos físicos aos carregadores. A integração de controle via OCPP será uma etapa própria.

## Banco de dados

Instale `node-red-node-sqlite` pelo **Manage palette → Install** do Node-RED. Configure um banco SQLite em um caminho estável, por exemplo `C:/Users/<usuario>/Documents/RAIOS/data/raios.sqlite3`, e execute `database/schema.sql` uma única vez usando um nó SQLite em modo **Batch without response**. Não coloque o arquivo do banco na pasta temporária.

O nó SQLite aceita parâmetros preparados. Use essa modalidade para inserir telemetria e decisões; não concatene dados recebidos do MQTT diretamente em SQL.

## Fluxo recebido e próximo passo

O fluxo enviado foi preservado como cópia corrigida em `flows/raios-mqtt-dashboard-fixed.json`. Nele, a entrada MQTT assina o tópico `raios/demo-8472/posto01/telemetria` (antes o campo continha o nome do broker) e o identificador do cliente MQTT é único (antes repetia o tópico). A função também aceita JSON como objeto ou texto e valida `demanda_kw` antes de exibir a leitura.

Para experimentar, faça backup/exportação do fluxo existente e importe esse arquivo no editor Node-RED usando **Import → select a file**. O fluxo corrigido mantém a página, o tema e o grupo existentes. Confira se o nó MQTT mostra conectado e se a mensagem do ESP32/Wokwi usa o mesmo tópico e contém `demanda_kw` numérico. O broker público `test.mosquitto.org` serve apenas para demonstração: não envie dados privados nem comandos reais por ele.

O fluxo corrigido ainda não persiste as amostras. Para acrescentar SQLite, instale `node-red-node-sqlite` via **Manage palette → Install**. Configure um banco em caminho persistente (por exemplo `C:/Users/<usuario>/Documents/RAIOS/data/raios.sqlite3`) e execute `database/schema.sql` uma vez em modo batch. Depois conecte a validação MQTT a um nó SQLite com prepared statement e parâmetros, e alimente os widgets do dashboard. Não concatene valores recebidos do MQTT diretamente no SQL.

O caminho de dados pretendido é:

```text
MQTT In → validar JSON → SQLite → indicadores, gráfico e árvore de decisão
```

O payload atual contém a demanda agregada. Para a árvore calcular redução ou prioridade por carregador, o ESP32 deverá publicar também um array `chargers` com identificador, potência solicitada e estado. Até esse formato existir, mantenha a recomendação no nível do posto e marcada como simulação; o painel não deve alegar que alterou a potência física.

## Nota sobre os números

Estimativas em R$/h dependem da tarifa cadastrada e assumem a potência atual mantida por uma hora. Relatórios de energia em kWh só devem ser calculados quando a frequência e os horários das leituras estiverem definidos; uma amostra de potência em kW não equivale, sozinha, a consumo acumulado.
