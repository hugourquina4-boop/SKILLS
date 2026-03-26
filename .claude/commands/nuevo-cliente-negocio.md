# Comando: /nuevo-cliente-negocio

## Descripcion
Onboarding rapido para agregar un nuevo negocio cliente a tu plataforma SaaS de agentes WhatsApp. Genera el contrato, configura el sistema y prepara la demo.

## Uso
```
/nuevo-cliente-negocio
```

## Que hace
1. Recoge datos del negocio cliente
2. Genera propuesta comercial personalizada
3. Crea configuracion del agente lista para activar
4. Prepara email de bienvenida y guia de onboarding
5. Genera instrucciones para el cliente final

## Instrucciones para Claude

### PASO 1 — Datos del cliente
```
Recopilar:
- Nombre completo del negocio
- Tipo de negocio
- Nombre del contacto (dueno/administrador)
- Numero de WhatsApp actual del negocio
- Cuantos mensajes reciben aproximado por dia
- Tienen Google Calendar? Si/No
- Plan de interes (Basico/Pro/Enterprise)
```

### PASO 2 — Generar propuesta
Crear documento con:
- Descripcion del servicio personalizado para su tipo de negocio
- Beneficios especificos (ej: "Su recepcionista virtual atendera citas 24/7")
- Precio mensual y que incluye
- Periodo de prueba gratuita (14 dias recomendado)
- Proceso de implementacion (tipicamente 48-72 horas)

### PASO 3 — Configuracion tecnica
Generar archivo `config-{nombre-negocio}.json`:
```json
{
  "negocio": {
    "nombre": "",
    "tipo": "",
    "whatsapp": "",
    "zona_horaria": "",
    "idioma": "es"
  },
  "agente": {
    "nombre": "",
    "personalidad": "",
    "servicios": [],
    "horarios": {},
    "escalamiento": {
      "numero": "",
      "condiciones": []
    }
  },
  "integraciones": {
    "google_calendar_id": "",
    "airtable_base_id": "",
    "stripe_customer_id": ""
  },
  "plan": {
    "tipo": "basico|pro|enterprise",
    "precio_mensual": 0,
    "fecha_inicio": "",
    "conversaciones_limite": 0
  }
}
```

### PASO 4 — Email de bienvenida
Generar borrador de email para enviar al cliente con:
- Credenciales de acceso al dashboard
- Video tutorial personalizado (link a Loom)
- Guia de primeros pasos (PDF)
- Contacto de soporte

### PASO 5 — Checklist de activacion
```
[ ] Cuenta WhatsApp Business verificada
[ ] Numero conectado a 360dialog/Twilio
[ ] Google Calendar compartido con el sistema
[ ] System prompt configurado y probado
[ ] Webhook activo y respondiendo
[ ] Primera cita de prueba creada exitosamente
[ ] Cliente capacitado en uso del dashboard
[ ] Pago configurado en Stripe
```

## KPIs a medir en primeras 2 semanas
- Tiempo promedio de respuesta del agente
- % de mensajes respondidos correctamente sin intervencion humana
- Numero de citas agendadas por el agente
- Satisfaccion del dueno del negocio (encuesta dia 7 y dia 14)
