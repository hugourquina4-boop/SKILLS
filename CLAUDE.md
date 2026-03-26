# Mi Sistema Claude Code — Configuracion y Habilidades

## Proposito de este repositorio
Repositorio central de skills, agentes, comandos y configuracion para Claude Code.
Incluye todo lo necesario para construir y vender aplicaciones SaaS de agentes de IA.

---

## Proyecto Principal: SaaS de Agentes WhatsApp para Negocios

### Vision
Plataforma que permite a peluquerias, odontologias, despachos de abogados y otros negocios tener un agente de IA en WhatsApp que:
- Responde preguntas 24/7
- Agenda citas automaticamente
- Procesa mensajes de voz
- Escala a humano cuando es necesario

### Modelo de negocio
```
Tu (desarrollador) → construyes y mantienes la plataforma
Negocios locales   → pagan $49-$199/mes por el servicio
Escalabilidad      → 1 plataforma, muchos clientes
```

### Stack tecnologico
- **Frontend/Backend**: Next.js 14 + TypeScript
- **Base de datos**: Supabase (PostgreSQL)
- **IA**: Claude (claude-sonnet-4-6) via Anthropic API
- **WhatsApp**: 360dialog o Twilio
- **Calendario**: Google Calendar API
- **Voz**: OpenAI Whisper (transcripcion de audios)
- **Pagos**: Stripe
- **Deploy**: Vercel + Railway

---

## Skills instalados

### De obra/superpowers (workflows de desarrollo)
| Skill | Uso |
|-------|-----|
| `superpowers-test-driven-development` | Escribir tests antes de codigo |
| `superpowers-systematic-debugging` | Depuracion estructurada |
| `superpowers-brainstorming` | Explorar ideas y soluciones |
| `superpowers-writing-plans` | Crear planes de implementacion |
| `superpowers-executing-plans` | Ejecutar con subagentes |
| `superpowers-dispatching-parallel-agents` | Lanzar agentes en paralelo |
| `superpowers-subagent-driven-development` | Desarrollo con subagentes |
| `superpowers-requesting-code-review` | Solicitar revision de codigo |
| `superpowers-verification-before-completion` | Verificar antes de terminar |
| `superpowers-using-git-worktrees` | Ramas paralelas |
| `superpowers-writing-skills` | Crear nuevos skills |

### De ruvnet/ruflo (orquestacion multi-agente)
- 98 agentes especializados
- 30 skills de alto nivel
- Swarm intelligence

### Especializados para negocios
| Skill | Uso |
|-------|-----|
| `whatsapp-agent-negocio` | Base para construir agentes WhatsApp |
| `humanizalo` | Humanizar texto generado por IA |
| `ui-ux-pro-max` | Diseno visual de interfaces |

---

## MCP Servers instalados

| Servidor | Para que |
|---------|----------|
| **ruflo** | Orquestacion multi-agente avanzada |
| **remotion** | Crear videos con React (marketing) |
| **expo** | Build y deploy Android/iOS |
| **whatsapp** | Integracion directa con WhatsApp |
| **google-calendar** | Manejo de citas y agendas |
| **gmail** | Envio de emails y notificaciones |
| **airtable** | Base de datos de clientes |
| **make** (integromat) | Automatizacion de flujos |
| **apollo** | Marketing y prospeccion |
| **figma** | Diseno de interfaces |
| **vercel** | Deploy y hosting |

---

## Comandos disponibles

### Para el negocio SaaS
```
/deploy-negocio-whatsapp    → Crea proyecto completo para nuevo negocio
/nuevo-cliente-negocio      → Onboarding de nuevo cliente
```

### Para desarrollo
```
/sparc                      → Metodologia SPARC de desarrollo
/claude-flow-swarm          → Iniciar swarm de agentes
/claude-flow-memory         → Gestionar memoria persistente
```

---

## Agentes especializados

### Para el sistema WhatsApp
- `whatsapp-peluqueria` — Recepcionista virtual de peluquerias
- `whatsapp-odontologia` — Asistente de clinicas dentales
- `whatsapp-abogado` — Asistente de despachos juridicos

### Para formularios de psicologia
Usar Tally MCP + Airtable MCP para crear:
- Formularios de admision de pacientes
- Evaluaciones psicologicas estandarizadas
- Seguimiento de sesiones
- Reportes de progreso

---

## Roadmap del producto

### Fase 1 — MVP (1-2 meses)
- [ ] Un tipo de negocio (empezar con peluquerias)
- [ ] WhatsApp + Google Calendar integrado
- [ ] Dashboard simple para el dueno del negocio
- [ ] Sistema de pagos con Stripe

### Fase 2 — Expansion (3-4 meses)
- [ ] Agregar odontologias y abogados
- [ ] App movil para el dueno (React Native + Expo)
- [ ] Reportes y analiticas
- [ ] Sistema de recordatorios automaticos

### Fase 3 — Scale (5-6 meses)
- [ ] API publica para integraciones
- [ ] Marketplace de templates por industria
- [ ] Programa de afiliados/revendedores
- [ ] Soporte multiidioma

---

## Costos operativos estimados por cliente

| Servicio | Costo mensual |
|---------|--------------|
| Vercel (hosting) | $0-20 |
| Supabase | $0-25 |
| Claude API (1000 conv) | ~$5-15 |
| 360dialog WhatsApp | $25-50 |
| **Total por cliente** | **~$30-110** |
| **Precio al cliente** | **$49-199** |
| **Margen** | **~50-70%** |

---

## Nota sobre RuFlo V3
Este proyecto tambien incluye la configuracion completa de RuFlo V3 con sus 98 agentes,
30 skills especializados y sistema de swarm intelligence para desarrollo avanzado.
