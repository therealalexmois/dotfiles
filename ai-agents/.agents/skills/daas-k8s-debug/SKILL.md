---
name: daas-k8s-debug
description: >-
  Триаж и дебаг rollout-а DaaS / Spirit Deploy в Kubernetes после выката приложения dwsai-data-agent. Триггеры: «под не поднимается», «CrashLoopBackOff», «ImagePullBackOff», «почему упал роллаут в k8s», «dp deploy watch показывает ошибку», «вебхук SPIRE/MSA отклоняет ресурс», «деплой завис», «не доехал ConfigMap», «приехал не тот образ», «pod в Error», «rollout timeout», «namespace Forbidden», «дебаг деплоя в daas». Срабатывает, даже если слово «debug» не названо явно, но речь про разбор того, почему после деплоя в Kubernetes что-то не поднялось. Read-only по умолчанию: изменяющие команды только после явного подтверждения.
---

# DaaS / K8s Debug

Разбор ситуации, когда приложение уже выкатили через DaaS / Spirit Deploy, но в Kubernetes что-то не поднялось: rollout завис, под в `CrashLoopBackOff` или `ImagePullBackOff`, webhook отклоняет ресурсы, не доехал ConfigMap или приехал не тот образ.

Источник: адаптировано из `hwaas/nmsgo` `.agents/skills/daas-k8s-debug/SKILL.md` (MR 785, https://gitlab.tcsbank.ru/hwaas/nmsgo/-/merge_requests/785). Здесь стек переведен на DWSAI и на инструменты `dp` MCP: `dp_kube_*` (`dp kube`), `dp_sage_*` (`dp sage`), `dp deploy` (Spirit Deploy). Raw `kubectl` оставлен только как fallback.

## Связанные skills

- `spirit-deploy` - deploy-time counterpart: как готовить `application.yaml` и выстраивать `create → do → watch`. Этот skill - его post-deploy DEBUG-сторона: что делать, когда выкат уже прошел, но в k8s проблема.
- `work-release-manager` - monitored-adjacent: production-релиз end-to-end (changelog, тег, deploy, мониторинг, post-release smoke). Когда дебаг ведется в рамках релиза, он управляет процессом, а этот skill дает детальный триаж rollout-а.
- `gitlab-mcp-workflow` - pipeline и CI-логи, если проблема началась со сборки образа.

## Модель DaaS

- DaaS / Spirit Deploy рендерит Kubernetes-ресурсы в целевой namespace: `Deployment`, `ReplicaSet`, `Pod`, `ConfigMap`, `Service`, SPIRE/MSA labels и другие объекты.
- `deploy/service.yml` (`.devplatform/*/service.yml`) описывает сервис Software Catalog.
- Конфигурация Spirit application описывает DaaS component (имя Deployment в k8s).
- Kubernetes workload names и SPIRE labels должны соответствовать component name из Application Catalog. Рассинхрон имен - частая причина webhook-ошибок.

Пример контекста DWSAI (EXAMPLE, подставь свои значения):

```text
Tenant:      dwsai
Application: dwsai-data-agent          # внутреннее имя; user-facing - Nessy Data Agent
Spirit app:  data-agent-prod           # для `dp deploy --app` (prod); dev: data-agent-dev
Component:   data-agent-webservice-prod # имя Deployment в k8s и SPIRE component
Namespace:   dwsai-data-agent-prod-prod-daas    # паттерн: dwsai-data-agent-<env>-<env>-daas
Env:         dev | prod
Cluster:     bm-ix-m5-inside-wl1.prod, bm-ix-m5-inside-wl4.prod   # prod; см. `dp kube get clusters`
```

Инфраструктуру, которую не знаешь точно (имена кластеров, dev-namespace, имена component/ConfigMap, image stream), НЕ выдумывай. Бери из `dp kube get clusters` / `dp kube get namespaces`, из `dp deploy get` и из `deploy/service.yml`, либо помечай как `<placeholder>` и проси уточнить.

## Правило безопасности (read-only first)

Сначала собираем факты read-only. Без явного подтверждения пользователя в текущем шаге НЕ запускаем изменяющие команды:

- `kubectl delete`, `kubectl rollout undo`, `kubectl scale`, `kubectl edit`, `kubectl apply`;
- любые write-команды `dp deploy` (`do`, `update`, `rollback`, `shutdown`).

Production (`dwsai-data-agent-prod-prod-daas`) - повышенная осторожность: всегда показывай команду целиком и проси подтверждение, даже если пользователь торопит. `kubectl exec` в prod-namespace обычно запрещен RBAC; готовность подов (зеленые startup/readiness/liveness probes) и есть подтверждение здоровья.

Не используй `-A` / cluster-wide выборки без необходимости и без соответствующих прав.

## Инструменты

Предпочитай MCP `dp`:

- `dp_kube_*` (`dp kube`): обзор подов, образов, готовности, рестартов по кластерам; список кластеров и namespaces.
- `dp_sage_*` (`dp sage`): логи и регрессионный разбор ERROR. Workflow: `groups` -> `systems` -> `completion` (prompt -> MageQL) -> `logs`/`query`.
- `dp deploy` (Spirit Deploy): состояние rollout-а и rendered-конфиг приложения.

Raw `kubectl` - fallback, когда нужен `describe`, `events`, `rollout history`, выгрузка YAML ресурса или `--previous` логи, которых нет в `dp kube`. Для raw `kubectl` сначала нужен kubeconfig на нужный cluster/namespace (см. ниже).

## Триаж: порядок

### 1. Зафиксировать исходные данные

Перед командами зафиксируй: tenant, application, env, namespace, cluster, component, ожидаемый image/tag, revision ID (если известен) и симптом (webhook error / rollout timeout / CrashLoop / ImagePull / missing config / wrong image).

### 2. Проверить DaaS-слой (Spirit Deploy)

Состояние rollout-а и rendered application config - первый слой. `dp deploy` в DWSAI БЕЗ `--env` (среда задана конфигом приложения); подкоманды `do`, `get`, `watch`, `rollback` (нет `status` - используй `get`/`watch`).

```bash
dp deploy watch --tenant dwsai --app data-agent-prod        # дождаться/увидеть исход последней ревизии
dp deploy get   --tenant dwsai --app data-agent-prod -f /tmp/dwsai-data-agent.yaml
grep -n "data-agent\|placement:\|clusters:\|image" /tmp/dwsai-data-agent.yaml
```

Если в rendered-конфиге component называется иначе, чем workload или SPIRE label в k8s, это типичная причина webhook-ошибок. Детали `application.yaml`, режимы `--file/--local`, `isModified`, `serviceId` - в skill `spirit-deploy`.

### 3. Обзор Kubernetes namespace (dp_kube_*)

`dp kube get logs` дает JSON по кластерам: `.clusters[].pods[].containers[]` с полями `image`, `ready`, `restarts`, `status`. Это быстрый способ увидеть образ и здоровье подов без kubeconfig.

```bash
dp kube get clusters                                          # валидные имена кластеров для env
dp kube get namespaces -e <env> -t dwsai                      # доступные namespaces
dp kube get logs -n dwsai-data-agent-prod-prod-daas -e prod \
  -c bm-ix-m5-inside-wl1.prod,bm-ix-m5-inside-wl4.prod -l 1                              # поды/образ/ready/restarts по кластерам
```

Что проверяем: все контейнеры на ожидаемом теге, `ready=true`, `restarts` в норме, `status=Running`. Контейнер не на том теге, `ready=false` или растущие `restarts` указывают на проблемный pod.

### 4. Drill-down: rollout, describe, logs (fallback на raw kubectl)

`dp kube` дает срез состояния, но детальный разбор (`describe`, `events`, `rollout history`, `--previous` логи) обычно идет через raw `kubectl`. Сначала kubeconfig на нужный cluster/namespace:

```bash
dp auth login
dp auth configure-kubeconfig --cluster-name <cluster> --account-name "$(whoami)@tbank.ru"
kubectl config set-context --current --namespace=dwsai-data-agent-prod-prod-daas
kubectl config current-context
kubectl config view --minify --output 'jsonpath={..namespace}'; echo
```

Если `Forbidden` - проверь доступы (для чтения обычно нужна роль `namespace-viewer`, для изменений - `namespace-admin`):

```bash
dp kube get namespaces -e <env> -t dwsai
kubectl auth can-i list deployments -n dwsai-data-agent-prod-prod-daas
kubectl auth can-i list events      -n dwsai-data-agent-prod-prod-daas
```

Обзор и события:

```bash
NS=dwsai-data-agent-prod-prod-daas
kubectl get deploy,rs,pod -n "$NS"
kubectl get deploy,rs,pod -n "$NS" | grep -E '0/|CrashLoop|Error|ImagePull|data-agent'
kubectl get events -n "$NS" --sort-by=.lastTimestamp | tail -n 50
kubectl get rs -n "$NS" --sort-by=.metadata.creationTimestamp | tail -n 30
```

Rollout, deployment, pod, logs:

```bash
kubectl rollout status  deploy/data-agent-webservice-prod -n "$NS"
kubectl rollout history deploy/data-agent-webservice-prod -n "$NS"
kubectl describe deploy data-agent-webservice-prod -n "$NS"
kubectl describe pod <pod-name> -n "$NS"
kubectl get pod <pod-name> -n "$NS" -o jsonpath='{.spec.containers[*].name}'; echo
kubectl logs <pod-name> -n "$NS" -c <container-name> --tail=120
kubectl logs <pod-name> -n "$NS" -c <container-name> --previous --tail=120
```

`--previous` нужен, когда контейнер уже рестартнул и текущий лог начинается после падения.

### 5. ConfigMap и образы

```bash
kubectl get cm -n "$NS"
kubectl get cm <configmap-name> -n "$NS" -o yaml
kubectl get cm <configmap-name> -n "$NS" -o jsonpath='{.data.config\.yaml}' | sed -n '1,160p'
kubectl get deploy data-agent-webservice-prod -n "$NS" -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{" "}{.image}{"\n"}{end}'
kubectl get pod    <pod-name>   -n "$NS" -o jsonpath='{range .spec.containers[*]}{.name}{" "}{.image}{"\n"}{end}'
```

### 6. Логи в Sage (dp_sage_*)

Sage - для разбора прикладных ошибок и регрессии. Анализируй ERROR регрессионно (новые сигнатуры против прошлого релиза), а не голым ERROR-count. Workflow MCP: `groups` -> `systems` -> `completion` -> `logs`/`query`.

```bash
dp sage query -q 'group="dwsai" system="data-agent" env="prod" level="ERROR"' --hours 1
# Если в логах есть version="release-...", фильтруй по нему и сравни с прошлым релизом:
dp sage query -q 'group="dwsai" system="data-agent" env="prod" version="<new-tag>"  level="ERROR"' --hours 1
dp sage query -q 'group="dwsai" system="data-agent" env="prod" version="<prev-tag>" level="ERROR"' --hours 24
```

Фейли только на ERROR, которых не было на прошлом релизе. Фон (ошибки трафика, давние `FLAG_NOT_FOUND`) не должен валить вывод.

## Типовые проблемы

### MSA / SPIRE webhook

Пример ошибки:

```text
admission webhook "msa-webhook.tcsbank.ru" denied the request:
component "<component>" not found in Application "dwsai-data-agent"("dwsai.<env>.dwsai-data-agent")
```

Причина: имя workload или SPIRE label в k8s не совпадает с component name в Spirit application, либо остался orphaned deployment под старым именем. Проверка:

```bash
kubectl get deploy data-agent-webservice-prod -n "$NS" -o yaml | grep -n \
  "spire.k8s.tinkoff.ru/application\|spire.k8s.tinkoff.ru/component\|spire.k8s.tinkoff.ru/tenant"
grep -n "<component>" /tmp/dwsai-data-agent.yaml
kubectl get deploy,rs -n "$NS" | grep data-agent
```

Ожидаемый набор labels (EXAMPLE):

```yaml
spire.k8s.tinkoff.ru/application: dwsai-data-agent
spire.k8s.tinkoff.ru/component: data-agent-webservice-prod
spire.k8s.tinkoff.ru/tenant: dwsai
```

Даже если MSA выключен (`trafficManagement.msaType: "off"`, `msaMode: DISABLE`), SPIRE labels могут оставаться на workload, и webhook все равно будет проверять существование component. Проверь старые orphaned deployments: если текущий component называется `data-agent-webservice-prod`, но старый deployment под прежним именем остался, он продолжит ловить webhook errors.

### CrashLoopBackOff

```bash
kubectl get pods -n "$NS" | grep -E 'CrashLoop|Error'
kubectl describe pod <pod-name> -n "$NS"
kubectl logs <pod-name> -n "$NS" -c <container-name> --previous --tail=120
```

`describe` покажет причину рестарта (OOMKilled, exit code, failed probe), `--previous` логи - что приложение писало перед падением.

### Oathkeeper uppercase log level

Пример ошибки:

```text
log.level: DEBUG
value must be one of "panic", "fatal", "error", "warn", "info", "debug"
```

Что делать: использовать lowercase `debug` в Oathkeeper config либо не прокидывать uppercase `LOG_LEVEL=DEBUG` в этот sidecar.

```bash
kubectl get cm <oathkeeper-configmap> -n "$NS" -o jsonpath='{.data.oathkeeper\.yaml}' | sed -n '1,20p'
```

### Missing required config fields

Пример ошибки:

```text
parse config: missing required fields: <field-a>, <field-b>
```

Конфиг приложения не доехал или DaaS-переменная не выставлена. Сверь ConfigMap в namespace с rendered-конфигом:

```bash
kubectl get cm <component-configmap> -n "$NS" -o yaml
dp deploy get --tenant dwsai --app data-agent-prod -f /tmp/dwsai-data-agent.yaml
grep -n "<field-a>\|<field-b>" /tmp/dwsai-data-agent.yaml
```

Если переменную меняли через `dp deploy`, без `isModified: true` сервер игнорирует новое значение (см. `spirit-deploy`).

### Образ или tag не тот

Ожидаемый образ: `docker-hosted.artifactory.tcsbank.ru/dwsai/dwsai-data-agent:<release-tag>`. Сверь префикс образа и тег.

```bash
kubectl get pod    <pod-name>   -n "$NS" -o jsonpath='{range .spec.containers[*]}{.name}{" "}{.image}{"\n"}{end}'
kubectl get deploy data-agent-webservice-prod -n "$NS" -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{" "}{.image}{"\n"}{end}'
# Быстрее - срез по всем кластерам:
dp kube get logs -n "$NS" -e <env> -c bm-ix-m5-inside-wl1.prod,bm-ix-m5-inside-wl4.prod -l 1   # сверь .image с ожидаемым тегом
```

Если деплой шел в API-режиме (`--tag`/`--sha`) - менялся только образ; rendered deployment должен ссылаться на ожидаемый тег. Если нет - проверь, что ревизия действительно применилась (`dp deploy watch`).

## Escalation payload

При обращении в поддержку Spirit Deploy / Runtime (например, канал `~spirit-deploy-feedback`) приложи:

- tenant, application, environment, namespace, cluster;
- revision ID;
- component name;
- deployment / ReplicaSet / pod name;
- полный webhook error или CrashLoop log;
- фрагмент `dp deploy get`, где виден component;
- `kubectl describe deploy` или `kubectl describe pod`.

Шаблон (EXAMPLE):

```text
Tenant:      dwsai
Application: dwsai-data-agent
Environment: prod
Namespace:   dwsai-data-agent-prod-prod-daas
Cluster:     bm-ix-m5-inside-wl1.prod | bm-ix-m5-inside-wl4.prod
Revision ID: <revision-id>
Component:   data-agent-webservice-prod
Error:       admission webhook "msa-webhook.tcsbank.ru" denied the request...
```
