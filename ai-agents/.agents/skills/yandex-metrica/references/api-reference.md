# Yandex Metrica API — Full Reference

Base URL: `https://api-metrika.yandex.net`
Auth: `Authorization: OAuth TOKEN`

## 1. Authentication

Register app at https://oauth.yandex.ru/client/new
Permissions: `metrika:read` (read data), `metrika:write` (manage counters)

```bash
# Get token URL
https://oauth.yandex.ru/authorize?response_type=token&client_id=YOUR_CLIENT_ID
```

## 2. Management API

### Counters

```bash
# List counters
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counters?per_page=100" | jq .

# Create counter
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"counter":{"site":"example.com","name":"My Site"}}' \
  "https://api-metrika.yandex.net/management/v1/counters" | jq .

# Get counter
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678" | jq .

# Update counter
curl -s -X PUT -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"counter":{"name":"Updated Name"}}' \
  "https://api-metrika.yandex.net/management/v1/counter/12345678" | jq .

# Delete counter
curl -s -X DELETE -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678"
```

Counter list params: `per_page`, `offset`, `search_string`, `field` (goals, mirrors, grants), `type`, `status`, `favorite`, `label_id`, `sort`

### Goals

```bash
# List goals
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/goals" | jq .

# Create URL goal
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"goal":{"name":"Purchase","type":"url","conditions":[{"type":"contain","url":"/thank-you"}]}}' \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/goals" | jq .

# Create event goal
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"goal":{"name":"Form Submit","type":"action","conditions":[{"type":"exact","url":"form_submit"}]}}' \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/goals" | jq .

# Delete goal
curl -s -X DELETE -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/goal/GOAL_ID"
```

Goal types: `url`, `action`, `step`, `phone`, `email`, `form`, `messenger`, `button`, `file`, `search`, `payment_system`, `chat`

Condition types: `contain`, `exact`, `start`, `regexp`, `action`

### Filters

```bash
# List filters
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/filters" | jq .

# Create filter (exclude IP range)
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filter":{"attr":"client_ip","type":"interval","action":"exclude","start_ip":"192.168.1.1","end_ip":"192.168.1.255","status":"active"}}' \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/filters" | jq .

# Delete filter
curl -s -X DELETE -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/filter/FILTER_ID"
```

Filter attrs: `title`, `client_ip`, `url`, `referer`, `uniq_id`
Filter actions: `exclude`, `include`
Filter types: `equal`, `start`, `contain`, `interval` (IP only), `regexp`

### Operations (URL transformations)

```bash
# Create operation
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"operation":{"action":"cut_parameter","attr":"url","value":"utm_source","status":"active"}}' \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/operations" | jq .
```

Actions: `cut_fragment`, `cut_parameter`, `cut_all_parameters`, `merge_https_and_http`, `to_lower`, `replace_domain`

### Grants (Access)

```bash
# List grants
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/grants" | jq .

# Add grant
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"grant":{"user_login":"colleague","perm":"view"}}' \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/grants" | jq .

# Delete grant
curl -s -X DELETE -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/grant/USER_LOGIN"
```

Permissions: `public_stat`, `view`, `edit`, `analyst`, `analyst_access_filter`

### Labels

```bash
# List labels
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/labels" | jq .

# Create label
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"label":{"name":"Production"}}' \
  "https://api-metrika.yandex.net/management/v1/labels" | jq .

# Link counter to label
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/label/LABEL_ID"
```

### Segments

```bash
# List segments
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/apisegment/segments" | jq .

# Create segment
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"segment":{"name":"Mobile Users","expression":"ym:s:deviceCategory=='\''2'\''"}}' \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/apisegment/segments" | jq .
```

### User Parameters Upload

```bash
# Upload (CSV format)
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  -H "Content-Type: application/x-yametrika+csv" \
  --data-binary @user_params.csv \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/user_params/uploadings?action=update&content_id_type=client_id"

# Confirm upload
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/user_params/uploading/UPLOAD_ID/confirm"
```

content_id_type: `client_id`, `user_id`
action: `update`, `delete_keys`

## 3. Reporting API

### Table Report — /stat/v1/data

```bash
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/stat/v1/data?ids=12345678&metrics=ym:s:visits,ym:s:users,ym:s:bounceRate&dimensions=ym:s:trafficSource&date1=2025-01-01&date2=2025-01-31&limit=100" | jq .
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `ids` | yes | — | Counter IDs (comma-separated) |
| `metrics` | yes | — | Metrics (max 20) |
| `dimensions` | no | — | Dimensions (max 10) |
| `date1` | no | 6daysAgo | Start: YYYY-MM-DD, today, yesterday, NdaysAgo |
| `date2` | no | today | End: same formats |
| `filters` | no | — | Filter expression |
| `limit` | no | 100 | Rows (max 100,000) |
| `offset` | no | 1 | Starting row |
| `sort` | no | — | Sort column (prefix `-` for desc) |
| `accuracy` | no | — | Sample size control |
| `preset` | no | — | Report preset name |

### Time-Series — /stat/v1/data/bytime

Extra params: `group` (day, week, month, quarter, year, hour), `top_keys` (max 30)

### Drilldown — /stat/v1/data/drilldown

Extra params: `parent_id` (JSON array for drill-into)

### Comparison — /stat/v1/data/comparison

Extra params: `date1_a`, `date2_a`, `date1_b`, `date2_b`, `filters_a`, `filters_b`

### CSV Output

Append `.csv` to any endpoint:
```bash
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/stat/v1/data.csv?ids=12345678&metrics=ym:s:visits&limit=10" -o report.csv
```

### All Session Metrics (ym:s:)

| Metric | Description |
|--------|-------------|
| `visits` | Sessions |
| `users` | Unique visitors |
| `pageviews` | Total pageviews |
| `bounceRate` | Bounce rate % |
| `avgPageViews` | Avg pages/session |
| `avgVisitDurationSeconds` | Avg duration (sec) |
| `newUsers` | New visitors |
| `newUsersShare` | New visitor % |
| `hits` | Total hits |
| `robotPercentage` | Robot % |
| `goal<ID>visits` | Sessions with goal |
| `goal<ID>users` | Users reached goal |
| `goal<ID>conversionRate` | Goal conv rate |
| `goal<ID>reaches` | Goal completions |
| `goal<ID>revenue` | Goal revenue |
| `ecommercePurchases` | E-commerce purchases |
| `ecommerceRevenue` | E-commerce revenue |

### All Dimensions

**Traffic:** `trafficSource`, `sourceEngine`, `searchEngine`, `socialNetwork`, `referalSource`, `advEngine`, `<attr>UTMSource`, `<attr>UTMMedium`, `<attr>UTMCampaign`, `<attr>UTMContent`, `<attr>UTMTerm`

**Behavior:** `startURL`, `endURL`, `referer`, `datePeriod<group>`

**Geography:** `regionCountry`, `regionCity`, `regionCountryName`, `regionCityName`

**Technology:** `browser`, `operatingSystem`, `operatingSystemRoot`, `deviceCategory`, `mobilePhone`, `mobilePhoneModel`, `screenResolution`

**Hit-level (ym:pv:):** `URL`, `title`, `referer`

Note: Cannot mix `ym:s:` and `ym:pv:` in one request.

### Parametrization

| Param | Values | Example |
|-------|--------|---------|
| `goal_id` | Goal ID | `ym:s:goal12345visits` |
| `group` | day/week/month/quarter/year | `ym:s:datePeriodday` |
| `attribution` | first/last/lastsign/automatic | `ym:s:lastTrafficSource` |
| `currency` | RUB/USD/EUR | — |

### Filter Syntax

```
=='value'           equals
!='value'           not equals
=.('a','b')         in list
>5                  greater than
=@'text'            contains
!@'text'            not contains
=~'regex'           regex match
expr1 AND expr2     combine with AND/OR
EXISTS dim          exists
```

### Presets

`sources_summary`, `sources_search_phrases`, `tech_platforms`, `publishers_sources`, `publishers_rubrics`, `publishers_authors`, `publishers_thematics`

## 4. Logs API

Raw (non-aggregated) data export. Does NOT support filtering at request level.

### Workflow

1. **Evaluate** → 2. **Create** → 3. **Poll status** → 4. **Download parts** → 5. **Clean**

### Evaluate

```bash
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/logrequests/evaluate?date1=2025-01-01&date2=2025-01-31&source=visits&fields=ym:s:visitID,ym:s:date,ym:s:startURL"
```

### Create

```bash
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/logrequests?date1=2025-01-01&date2=2025-01-31&source=visits&fields=ym:s:visitID,ym:s:date,ym:s:dateTime,ym:s:startURL,ym:s:clientID,ym:s:deviceCategory,ym:s:regionCity,ym:s:goalsID"
```

### Check Status

```bash
curl -s -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/logrequest/777"
```

Status values: `created`, `processed`, `canceled`, `cleaned_by_user`, `cleaned_automatically_as_too_old`, `processing_failed`, `awaiting_retry`

### Download Parts (TSV)

```bash
curl -s -H "Authorization: OAuth $TOKEN" -H "Accept-Encoding: gzip" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/logrequest/777/part/0/download" -o part0.tsv
```

### Clean

```bash
curl -s -X POST -H "Authorization: OAuth $TOKEN" \
  "https://api-metrika.yandex.net/management/v1/counter/12345678/logrequest/777/clean"
```

### Visit Fields (ym:s:)

**Core:** `visitID`, `counterID`, `date`, `dateTime`, `isNewUser`, `startURL`, `endURL`, `pageViews`, `visitDuration`, `bounce`, `ipAddress`, `clientID`

**Goals:** `goalsID`, `goalsSerialNumber`, `goalsDateTime`, `goalsPrice`, `goalsOrder`, `goalsCurrency`

**Geography:** `regionCountry`, `regionCity`, `regionCountryID`, `regionCityID`, `clientTimeZone`

**Traffic:** `<attr>TrafficSource`, `<attr>AdvEngine`, `<attr>SearchEngine`, `<attr>SocialNetwork`, `<attr>ReferalSource`, `referer`

**UTM:** `<attr>UTMSource`, `<attr>UTMMedium`, `<attr>UTMCampaign`, `<attr>UTMContent`, `<attr>UTMTerm`

**Device:** `browser`, `browserMajorVersion`, `deviceCategory`, `mobilePhone`, `mobilePhoneModel`, `operatingSystem`, `operatingSystemRoot`

**Screen:** `screenWidth`, `screenHeight`, `windowClientWidth`, `windowClientHeight`

**E-Commerce:** `purchaseID`, `purchaseRevenue`, `productID`, `productName`, `productBrand`, `productCategory`, `productPrice`, `productQuantity`

**Yandex Direct:** `<attr>DirectClickOrder`, `<attr>DirectBannerGroup`, `<attr>DirectClickBanner`, `<attr>DirectPhraseOrCond`, `<attr>DirectPlatformType`

### Hit Fields (ym:pv:)

**Core:** `watchID`, `clientID`, `date`, `dateTime`, `title`, `URL`, `referer`

**UTM:** `UTMSource`, `UTMMedium`, `UTMCampaign`, `UTMContent`, `UTMTerm`

**Geography:** `ipAddress`, `regionCountry`, `regionCity`

**Device:** `browser`, `operatingSystem`, `deviceCategory`, `mobilePhone`

## 5. Rate Limits

| Limit | Value |
|-------|-------|
| General API | 30 req/sec per IP |
| Logs API | 10 req/sec per IP |
| Parallel requests | 3 per user |
| Daily | 5,000 req/day |
| Reports API | 200 req/5 min |
| HTTP 420 | Quota exceeded |
