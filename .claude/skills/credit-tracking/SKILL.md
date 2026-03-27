---
name: "Credit Tracking & Precision Monitor"
description: "Monitorea los creditos restantes de la API de Anthropic y detecta cuando el codigo pierde precision o falla en la gestion de datos y procesos."
version: "1.0.0"
category: "monitoring"
tags: ["credits", "api-usage", "precision", "data-quality", "alerts"]
---

# Credit Tracking & Precision Monitor

## Que hace este skill

- **Creditos restantes**: Consulta el uso de tokens/creditos de la API de Anthropic en tiempo real
- **Alerta de agotamiento**: Avisa cuando los creditos bajan del umbral configurado (default: 20%)
- **Deteccion de perdida de precision**: Mide la tasa de errores en respuestas del modelo para detectar degradacion
- **Fallos en datos/procesos**: Registra y alerta cuando pipelines de datos o procesos automatizados fallan
- **Historial de uso**: Guarda un log local de consumo por sesion y por dia

---

## Inicio rapido

```bash
# Ver estado actual de creditos
bash .claude/helpers/credit-tracker.sh status

# Ver resumen del dia
bash .claude/helpers/credit-tracker.sh daily

# Activar modo vigilancia (monitoreo continuo cada 5 min)
bash .claude/helpers/credit-tracker.sh watch 300

# Ver historial de precision
bash .claude/helpers/credit-tracker.sh precision
```

---

## Guia completa

### 1. Estado de creditos

Muestra los creditos disponibles y el consumo de la sesion actual.

```bash
# Estado basico
bash .claude/helpers/credit-tracker.sh status

# Ejemplo de salida:
# ==========================================
# CREDITOS API - Estado actual
# ==========================================
# Tokens usados hoy    :  48,320
# Limite diario        : 500,000
# Restante             : 451,680 (90.3%)
# Estado               : OK
# Umbral de alerta     : 20% (100,000 tokens)
# ==========================================
```

### 2. Historial diario

```bash
bash .claude/helpers/credit-tracker.sh daily

# Salida:
# Fecha        Tokens    Costo est.  Estado
# 2026-03-27   48,320    $0.14       OK
# 2026-03-26   122,400   $0.37       OK
# 2026-03-25   489,200   $1.47       ALERTA
```

### 3. Monitor de precision

Detecta cuando el modelo empieza a dar respuestas menos precisas o incorrectas.

**Metricas de precision:**
- **Tasa de error de datos**: % de respuestas con datos incorrectos detectados
- **Fallos de proceso**: Numero de pipelines/workflows que fallaron
- **Score de confianza**: Promedio del nivel de confianza reportado por el modelo

```bash
# Ver metricas de precision actuales
bash .claude/helpers/credit-tracker.sh precision

# Salida:
# ==========================================
# MONITOR DE PRECISION
# ==========================================
# Score de confianza   : 0.94  OK
# Tasa de error        : 2.1%  OK
# Fallos de proceso    : 0     OK
# Ultimo fallo         : ninguno
# ==========================================

# Registrar un fallo de proceso manualmente
bash .claude/helpers/credit-tracker.sh log-failure "Pipeline WhatsApp" "Error: timeout en Google Calendar API"
```

### 4. Umbrales configurables

```bash
# Cambiar umbral de alerta de creditos (porcentaje)
bash .claude/helpers/credit-tracker.sh set-threshold credits 15

# Cambiar umbral de precision (0.0-1.0)
bash .claude/helpers/credit-tracker.sh set-threshold precision 0.90

# Ver configuracion actual
bash .claude/helpers/credit-tracker.sh config
```

### 5. Integracion con hooks de Claude Code

Agrega en `.claude/settings.json` para monitoreo automatico en cada sesion:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/helpers/credit-tracker.sh check-alert"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/helpers/credit-tracker.sh log-session"
          }
        ]
      }
    ]
  }
}
```

### 6. Interpretacion de alertas

| Estado | Significado | Accion recomendada |
|--------|------------|--------------------|
| `OK` | Creditos y precision normales | Ninguna |
| `ALERTA` | Creditos < 20% o precision < 0.90 | Revisar consumo |
| `CRITICO` | Creditos < 5% o precision < 0.75 | Pausar operaciones |
| `FALLO` | Pipeline/proceso fallo | Ver log de fallos |

### 7. Archivo de log

El tracker guarda logs en `.claude-flow/credit-tracking/`:

```
.claude-flow/
  credit-tracking/
    daily-usage.json       # Uso acumulado por dia
    session-log.jsonl      # Log de cada sesion (JSONL)
    precision-log.jsonl    # Registro de metricas de precision
    failures.jsonl         # Registro de fallos de proceso
    config.json            # Configuracion de umbrales
```

### 8. Exportar reporte

```bash
# Exportar reporte de la semana en JSON
bash .claude/helpers/credit-tracker.sh report --period 7d --format json

# Exportar en markdown
bash .claude/helpers/credit-tracker.sh report --period 30d --format markdown
```

---

## Costos estimados (referencia rapida)

| Modelo | Costo por 1M tokens input | Costo por 1M tokens output |
|--------|--------------------------|---------------------------|
| claude-sonnet-4-6 | $3.00 | $15.00 |
| claude-haiku-4-5 | $0.80 | $4.00 |
| claude-opus-4-6 | $15.00 | $75.00 |

---

## Buenas practicas

1. **Activa el hook SessionStart** para recibir alerta si los creditos estan bajos al inicio de cada sesion
2. **Usa umbrales conservadores** (20-25%) para el SaaS de WhatsApp — los clientes dependen de disponibilidad 24/7
3. **Registra fallos de proceso** con `log-failure` cada vez que un pipeline (Google Calendar, WhatsApp, Stripe) falle
4. **Revisa `precision-log` semanalmente** para detectar degradacion gradual antes de que afecte a clientes
5. **Integra con alertas en Slack/email** via el flag `--notify` del comando `watch`
