# Skill: Agente WhatsApp para Negocios (Peluquerias, Abogados, Odontologias)

## Proposito
Construir un agente de WhatsApp completo para cualquier tipo de negocio que:
- Responde preguntas automaticamente (precios, horarios, servicios)
- Gestiona citas y agendas via Google Calendar
- Procesa mensajes de voz (transcripcion + respuesta)
- Envia recordatorios automaticos
- Escala a humano cuando es necesario

## Cuando usar este skill
- El usuario pide "crear un agente de WhatsApp para [negocio]"
- El usuario quiere automatizar respuestas de WhatsApp
- El usuario necesita sistema de citas por mensajeria
- El usuario quiere vender este tipo de aplicacion a negocios

## Arquitectura del Sistema

```
WhatsApp Business API (360dialog / Twilio)
           ↓
     Webhook (Next.js / Express)
           ↓
     Agente Claude (este sistema)
      ↙        ↘
Google Calendar  Base de datos
(citas)         (Airtable / Supabase)
      ↘        ↙
   Respuesta al cliente
           ↓
     WhatsApp mensaje
```

## Stack tecnologico recomendado

### Backend
- **Next.js 14** con App Router (API routes para webhooks)
- **Supabase** (PostgreSQL + Auth + Storage para audios)
- **Prisma** ORM para base de datos

### Integraciones
- **WhatsApp**: 360dialog (mas barato) o Twilio (mas robusto)
- **Calendario**: Google Calendar API
- **IA**: Anthropic Claude API (claude-sonnet-4-6)
- **Voz**: Whisper API para transcripcion de audios
- **Deploy**: Vercel (frontend) + Railway o Render (backend)

### Pagos (para cobrar a tus clientes)
- **Stripe** para suscripciones mensuales por negocio

## Proceso de construccion

### PASO 1: Estructura del proyecto
```bash
npx create-next-app@latest nombre-negocio-bot --typescript --tailwind --app
cd nombre-negocio-bot
npm install @anthropic-ai/sdk @supabase/supabase-js prisma openai stripe
```

### PASO 2: Variables de entorno requeridas
```env
# WhatsApp
WHATSAPP_API_KEY=           # De 360dialog o Twilio
WHATSAPP_PHONE_NUMBER_ID=   # ID del numero de WhatsApp Business
WHATSAPP_WEBHOOK_TOKEN=     # Token para verificar webhook

# IA
ANTHROPIC_API_KEY=          # Claude API key

# Base de datos
DATABASE_URL=               # Supabase PostgreSQL URL
SUPABASE_URL=
SUPABASE_ANON_KEY=

# Google Calendar
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REFRESH_TOKEN=

# Pagos
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
```

### PASO 3: Schema de base de datos
```sql
-- Negocios (tus clientes)
CREATE TABLE negocios (
  id UUID PRIMARY KEY,
  nombre TEXT NOT NULL,
  tipo TEXT NOT NULL,          -- 'peluqueria' | 'abogado' | 'odontologia'
  whatsapp_numero TEXT,
  google_calendar_id TEXT,
  configuracion JSONB,         -- horarios, servicios, precios
  activo BOOLEAN DEFAULT true,
  plan TEXT DEFAULT 'basico',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Clientes de cada negocio
CREATE TABLE clientes (
  id UUID PRIMARY KEY,
  negocio_id UUID REFERENCES negocios(id),
  whatsapp TEXT NOT NULL,
  nombre TEXT,
  historial_citas JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Citas
CREATE TABLE citas (
  id UUID PRIMARY KEY,
  negocio_id UUID REFERENCES negocios(id),
  cliente_id UUID REFERENCES clientes(id),
  servicio TEXT NOT NULL,
  fecha_hora TIMESTAMPTZ NOT NULL,
  estado TEXT DEFAULT 'pendiente',  -- 'confirmada' | 'cancelada' | 'completada'
  google_event_id TEXT,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversaciones
CREATE TABLE conversaciones (
  id UUID PRIMARY KEY,
  negocio_id UUID REFERENCES negocios(id),
  cliente_whatsapp TEXT NOT NULL,
  mensajes JSONB DEFAULT '[]',
  estado TEXT DEFAULT 'activa',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### PASO 4: Webhook de WhatsApp
```typescript
// app/api/whatsapp/webhook/route.ts
import { NextRequest, NextResponse } from 'next/server'
import Anthropic from '@anthropic-ai/sdk'

const anthropic = new Anthropic()

export async function POST(req: NextRequest) {
  const body = await req.json()

  // Extraer mensaje
  const message = body.entry?.[0]?.changes?.[0]?.value?.messages?.[0]
  if (!message) return NextResponse.json({ status: 'ok' })

  const from = message.from
  const negocioId = req.nextUrl.searchParams.get('negocio_id')

  // Obtener configuracion del negocio
  const negocio = await getNegocio(negocioId)

  // Procesar segun tipo de mensaje
  let textoMensaje = ''
  if (message.type === 'text') {
    textoMensaje = message.text.body
  } else if (message.type === 'audio') {
    // Transcribir audio con Whisper
    textoMensaje = await transcribirAudio(message.audio.id)
  }

  // Llamar al agente Claude
  const respuesta = await agentePrincipal(textoMensaje, from, negocio)

  // Enviar respuesta por WhatsApp
  await enviarWhatsApp(from, respuesta, negocio.whatsapp_api_key)

  return NextResponse.json({ status: 'ok' })
}

// Verificacion del webhook
export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get('hub.verify_token')
  const challenge = req.nextUrl.searchParams.get('hub.challenge')

  if (token === process.env.WHATSAPP_WEBHOOK_TOKEN) {
    return new NextResponse(challenge)
  }
  return new NextResponse('Forbidden', { status: 403 })
}
```

### PASO 5: Agente Claude principal
```typescript
// lib/agente.ts
import Anthropic from '@anthropic-ai/sdk'

const anthropic = new Anthropic()

export async function agentePrincipal(
  mensaje: string,
  clienteWhatsapp: string,
  negocio: any
) {
  const historial = await getHistorialConversacion(clienteWhatsapp, negocio.id)

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    system: generarSystemPrompt(negocio),
    messages: [
      ...historial,
      { role: 'user', content: mensaje }
    ],
    tools: [
      {
        name: 'crear_cita',
        description: 'Crear una cita en el calendario del negocio',
        input_schema: {
          type: 'object',
          properties: {
            servicio: { type: 'string' },
            fecha: { type: 'string', description: 'ISO 8601 format' },
            nombre_cliente: { type: 'string' }
          },
          required: ['servicio', 'fecha', 'nombre_cliente']
        }
      },
      {
        name: 'consultar_disponibilidad',
        description: 'Ver horarios disponibles para una fecha',
        input_schema: {
          type: 'object',
          properties: {
            fecha: { type: 'string' }
          },
          required: ['fecha']
        }
      },
      {
        name: 'cancelar_cita',
        description: 'Cancelar una cita existente',
        input_schema: {
          type: 'object',
          properties: {
            cita_id: { type: 'string' }
          },
          required: ['cita_id']
        }
      }
    ]
  })

  // Procesar uso de herramientas
  if (response.stop_reason === 'tool_use') {
    return await procesarHerramientas(response, mensaje, clienteWhatsapp, negocio)
  }

  const textoRespuesta = response.content
    .filter(b => b.type === 'text')
    .map(b => b.text)
    .join('')

  await guardarMensaje(clienteWhatsapp, negocio.id, mensaje, textoRespuesta)
  return textoRespuesta
}
```

### PASO 6: System prompts por tipo de negocio
Ver archivos en `.claude/agents/` para cada tipo de negocio.

## Flujo de venta a negocios

1. **Demo gratuita** (14 dias) — cliente prueba con su numero real
2. **Plan Basico** $49/mes — 1 numero WhatsApp, hasta 500 conversaciones/mes
3. **Plan Pro** $99/mes — 2 numeros, conversaciones ilimitadas, reportes
4. **Plan Enterprise** $199/mes — multiples sucursales, API propia, soporte prioritario

## Comandos utiles

```bash
# Desplegar nuevo negocio
/deploy-negocio --tipo peluqueria --nombre "Peluqueria Don Carlos"

# Ver conversaciones activas
/ver-conversaciones --negocio-id xxx

# Configurar horarios
/configurar-horarios --negocio-id xxx

# Ver metricas
/metricas --negocio-id xxx
```
