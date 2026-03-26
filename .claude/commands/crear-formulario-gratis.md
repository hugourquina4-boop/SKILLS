# Comando: /crear-formulario-gratis

## Descripcion
Crea un formulario web completo usando Google Apps Script.
Gratis, codigo oculto, funciona en cualquier dispositivo (celular/PC/Mac/iPhone).

## Uso
```
/crear-formulario-gratis --tipo [admision|evaluacion|sesion|encuesta|contacto] --nombre "Nombre del formulario"
```

## Que genera este comando
1. Codigo completo de Apps Script (Code.gs + HTML)
2. Instrucciones paso a paso para publicarlo en 10 minutos
3. Estructura de Google Sheets para guardar los datos
4. (Opcional) Generacion automatica de PDF al enviar
5. (Opcional) Email de confirmacion al usuario

## Instrucciones para Claude

### PASO 1 — Preguntar al usuario
- Tipo de formulario (admision, evaluacion psicologica, registro de sesion, encuesta, contacto)
- Campos que necesita
- Necesita email de confirmacion? (Si/No)
- Necesita generar PDF automaticamente? (Si/No)
- Quiere graficos de los resultados? (Si/No)
- Tiene Google Sheets ya creado o lo crea nuevo?

### PASO 2 — Generar el proyecto completo

Crear todos los archivos listos para usar con clasp:

**appsscript.json** — configuracion con zona horaria correcta
**Code.gs** — logica completa del servidor (protegida)
**Formulario.html** — interfaz del usuario (diseno profesional con CSS)

### PASO 3 — Instrucciones de publicacion (10 minutos)

```
1. Ir a script.google.com
2. Nuevo proyecto → pegar el codigo
3. Guardar con nombre
4. Desplegar → Nueva implementacion → Aplicacion web
5. Ejecutar como: "Yo" (tu cuenta Google)
6. Quien tiene acceso: "Cualquier persona" (para formularios publicos)
   o "Cualquier persona con cuenta Google" (para formularios privados)
7. Copiar la URL → compartir con tus pacientes/clientes
```

### PASO 4 — Configurar Google Sheets
Crear la hoja de calculo con las columnas correctas y proteger
las hojas sensibles con contrasena.

### PASO 5 — (Opcional) Conectar a Google Looker Studio
Para crear dashboards visuales gratis de los datos recolectados.
Instrucciones paso a paso.

## Ejemplo de lo que el usuario PUEDE hacer con la URL generada
- Compartir por WhatsApp a sus pacientes
- Poner en su sitio web como iframe
- Enviar por email
- Crear codigo QR para imprimir
- Funciona en iPhone, Android, Mac, Windows sin instalar nada

## Seguridad y privacidad
- El codigo esta en servidores de Google, NADIE puede verlo
- Los datos van directo a tu Google Sheets (solo tu tienes acceso)
- Puedes proteger hojas con contrasena
- Puedes restringir el formulario a emails especificos
- Google cumple con GDPR y estandares de privacidad internacionales
