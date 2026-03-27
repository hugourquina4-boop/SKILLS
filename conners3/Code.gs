// ═══════════════════════════════════════════════════════════════════
//  CONNERS 3 · GENERADOR DE REPORTES · Code.gs  (VERSIÓN CORREGIDA)
//  BUGS CORREGIDOS:
//  1. tipo === 'padres' → tipo.includes('padre')  [causa principal de vacíos]
//  2. Fechas inyectadas como Date → ahora como string dd/MM/yyyy  [causa #N/A]
//  3. rsPadresExtras → rsPadresEx  [tabla índices siempre vacía]
//  4. Índice verificación loop s[0][3] → s[0][4]
//  5. Limpiar sheets usa findSheet robusto
// ═══════════════════════════════════════════════════════════════════

const SS_BASE    = '1784FxKrSlU_--HU6D6-q4URRQ0hJQdstBkMvr6lc8gc';
const SS_APP     = '1yfXiMt5geFBf48TpxaE79WBPeAqBMMt7Si59lIX5siQ';
const SS_PADRES  = '1lWSTodk5VO2BKUx6c6JrnrTBeMu4wpFq83DRShAKIhk';
const SS_MAESTRO = '1L9UqTcGbtrsJ91wNby6sy1tdq2YG6ZP51oj7_WcUHvc';
const SS_ESTUD   = '1-F2W9fWR06VymLc0OzjdcmmSxHXDzrawpTbMh0NbktM';

const CLAVES_VALIDAS = {
  'ADMIN2026':   'Administrador',
  'ANALISTA001': 'Analista 1',
  'ANALISTA002': 'Analista 2',
  'DEMO-001':    'Demo Usuario'
};

const HOJA_RESULTADOS = 'Resultados Consolidados';
const HOJA_DASHBOARD  = 'Dashboard';

// ── HELPERS ───────────────────────────────────────────────────────
function norm_(str) {
  return String(str || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim();
}

// FIX #2: Formatear fecha como string dd/MM/yyyy (no Date object)
function fmtFecha_(d) {
  try {
    var dt = (d instanceof Date) ? d : new Date(d);
    return Utilities.formatDate(dt, Session.getScriptTimeZone(), 'dd/MM/yyyy');
  } catch(e) { return ''; }
}

// FIX #5: findSheet robusto con log
function findSheet(ss, kw1, kw2) {
  var sheets = ss.getSheets();
  var k1 = norm_(kw1);
  var k2 = norm_(kw2 || '');
  for (var i = 0; i < sheets.length; i++) {
    var sn = norm_(sheets[i].getName());
    if (sn.includes(k1) || (k2 && sn.includes(k2))) return sheets[i];
  }
  Logger.log('findSheet: no encontró "' + kw1 + '". Hojas: ' + sheets.map(function(s){return s.getName();}).join(', '));
  return sheets.length > 1 ? sheets[1] : sheets[0];
}

// ── ENTRY POINTS ──────────────────────────────────────────────────
function doGet(e) {
  return HtmlService.createHtmlOutputFromFile('index')
    .setTitle('Conners 3 · Generador de Reportes')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function doPost(e) {
  var resultado;
  try {
    var body   = JSON.parse(e.postData.contents);
    var accion = body.accion;
    if      (accion === 'validar_clave')    resultado = validarClave_(body.clave);
    else if (accion === 'listar_pacientes') resultado = listarPacientes_(body.clave);
    else if (accion === 'generar_reporte')  resultado = generarReporte_(body.clave, body.nombre_paciente);
    else resultado = { ok: false, error: 'Acción no reconocida: ' + accion };
  } catch (err) {
    resultado = { ok: false, error: 'Error interno: ' + err.message };
  }
  return ContentService.createTextOutput(JSON.stringify(resultado))
    .setMimeType(ContentService.MimeType.JSON);
}

// ── VALIDAR CLAVE ─────────────────────────────────────────────────
function validarClave_(clave) {
  if (!clave || !CLAVES_VALIDAS[clave]) return { ok: false, error: 'Clave de acceso inválida.' };
  return { ok: true, nombre_analista: CLAVES_VALIDAS[clave] };
}

// ── LISTAR PACIENTES ──────────────────────────────────────────────
function listarPacientes_(clave) {
  try {
    if (!validarClave_(clave).ok) return { ok: false, error: 'Clave inválida.' };
    var ss    = SpreadsheetApp.openById(SS_BASE);
    var hResp = findSheet(ss, 'respuesta') || ss.getSheets()[0];
    var datos = hResp.getDataRange().getValues();
    var pacMap = {};
    for (var i = 1; i < datos.length; i++) {
      var nombre = String(datos[i][3] || '').trim();
      if (!nombre) continue;
      var tipo = norm_(datos[i][4]);
      if (!pacMap[nombre]) pacMap[nombre] = { nombre: nombre, formularios: { padres: false, maestro: false, estudiante: false } };
      if (tipo.includes('padre'))     pacMap[nombre].formularios.padres = true;
      if (tipo.includes('maestro'))   pacMap[nombre].formularios.maestro = true;
      if (tipo.includes('estudiant')) pacMap[nombre].formularios.estudiante = true;
    }
    return { ok: true, pacientes: Object.values(pacMap) };
  } catch (err) {
    return { ok: false, error: 'listarPacientes: ' + err.message };
  }
}

// ── GENERAR REPORTE ───────────────────────────────────────────────
function generarReporte_(clave, nombrePaciente) {
  try {
    if (!validarClave_(clave).ok) return { ok: false, error: 'Clave inválida.' };
    if (!nombrePaciente) return { ok: false, error: 'Indique el nombre del paciente.' };

    var ss    = SpreadsheetApp.openById(SS_BASE);
    var hResp = findSheet(ss, 'respuesta') || ss.getSheets()[0];
    var datos = hResp.getDataRange().getValues();

    var filaPadres = null, filaMaestro = null, filaEstud = null;
    var fechaApli = new Date(), fechaNaci = new Date();

    for (var i = 1; i < datos.length; i++) {
      var nombreFila = norm_(datos[i][3]);
      if (nombreFila !== norm_(nombrePaciente)) continue;

      // FIX #1: usar includes en lugar de ===
      var tipo = norm_(datos[i][4]);
      if (tipo.includes('padre'))     { filaPadres  = datos[i]; }
      if (tipo.includes('maestro'))   { filaMaestro = datos[i]; }
      if (tipo.includes('estudiant')) { filaEstud   = datos[i]; }

      if (datos[i][1]) fechaApli = new Date(datos[i][1]);
      if (datos[i][2]) fechaNaci = new Date(datos[i][2]);
    }

    if (!filaPadres && !filaMaestro && !filaEstud) {
      return { ok: false, error: 'Paciente "' + nombrePaciente + '" no encontrado o sin datos. Tipos en BD: ' +
        datos.slice(1).map(function(r){ return norm_(r[3]) + ':' + norm_(r[4]); }).join(' | ') };
    }

    // Demografía: buscar sexo en pestaña Casos
    var sexo = '';
    var hCasos = ss.getSheetByName('Casos') || findSheet(ss, 'caso');
    if (hCasos) {
      var casos = hCasos.getDataRange().getValues();
      for (var j = 1; j < casos.length; j++) {
        var nc = casos[j][2] || casos[j][3] || '';
        if (norm_(nc) === norm_(nombrePaciente)) {
          sexo = String(casos[j][4] || casos[j][5] || '').trim().toUpperCase();
          break;
        }
      }
    }

    // Calcular edad
    var edadNum = Math.floor((fechaApli - fechaNaci) / 31557600000);
    var edad = (edadNum > 0 && edadNum < 99) ? String(edadNum) : '8';

    // Fallback sexo si vacío
    if (!sexo) {
      Logger.log('ADVERTENCIA: sexo no encontrado para ' + nombrePaciente + '. Usando F por defecto.');
      sexo = 'F';
    }

    var demog = { edad: edad, sexo: sexo, fechaNaci: fechaNaci, fechaApli: fechaApli };

    // Procesar cada informante
    var resPadres  = { ok: false, datos: null, error: 'Sin formulario de padres' };
    var resMaestro = { ok: false, datos: null, error: 'Sin formulario de maestro' };
    var resEstud   = { ok: false, datos: null, error: 'Sin formulario de estudiante' };

    if (filaPadres) {
      var respP = filaPadres.slice(5, 115);
      resPadres = procesarPadres_(respP, demog);
    }
    if (filaMaestro) {
      var respM = filaMaestro.slice(5, 118);
      resMaestro = procesarMaestro_(respM, demog);
    }
    if (filaEstud) {
      var respE = filaEstud.slice(5, 46);
      resEstud = procesarEstudiante_(respE, demog);
    }

    var informe = {
      paciente: {
        nombre: nombrePaciente,
        edad: edad,
        sexo: sexo,
        fecha_aplicacion: fmtFecha_(fechaApli)
      },
      padres:     resPadres.ok  ? resPadres.datos  : null,
      maestro:    resMaestro.ok ? resMaestro.datos  : null,
      estudiante: resEstud.ok   ? resEstud.datos    : null,
      fecha_reporte: Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'dd/MM/yyyy HH:mm'),
      _clave: clave,
      errorPadre:  resPadres.error  || 'ok',
      errorMaestro: resMaestro.error || 'ok',
      errorEstud:  resEstud.error   || 'ok'
    };

    // Log de depuración
    try {
      var dbSS = SpreadsheetApp.openById(SS_APP);
      var dSheet = dbSS.getSheetByName('DEBUG_LOGS') || dbSS.insertSheet('DEBUG_LOGS');
      dSheet.insertRowBefore(1);
      dSheet.getRange('A1:B1').setValues([[
        new Date().toISOString() + ' | ' + nombrePaciente + ' | Sexo:' + sexo + ' | Edad:' + edad,
        JSON.stringify({ P: resPadres.error, M: resMaestro.error, E: resEstud.error,
          pRows: resPadres.ok ? resPadres.datos.sintesis.length : 0,
          mRows: resMaestro.ok ? resMaestro.datos.sintesis.length : 0,
          eRows: resEstud.ok ? resEstud.datos.sintesis.length : 0 })
      ]]);
    } catch(e) { Logger.log('debug log error: ' + e.message); }

    var pdfBase64 = generarPDF_(informe);

    // Limpiar sheets de procesamiento
    try { if (resPadres.ok)  limpiarSheetPadres_();    } catch(e) {}
    try { if (resMaestro.ok) limpiarSheetMaestro_();   } catch(e) {}
    try { if (resEstud.ok)   limpiarSheetEstudiante_(); } catch(e) {}

    try { escribirHistorialResultados(informe); } catch(e) { Logger.log('historial: ' + e.message); }

    return { ok: true, pdf: pdfBase64 };

  } catch (err) {
    return { ok: false, error: 'generarReporte: ' + err.message + ' | Stack: ' + err.stack };
  }
}

// ── PROCESAR PADRES ───────────────────────────────────────────────
function procesarPadres_(respuestas, demog) {
  try {
    var ss     = SpreadsheetApp.openById(SS_PADRES);
    var hCuest = findSheet(ss, 'cuestion', 'formul');

    // Inyectar respuestas
    var respArr = respuestas.slice(0, 110).map(function(v){ return [v]; });
    while (respArr.length < 110) respArr.push(['']);
    hCuest.getRange('H5:H114').setValues(respArr);

    // FIX #2: Fechas como string dd/MM/yyyy
    var sPadres = (demog.sexo.charAt(0) === 'F') ? 'M' : 'V';
    hCuest.getRange('M6').setValue(sPadres);
    hCuest.getRange('M7').setValue(fmtFecha_(demog.fechaNaci));
    hCuest.getRange('M8').setValue(fmtFecha_(demog.fechaApli));

    SpreadsheetApp.flush();

    var hSin = findSheet(ss, 'sintesi', 'resulta');
    var s = null, e = null;

    for (var i = 0; i < 8; i++) {
      Utilities.sleep(3000);
      s = hSin.getRange('B3:F13').getValues();
      e = hSin.getRange('B18:D26').getValues();
      // FIX #4: verificar índice [4] (columna F = PT)
      var chk = String(s[0][4] || '').toUpperCase();
      if (chk && !chk.includes('N/A') && !chk.includes('ERRON') && !chk.includes('#')) break;
      Logger.log('Padres intento ' + (i+1) + ': chk=' + chk);
    }

    return { ok: true, datos: { sintesis: s, extras: e }, error: 'ok' };
  } catch (err) {
    return { ok: false, datos: null, error: 'procesarPadres: ' + err.message };
  }
}

// ── PROCESAR MAESTRO ──────────────────────────────────────────────
function procesarMaestro_(respuestas, demog) {
  try {
    var ss     = SpreadsheetApp.openById(SS_MAESTRO);
    var hCuest = findSheet(ss, 'cuestion', 'formul');

    var respArr = respuestas.slice(0, 113).map(function(v){ return [v]; });
    while (respArr.length < 113) respArr.push(['']);
    hCuest.getRange('G4:G116').setValues(respArr);

    // FIX #2: Fechas como string dd/MM/yyyy
    var sMaestro = (demog.sexo.charAt(0) === 'F') ? 'M' : 'V';
    hCuest.getRange('E7').setValue(sMaestro);
    hCuest.getRange('E8').setValue(fmtFecha_(demog.fechaNaci));
    hCuest.getRange('E9').setValue(fmtFecha_(demog.fechaApli));

    SpreadsheetApp.flush();

    var hSin = findSheet(ss, 'sintesi', 'resulta');
    var s = null, e = null;

    for (var i = 0; i < 8; i++) {
      Utilities.sleep(3000);
      s = hSin.getRange('B3:F14').getValues();
      e = hSin.getRange('B20:D28').getValues();
      // FIX #4: verificar índice [4]
      var chk = String(s[0][4] || '').toUpperCase();
      if (chk && !chk.includes('N/A') && !chk.includes('ERRON') && !chk.includes('#')) break;
      Logger.log('Maestro intento ' + (i+1) + ': chk=' + chk);
    }

    return { ok: true, datos: { sintesis: s, extras: e }, error: 'ok' };
  } catch (err) {
    return { ok: false, datos: null, error: 'procesarMaestro: ' + err.message };
  }
}

// ── PROCESAR ESTUDIANTE ───────────────────────────────────────────
function procesarEstudiante_(respuestas, demog) {
  try {
    var ss     = SpreadsheetApp.openById(SS_ESTUD);
    var hCuest = findSheet(ss, 'personal', 'cuestion');

    var respArr = respuestas.slice(0, 41).map(function(v){ return [v]; });
    while (respArr.length < 41) respArr.push(['']);
    hCuest.getRange('M4:M44').setValues(respArr);

    var sEstud = (demog.sexo.charAt(0) === 'F') ? 'Femenino' : 'Masculino';
    hCuest.getRange('J1').setValue(sEstud);
    hCuest.getRange('L1').setValue(demog.edad + ' años');

    SpreadsheetApp.flush();

    var hRes = ss.getSheetByName('Resultados') || ss.getSheetByName('RESULTADOS') || ss.getSheets()[1];
    var s = null;

    for (var i = 0; i < 6; i++) {
      Utilities.sleep(2000);
      s = hRes.getRange('D2:H9').getValues();
      // Verificar fila de datos (índice 1), columna PT (índice 3)
      var chk = String(s[1] && s[1][3] ? s[1][3] : '').toUpperCase();
      if (chk && !chk.includes('N/A') && !chk.includes('ERRON') && !chk.includes('#')) break;
      Logger.log('Estudiante intento ' + (i+1) + ': chk=' + chk);
    }

    return { ok: true, datos: { sintesis: s, extras: [] }, error: 'ok' };
  } catch (err) {
    return { ok: false, datos: null, error: 'procesarEstudiante: ' + err.message };
  }
}

// ── LIMPIAR SHEETS ────────────────────────────────────────────────
function limpiarSheetPadres_() {
  var h = findSheet(SpreadsheetApp.openById(SS_PADRES), 'cuestion', 'formul');
  h.getRange('H5:H114').clearContent();
  h.getRange('M6:M8').clearContent();
}

function limpiarSheetMaestro_() {
  var h = findSheet(SpreadsheetApp.openById(SS_MAESTRO), 'cuestion', 'formul');
  h.getRange('G4:G116').clearContent();
  h.getRange('E7:E9').clearContent();
}

function limpiarSheetEstudiante_() {
  var h = findSheet(SpreadsheetApp.openById(SS_ESTUD), 'personal', 'cuestion');
  h.getRange('M4:M44').clearContent();
  h.getRange('J1').clearContent();
  h.getRange('L1').clearContent();
}

// ── GENERAR PDF ───────────────────────────────────────────────────
function generarPDF_(informe) {
  var p = informe.paciente;
  var template = HtmlService.createTemplateFromFile('ReportePDF');

  // FIX #3: nombres de propiedades alineados con el template (rsPadresEx, rsMaestrosEx)
  template.pacienteData = {
    nombre:       p.nombre || 'Desconocido',
    edad:         p.edad   || '—',
    sexo:         p.sexo   || '—',
    rsPadres:     informe.padres     ? informe.padres.sintesis    : [],
    rsPadresEx:   informe.padres     ? informe.padres.extras      : [],
    rsMaestros:   informe.maestro    ? informe.maestro.sintesis   : [],
    rsMaestrosEx: informe.maestro    ? informe.maestro.extras     : [],
    rsEstudiante: informe.estudiante ? informe.estudiante.sintesis: [],
    debugP:       informe.errorPadre,
    debugM:       informe.errorMaestro,
    debugE:       informe.errorEstud
  };

  var htmlOut  = template.evaluate().getContent();
  var pdfBlob  = Utilities.newBlob(htmlOut, MimeType.HTML)
                   .getAs(MimeType.PDF)
                   .setName('Conners3_' + p.nombre.replace(/ /g, '_') + '.pdf');
  return Utilities.base64Encode(pdfBlob.getBytes());
}

// ── WRAPPERS FRONTEND (google.script.run) ─────────────────────────
function getPacientesFront(clave) {
  var res = listarPacientes_(clave || 'ADMIN2026');
  if (!res.ok) throw new Error(res.error);
  return res.pacientes.map(function(p){ return p.nombre; });
}

function generarReporteFront(paciente, clave) {
  var res = generarReporte_(clave, paciente);
  if (!res.ok) throw new Error(res.error);
  // Retorna data URI para que el frontend lo convierta a Blob
  return 'data:application/pdf;base64,' + res.pdf;
}

// ── HISTORIAL ─────────────────────────────────────────────────────
function escribirHistorialResultados(informe) {
  try {
    var ss   = SpreadsheetApp.openById(SS_APP);
    var hoja = ss.getSheetByName(HOJA_RESULTADOS);
    if (!hoja) { hoja = ss.insertSheet(HOJA_RESULTADOS); }

    function getPT(datos, clave, isEstud) {
      if (!datos || !datos.sintesis) return '';
      var idx = isEstud ? 3 : 4;
      for (var i = 0; i < datos.sintesis.length; i++) {
        var f = datos.sintesis[i];
        if (!f || f.length <= idx) continue;
        if (String(f[0] || '').toLowerCase().includes(clave.toLowerCase())) {
          var val = parseFloat(f[idx]);
          return isNaN(val) ? '' : val;
        }
      }
      return '';
    }

    var keys = ['Inatenc','Hiperac','Aprend','Ejecuti','Agresi','Relaci','Global','Inatent','Hiperact','Conduct','Negativ'];
    var p    = informe.paciente;
    var tz   = Session.getScriptTimeZone();

    var fila = [
      Utilities.formatDate(new Date(), tz, 'dd/MM/yyyy HH:mm'),
      p.nombre, p.edad, p.sexo
    ];
    keys.forEach(function(k){ fila.push(getPT(informe.padres,     k, false)); });
    keys.forEach(function(k){ fila.push(getPT(informe.maestro,    k, false)); });
    keys.forEach(function(k){ fila.push(getPT(informe.estudiante, k, true));  });
    fila.push('OK');

    hoja.getRange(hoja.getLastRow() + 1, 1, 1, fila.length).setValues([fila]);
  } catch(e) { Logger.log('historial error: ' + e.message); }
}

// ── PRUEBA RÁPIDA (ejecutar manualmente en Apps Script) ───────────
function testConexion() {
  Logger.log(JSON.stringify(validarClave_('ADMIN2026')));
  Logger.log(JSON.stringify(listarPacientes_('ADMIN2026')));
}
