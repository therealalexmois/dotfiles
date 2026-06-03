# Справочник application.yaml

Полное описание структуры и полей `application.yaml` для Spirit Deploy (DaaS).

## Содержание

- [Полный шаблон](#полный-шаблон)
- [Структура файла](#структура-файла)
- [Приложение (attributes)](#приложение-attributes)
- [Placement](#placement)
- [Компонент](#компонент)
- [Контейнер](#контейнер)
- [Ресурсы](#ресурсы)
- [Переменные окружения](#переменные-окружения)
- [Порты](#порты)
- [Пробы](#пробы)
- [Управление трафиком (trafficManagement)](#управление-трафиком-trafficmanagement)
- [Параметры для deployment / webservice](#параметры-для-deployment--webservice)
- [Параметры для statefulset](#параметры-для-statefulset)
- [Параметры для crontask](#параметры-для-crontask)
- [Параметры для task](#параметры-для-task)
- [Заполненный пример](#заполненный-пример)

---

## Полный шаблон

Генерируется командой `dp deploy create --new daas --tenant <tenant> --env <env>` в текущей директории. Placeholder-значения (`<...>`) нужно заменить вручную.

```yaml
attributes:
    applicationName: <application-name>
    components:
        - containers:
            - envs:
                - isModified: true
                  name: APP_ENV
                  value: ""
                - isModified: true
                  name: APP_CLUSTER
                  value: ""
                - isModified: true
                  name: APP_SYSTEM
                  value: ""
              imageStream: <image-stream>
              livenessProbe:
                failureThreshold: 5
                httpGet:
                    path: /health
                    port: 8080
                    scheme: HTTP
                initialDelaySeconds: 10
                periodSeconds: 10
                successThreshold: 1
                terminationGracePeriodSeconds: 0
                timeoutSeconds: 5
              ports:
                - containerPort: 8080
                  name: http-web
                  protocol: TCP
              readinessProbe:
                failureThreshold: 5
                httpGet:
                    path: /health
                    port: 8080
                    scheme: HTTP
                initialDelaySeconds: 10
                periodSeconds: 10
                successThreshold: 1
                terminationGracePeriodSeconds: 0
                timeoutSeconds: 5
              resources:
                cpu: 250m
                mem: 256Mi
              trafficManagement:
                msaType: "off"
                portConfig:
                  - ingress: ""
                    msaMode: DISABLE
                    name: http-web
              runAsGroup: 2000
              runAsUser: 2000
              serviceId: <service-id>
              tag: <tag>
              volumeMounts: []
          deploySpecificParams:
            labelSelectors: null
            replicas: 2
          initContainers: []
          isModified: false
          name: <component-name>
          networkAccesses: {}
          type: deployment
          volumes: []
    placement:
        clusters:
            - ya-ruc1-dev1
        type: k8s
    description: ""
    environmentType: development
    sageGroup: <sage-group>
kind: ApplicationFull
```

---

## Структура файла

| Поле | Тип | Описание |
|------|-----|----------|
| `kind` | string | Всегда `ApplicationFull` |
| `attributes` | object | Конфигурация приложения |

## Приложение (attributes)

| Поле | Тип | Обязательный | Описание |
|------|-----|--------------|----------|
| `applicationName` | string | да | Имя приложения в Spirit Deploy |
| `components` | array | да | Массив компонентов (минимум один) |
| `environmentType` | string | да | `development` или `production`; должно совпадать с `--env` |
| `placement` | object | нет | Тип и кластеры размещения |
| `deployStrategy` | string | нет | Стратегия деплоя: `Rolling` |
| `releaseStrategy` | string | нет | Стратегия релиза: `Manual` |
| `description` | string | нет | Описание приложения |
| `sageGroup` | string | нет | Группа Sage для логирования |
| `finedog` | object | нет | Finedog-интеграция. Содержит `unitId` (string) |

## Placement

| Поле | Тип | Описание |
|------|-----|----------|
| `type` | string | Тип размещения: `k8s`, `vm`, `stub` |
| `clusters` | array of strings | Список кластеров (зависит от `--env`) |

```yaml
placement:
    type: k8s
    clusters:
        - cluster-1
        - cluster-2
```

## Компонент

Каждый компонент описывает одну деплой-единицу (Deployment, StatefulSet, CronJob и т. д.).

| Поле | Тип | Обязательный | Описание |
|------|-----|--------------|----------|
| `name` | string | да | Имя компонента |
| `type` | string | да | Тип компонента |
| `containers` | array | да | Основные контейнеры |
| `initContainers` | array | нет | Init-контейнеры |
| `volumes` | array | нет | Внешние тома |
| `networkAccesses` | object | нет | Сетевые доступы |
| `deploySpecificParams` | object | нет | Параметры для `deployment` / `webservice` |
| `stsSpecificParams` | object | нет | Параметры для `statefulset` |
| `cronTaskSpecificParams` | object | нет | Параметры для `crontask` |
| `taskSpecificParams` | object | нет | Параметры для `task` |
| `isModified` | bool | нет | Read-only при GET |

Допустимые значения `type`:

| Значение | Описание |
|----------|----------|
| `deployment` | Стандартный Deployment |
| `webservice` | Веб-сервис |
| `task` | Одноразовая задача (Job) |
| `crontask` | Периодическая задача (CronJob) |
| `k8scatalog` | Каталог K8s |
| `vmcatalog` | Каталог VM |
| `vmdeploy` | Деплой на VM |

## Контейнер

| Поле | Тип | Обязательный | Описание |
|------|-----|--------------|----------|
| `serviceId` | string (UUID) | да | UUID сервиса из Software Catalog |
| `imageStream` | string | да | Имя image stream |
| `tag` | string | да | Тег образа |
| `sha` | string | нет | SHA коммита |
| `branch` | string | нет | Имя ветки |
| `resources` | object | да | CPU / memory / GPU |
| `envs` | array | нет | Переменные окружения |
| `ports` | array | нет | Порты контейнера |
| `livenessProbe` | object | нет | Liveness-проба |
| `readinessProbe` | object | нет | Readiness-проба |
| `startupProbe` | object | нет | Startup-проба |
| `volumeMounts` | array | нет | Монтирование томов |
| `configPreset` | string | нет | Пресет конфигурации |
| `configMountDir` | string | нет | Директория монтирования конфига |
| `trafficManagement` | object | нет | Управление трафиком (MSA) |
| `runAsUser` | int | нет | UID процесса в контейнере |
| `runAsGroup` | int | нет | GID процесса в контейнере |
| `command` | array of strings | нет | Переопределение entrypoint |
| `args` | array of strings | нет | Аргументы команды |
| `workingDir` | string | нет | Рабочая директория |
| `metrics` | object | нет | Настройки метрик |

## Ресурсы

| Поле | Тип | Описание | Примеры |
|------|-----|----------|---------|
| `cpu` | string | CPU в формате Kubernetes | `125m`, `250m`, `500m`, `1`, `2` |
| `mem` | string | Память в формате Kubernetes | `128Mi`, `256Mi`, `512Mi`, `1Gi` |
| `gpu` | string | GPU (опционально) | `1` |

```yaml
resources:
    cpu: 250m
    mem: 256Mi
```

## Переменные окружения

Только plain-text строки. Интеграция с Vault и ссылки на секреты не поддерживаются. Пустые значения недопустимы. Список переменных должен совпадать со списком `envs` из `service.yaml`.

| Поле | Тип | Описание |
|------|-----|----------|
| `name` | string | Имя переменной |
| `value` | string | Значение (только строки) |
| `isModified` | bool | `true` — сервер обновит значение |

**При добавлении или изменении переменной всегда ставь `isModified: true`** — иначе сервер проигнорирует новое значение.

```yaml
envs:
    - name: APP_ENV
      value: "production"
      isModified: true       # ← обязательно при изменении
    - name: STATIC_VAR
      value: "unchanged"
      isModified: false      # ← не изменялась
```

## Порты

| Поле | Тип | Описание |
|------|-----|----------|
| `containerPort` | int | Номер порта |
| `name` | string | Имя порта |
| `protocol` | string | Протокол: `TCP` или `UDP` |

```yaml
ports:
    - containerPort: 8080
      name: http-web
      protocol: TCP
```

## Пробы

Все три вида проб (`livenessProbe`, `readinessProbe`, `startupProbe`) имеют одинаковую структуру.

Общие параметры:

| Поле | Тип | Описание |
|------|-----|----------|
| `failureThreshold` | int | Количество неудачных проверок до сбоя |
| `initialDelaySeconds` | int | Задержка перед первой проверкой (сек) |
| `periodSeconds` | int | Интервал между проверками (сек) |
| `successThreshold` | int | Количество успешных проверок для готовности |
| `timeoutSeconds` | int | Таймаут одной проверки (сек) |
| `terminationGracePeriodSeconds` | int | Время на graceful shutdown |

Тип проверки — один из трёх:

| Поле | Подполя | Описание |
|------|---------|----------|
| `httpGet` | `path`, `port`, `scheme` | HTTP-проба |
| `grpcProbe` | `port`, `service` | gRPC-проба |
| `tcpSocket` | `port` | TCP-проба |

HTTP-проба:

```yaml
livenessProbe:
    failureThreshold: 5
    httpGet:
        path: /health
        port: 8080
        scheme: HTTP
    initialDelaySeconds: 10
    periodSeconds: 10
    successThreshold: 1
    terminationGracePeriodSeconds: 0
    timeoutSeconds: 5
```

gRPC-проба:

```yaml
readinessProbe:
    failureThreshold: 3
    grpcProbe:
        port: 9090
        service: my.service.Health
    initialDelaySeconds: 5
    periodSeconds: 10
    successThreshold: 1
    terminationGracePeriodSeconds: 0
    timeoutSeconds: 5
```

TCP-проба:

```yaml
startupProbe:
    failureThreshold: 30
    tcpSocket:
        port: 8080
    initialDelaySeconds: 0
    periodSeconds: 1
    successThreshold: 1
    terminationGracePeriodSeconds: 0
    timeoutSeconds: 1
```

## Управление трафиком (trafficManagement)

| Поле | Тип | Описание |
|------|-----|----------|
| `msaType` | string | Тип MSA: `off`, `library`, `sidecar` |
| `portConfig` | array | Конфигурация портов |

Элемент `portConfig`:

| Поле | Тип | Описание |
|------|-----|----------|
| `name` | string | Имя порта (должно совпадать с `ports`) |
| `ingress` | string | Ingress-правило. Пустая строка — без ingress |
| `msaMode` | string | Режим MSA: `DISABLE`, `STRICT`, `PERMISSIVE` |

```yaml
trafficManagement:
    msaType: "off"
    portConfig:
        - name: http-web
          ingress: ""
          msaMode: DISABLE
```

## Параметры для deployment / webservice

Поле `deploySpecificParams`:

| Поле | Тип | Описание |
|------|-----|----------|
| `replicas` | int | Количество реплик (≥ 1) |
| `labelSelectors` | map[string]string | Label-селекторы |
| `strategyType` | string | Тип стратегии обновления |
| `strategyRollingUpdateMaxSurge` | int | Макс. дополнительных подов при rolling update |
| `strategyRollingUpdateMaxUnavailable` | int | Макс. недоступных подов при rolling update |
| `minReadySeconds` | int | Мин. время готовности пода (сек) |
| `progressDeadlineSeconds` | int | Таймаут прогресса деплоя (сек) |
| `revisionHistoryLimit` | int | Лимит хранения ревизий |

```yaml
deploySpecificParams:
    replicas: 2
    labelSelectors: null
```

## Параметры для statefulset

Поле `stsSpecificParams`:

| Поле | Тип | Описание |
|------|-----|----------|
| `replicas` | int | Количество реплик (≥ 2) |
| `labelSelectors` | map[string]string | Label-селекторы |
| `revisionHistoryLimit` | int | Лимит хранения ревизий |
| `serviceName` | string | Имя headless-сервиса |

## Параметры для crontask

Поле `cronTaskSpecificParams`:

| Поле | Тип | Описание |
|------|-----|----------|
| `schedule` | string | Расписание в формате cron |
| `activeDeadlineSeconds` | int | Максимальное время выполнения (сек) |

## Параметры для task

Поле `taskSpecificParams`:

| Поле | Тип | Описание |
|------|-----|----------|
| `activeDeadlineSeconds` | int | Максимальное время выполнения (сек) |

---

## Заполненный пример

`deployment` с тремя переменными окружения, HTTP-пробами и двумя репликами в dev-кластере.

```yaml
attributes:
    applicationName: spirit-cli-sandbox
    components:
        - containers:
            - envs:
                - name: APP_ENV
                  value: "development"
                  isModified: true
                - name: K8S_CLUSTER
                  value: "ya-ruc1-dev1"
                  isModified: true
                - name: APP_DATA_CENTER
                  value: "dc1"
                  isModified: true
              imageStream: docker-hosted.artifactory.tcsbank.ru/invest-core/spirit-cli-sandbox
              livenessProbe:
                failureThreshold: 5
                httpGet:
                    path: /health
                    port: 8080
                    scheme: HTTP
                initialDelaySeconds: 10
                periodSeconds: 10
                successThreshold: 1
                terminationGracePeriodSeconds: 0
                timeoutSeconds: 5
              ports:
                - containerPort: 8080
                  name: http-web
                  protocol: TCP
              readinessProbe:
                failureThreshold: 5
                httpGet:
                    path: /health
                    port: 8080
                    scheme: HTTP
                initialDelaySeconds: 10
                periodSeconds: 10
                successThreshold: 1
                terminationGracePeriodSeconds: 0
                timeoutSeconds: 5
              resources:
                cpu: 250m
                mem: 256Mi
              trafficManagement:
                msaType: "off"
                portConfig:
                  - ingress: ""
                    msaMode: DISABLE
                    name: http-web
              runAsGroup: 2000
              runAsUser: 2000
              serviceId: 42eefdb1-c89c-40c8-abbc-f4463de5b2ce
              tag: release-1.0.0
              volumeMounts: []
          deploySpecificParams:
            labelSelectors: null
            replicas: 2
          initContainers: []
          isModified: false
          name: app
          networkAccesses: {}
          type: deployment
          volumes: []
    placement:
        clusters:
            - ya-ruc1-dev1
        type: k8s
    description: ""
    environmentType: development
    sageGroup: ""
kind: ApplicationFull
```

Связанный `service.yaml` (Software Catalog), из которого берётся `serviceId` (UUID) и список `envs`:

```yaml
---
apiVersion: devplatform.tcsbank.ru/v1
kind: Service
metadata:
  name: spirit-cli-sandbox
  labels:
    GO: "1.23"
spec:
  type: "backend"
  criticalLevel: "OP"
  provides:
    - name: spirit-cli-sandbox-api
      tenant: invest-core
  imageStream: "docker-hosted.artifactory.tcsbank.ru/invest-core/spirit-cli-sandbox"
  envs:
    - APP_ENV
    - K8S_CLUSTER
    - APP_DATA_CENTER
```
