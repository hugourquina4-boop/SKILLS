# Comando: /deploy-negocio-whatsapp

## Descripcion
Despliega un agente de WhatsApp completo para un nuevo negocio (peluqueria, odontologia, abogado u otro). Genera toda la estructura del proyecto lista para produccion.

## Uso
```
/deploy-negocio-whatsapp --tipo [peluqueria|odontologia|abogado|otro] --nombre "Nombre del Negocio"
```

## Que hace este comando
1. Crea la estructura completa del proyecto Next.js
2. Genera el webhook de WhatsApp
3. Configura el agente Claude con el system prompt correcto para el tipo de negocio
4. Crea el schema de base de datos en Supabase
5. Configura las variables de entorno necesarias
6. Prepara el deploy en Vercel

## Instrucciones para Claude

Cuando el usuario ejecute este comando:

### PASO 1 — Recopilar informacion del negocio
Pregunta al usuario:
- Nombre del negocio
- Tipo (peluqueria/barbershop, odontologia/clinica dental, abogado/despacho, otro)
- Nombre del asistente virtual (como se llamara el agente)
- Nombre del dueno o doctor principal
- Servicios principales y precios
- Horarios de atencion
- Numero de WhatsApp Business (si ya tienen)
- Ciudad / pais (para zona horaria)

### PASO 2 — Generar estructura del proyecto
```bash
npx create-next-app@latest {nombre-negocio-bot} --typescript --tailwind --app --src-dir
cd {nombre-negocio-bot}
npm install @anthropic-ai/sdk @supabase/supabase-js prisma @prisma/client openai stripe zod
npm install -D @types/node
```

### PASO 3 — Crear archivos base

Crear los siguientes archivos con el contenido correcto:

**`src/app/api/whatsapp/webhook/route.ts`** — Webhook principal
**`src/lib/agente.ts`** — Logica del agente Claude
**`src/lib/calendar.ts`** — Integracion Google Calendar
**`src/lib/supabase.ts`** — Cliente Supabase
**`src/lib/whatsapp.ts`** — Funciones de envio WhatsApp
**`prisma/schema.prisma`** — Schema de base de datos
**`.env.example`** — Plantilla de variables de entorno
**`SETUP.md`** — Guia de configuracion paso a paso

### PASO 4 — Personalizar system prompt
Usar el agente correspondiente de `.claude/agents/whatsapp-{tipo}.md`
Reemplazar todas las variables `{VARIABLE}` con los datos reales del negocio

### PASO 5 — Generar SETUP.md
Crear una guia personalizada para que el dueno del negocio pueda:
1. Crear cuenta en 360dialog o Twilio
2. Conectar su numero de WhatsApp Business
3. Configurar Google Calendar
4. Crear proyecto en Supabase
5. Hacer deploy en Vercel
6. Configurar el webhook URL

### PASO 6 — Calcular precio mensual sugerido
Basado en la complejidad, sugerir al usuario un precio para cobrar al negocio:
- Basico (1 numero, hasta 300 conv/mes): $49/mes
- Estandar (1 numero, ilimitado): $89/mes
- Pro (multiples numeros, dashboard): $149/mes

## Resultado esperado
Al finalizar el comando, el usuario tiene:
- Proyecto completo listo para deploy
- Guia de configuracion personalizada
- Estimado de costos operativos mensuales (API, hosting, WhatsApp)
- Precio sugerido para cobrar al cliente
