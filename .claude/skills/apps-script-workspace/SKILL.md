# Skill: Google Apps Script + Workspace (GRATIS, codigo protegido)

## Por que Apps Script es perfecto para ti
- **100% GRATIS** — corre en servidores de Google sin costo
- **Codigo oculto** — los usuarios solo ven la interfaz, NUNCA el codigo
- **Sin servidor propio** — Google maneja todo
- **Integrado con** Google Sheets, Forms, Docs, Gmail, Calendar, Drive
- **Publicable como app web** — URL publica que cualquiera puede usar
- **Sin problemas de compatibilidad** — funciona en cualquier dispositivo con navegador

## Cuando usar este skill
- Usuario quiere crear formularios con logica avanzada
- Usuario necesita guardar datos en Google Sheets sin que el cliente vea el codigo
- Usuario quiere automatizar procesos en Google Workspace
- Usuario necesita generar PDFs o reportes desde datos
- Usuario quiere una app web gratis sin pagar hosting

## Arquitectura del sistema GRATIS

```
Usuario (celular/PC/Mac/iPhone)
         ↓ (URL publica)
  Apps Script Web App
  [codigo 100% oculto]
         ↓
  Google Sheets (base de datos)
         ↓
  Google Drive (archivos/PDFs)
         ↓
  Gmail (notificaciones)
```

## Estructura de un proyecto Apps Script tipico

```
mi-proyecto/
├── appsscript.json          ← configuracion del proyecto
├── Code.gs                  ← logica principal (servidor, oculto)
├── Formulario.html          ← interfaz del usuario (frontend)
├── Estilos.html             ← CSS
└── Utils.gs                 ← funciones utiles
```

## Comandos clasp (desarrollo local con Claude Code)

```bash
# Autenticarse con Google
clasp login

# Crear nuevo proyecto
clasp create --title "Mi App" --type webapp

# Subir cambios a Google
clasp push

# Abrir en el editor de Google
clasp open

# Desplegar como app web
clasp deploy --description "Version 1.0"

# Ver deployments activos
clasp deployments

# Bajar cambios desde Google
clasp pull
```

## Plantilla base: App Web con formulario

### appsscript.json
```json
{
  "timeZone": "America/Bogota",
  "dependencies": {},
  "exceptionLogging": "STACKDRIVER",
  "runtimeVersion": "V8",
  "webapp": {
    "executeAs": "USER_DEPLOYING",
    "access": "ANYONE_ANONYMOUS"
  }
}
```

### Code.gs (servidor — NUNCA lo ve el usuario)
```javascript
// Punto de entrada de la app web
function doGet(e) {
  return HtmlService.createTemplateFromFile('Formulario')
    .evaluate()
    .setTitle('Mi Formulario')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

// Recibir datos del formulario
function guardarRespuesta(datos) {
  const hoja = SpreadsheetApp.openById('ID_DE_TU_SHEET').getSheetByName('Respuestas');

  hoja.appendRow([
    new Date(),
    datos.nombre,
    datos.email,
    datos.respuesta,
    Session.getActiveUser().getEmail() || 'Anonimo'
  ]);

  // Enviar confirmacion por email
  if (datos.email) {
    GmailApp.sendEmail(
      datos.email,
      'Confirmacion de tu respuesta',
      `Hola ${datos.nombre}, recibimos tu respuesta correctamente.`
    );
  }

  return { exito: true, mensaje: 'Respuesta guardada correctamente' };
}

// Incluir archivos HTML (para CSS y JS separados)
function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
```

### Formulario.html (lo que VE el usuario)
```html
<!DOCTYPE html>
<html>
<head>
  <base target="_top">
  <?!= include('Estilos'); ?>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <div class="contenedor">
    <h1>Mi Formulario</h1>

    <form id="miFormulario">
      <label>Nombre completo</label>
      <input type="text" id="nombre" required>

      <label>Email</label>
      <input type="email" id="email" required>

      <label>Tu respuesta</label>
      <textarea id="respuesta" rows="5" required></textarea>

      <button type="submit" id="btnEnviar">Enviar</button>
    </form>

    <div id="mensaje" style="display:none"></div>
  </div>

  <script>
    document.getElementById('miFormulario').addEventListener('submit', function(e) {
      e.preventDefault();

      const btn = document.getElementById('btnEnviar');
      btn.disabled = true;
      btn.textContent = 'Enviando...';

      const datos = {
        nombre: document.getElementById('nombre').value,
        email: document.getElementById('email').value,
        respuesta: document.getElementById('respuesta').value
      };

      // Llamar al servidor (Code.gs) — el usuario no puede ver este codigo
      google.script.run
        .withSuccessHandler(function(resultado) {
          document.getElementById('miFormulario').style.display = 'none';
          document.getElementById('mensaje').style.display = 'block';
          document.getElementById('mensaje').innerHTML =
            '<h2>✅ ' + resultado.mensaje + '</h2>';
        })
        .withFailureHandler(function(error) {
          btn.disabled = false;
          btn.textContent = 'Enviar';
          alert('Error: ' + error.message);
        })
        .guardarRespuesta(datos);
    });
  </script>
</body>
</html>
```

## Generacion de PDF desde Apps Script (GRATIS)

```javascript
function generarPDFReporte(datos) {
  // Crear Google Doc con los datos
  const doc = DocumentApp.create('Reporte_' + datos.nombre);
  const body = doc.getBody();

  body.appendParagraph('REPORTE').setHeading(DocumentApp.ParagraphHeading.HEADING1);
  body.appendParagraph('Fecha: ' + new Date().toLocaleDateString());
  body.appendParagraph('Nombre: ' + datos.nombre);
  // ... agregar mas datos

  doc.saveAndClose();

  // Convertir a PDF
  const pdfBlob = DriveApp.getFileById(doc.getId()).getAs('application/pdf');

  // Guardar PDF en Drive
  const carpeta = DriveApp.getFolderById('ID_CARPETA_DRIVE');
  const archivoPDF = carpeta.createFile(pdfBlob);
  archivoPDF.setName('Reporte_' + datos.nombre + '.pdf');

  // Eliminar el Doc temporal
  DriveApp.getFileById(doc.getId()).setTrashed(true);

  // Retornar URL del PDF
  return archivoPDF.getUrl();
}
```

## Graficos y analisis visual (GRATIS con Google Charts)

```javascript
// En el HTML del usuario — Google Charts es completamente gratis
function cargarGrafico() {
  const datos = obtenerDatosDeSheet(); // funcion en Code.gs

  // Google Charts
  google.charts.load('current', {packages: ['corechart', 'bar', 'table']});
  google.charts.setOnLoadCallback(function() {
    const dataTable = new google.visualization.DataTable();
    dataTable.addColumn('string', 'Categoria');
    dataTable.addColumn('number', 'Valor');
    dataTable.addRows(datos);

    // Pie chart
    new google.visualization.PieChart(document.getElementById('grafico'))
      .draw(dataTable, {title: 'Mi Analisis', width: 500, height: 400});
  });
}
```

## Alternativas GRATIS a Tableau para tus dashboards

| Herramienta | Costo | Para que |
|------------|-------|----------|
| **Google Looker Studio** | GRATIS | Dashboards profesionales conectados a Sheets |
| **Google Charts** | GRATIS | Graficos dentro de Apps Script |
| **ApexCharts** | GRATIS | Graficos interactivos en tus paginas web |
| **Chart.js** | GRATIS | Graficos simples y bonitos |

## Hosting GRATIS sin pagar nada

| Opcion | Costo | Limite | Ideal para |
|--------|-------|--------|-----------|
| **Apps Script Web App** | GRATIS | 20k usuarios/dia | Formularios y apps internas |
| **GitHub Pages** | GRATIS | Ilimitado | Paginas estaticas/portfolio |
| **Vercel Free** | GRATIS | 100GB/mes | Apps React/Next.js |
| **Netlify Free** | GRATIS | 100GB/mes | Sites estaticos |
| **Firebase Hosting** | GRATIS | 10GB | Apps web completas |

## Flujo recomendado para tus proyectos de psicologia

```
1. Formulario de admision → Apps Script Web App (gratis, oculto)
2. Respuestas → Google Sheets (base de datos gratis)
3. Analisis → Google Looker Studio (dashboards gratis)
4. Reportes → PDF generado por Apps Script (gratis)
5. Notificaciones → Gmail via Apps Script (gratis)
6. Todo desde celular, PC, Mac, iPhone sin instalar nada
```
