<p align="center">
  <img src="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" width="112" alt="Ícono de Goiás App">
</p>

<h1 align="center">Goiás App</h1>

<p align="center">
  App para la hinchada del Goiás: partidos, contenido del club, medios, entradas, socios y una Arena de minijuegos en un solo lugar.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white" alt="Supabase">
  <img src="https://img.shields.io/badge/Cloudflare_Workers-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare Workers">
  <img src="https://img.shields.io/badge/plataformas-Android_·_iOS_·_Web-555555" alt="Plataformas: Android, iOS y Web">
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.pt-BR.md">Português</a> · <b>Español</b>
</p>

---

Goiás App reúne en una sola app, para la hinchada del Goiás, el calendario de partidos, los resultados en vivo, la historia del club, noticias y redes sociales, entradas, el programa de socios, una tienda y un conjunto de juegos. Es un producto independiente: no es una app oficial y no representa una alianza ni un respaldo del Goiás Esporte Clube.

Técnicamente, la app está construida sobre **Fan Hub**, una base multiclub: un único código Flutter que genera un build separado para cada club, cada uno con su propio backend.

## Disponibilidad

- **Android**, **iOS** y **Web (PWA instalable)**, desde un único código en Flutter.
- **Idiomas**: portugués (Brasil), inglés y español, elegibles con independencia del idioma del dispositivo.
- **Temas**: claro, oscuro o según el sistema.

## Pantallas

### Lo que usa la hinchada

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/home.webp" width="220" alt="Pantalla de inicio de la app con el último resultado, el área del club y la Arena Esmeraldina"><br><sub><b>Inicio</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/matches.webp" width="220" alt="Pestaña Partidos con el próximo partido, botón de detalles del partido y la lista de partidos de la ronda"><br><sub><b>Partidos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/standings.webp" width="220" alt="Tabla de clasificación de la Série B con el Goiás resaltado"><br><sub><b>Clasificación</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/calendar.webp" width="220" alt="Pestaña Partidos con el calendario mensual de partidos"><br><sub><b>Partidos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/socio.webp" width="220" alt="Pantalla del programa de socios con los planes disponibles"><br><sub><b>Socios</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/store.webp" width="220" alt="Tienda de la app con categorías de productos y acceso a compras y pedidos"><br><sub><b>Tienda</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/club.webp" width="220" alt="Menú del club desplazado: Ídolos, Directiva, Plantel, Himno y Canciones, Transparencia y Aliados"><br><sub><b>El Club</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/anthem.webp" width="220" alt="Reproductor de la canción Sou esmeraldino con controles de reproducción, volumen y letra"><br><sub><b>Himno y canciones</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/guess-shirt.webp" width="220" alt="Juego en el que el aficionado adivina letra por letra el nombre de un volante del plantel, con teclado en pantalla"><br><sub><b>Adivina la Alineación</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/guess-player.webp" width="220" alt="Adivina el Jugador: tabla de carrera con clubes, partidos y goles y campo para escribir el nombre"><br><sub><b>Adivina el Jugador</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/identity-quiz.webp" width="220" alt="Pregunta del test de identidad futbolística con cuatro frases para elegir"><br><sub><b>Identidad Futbolística</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/identity-result.webp" width="220" alt="Resultado «El Refinado» con rasgos y atributos del estilo de juego"><br><sub><b>¿Qué crack eres?</b></sub></td></tr>
</table>

### Club y contenido

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/club-home.webp" width="220" alt="Menú institucional del club con Historia, Títulos, Ídolos, Directiva, Plantel e Himno"><br><sub><b>Menú del club</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/titles.webp" width="220" alt="Pantalla de títulos del club con el total de títulos principales y los años de cada campeonato"><br><sub><b>Títulos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/board.webp" width="220" alt="Pantalla de la directiva del club con gestión ejecutiva e in memoriam"><br><sub><b>Directiva</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/idols.webp" width="220" alt="Lista de ídolos del club con foto, período y una descripción breve"><br><sub><b>Ídolos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/squad.webp" width="220" alt="Plantel del club en cuadrícula, con foto y dorsal de cada jugador"><br><sub><b>Plantel</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/player.webp" width="220" alt="Perfil de un jugador con número, edad, nacionalidad, altura, pie y carrera"><br><sub><b>Perfil del jugador</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/transparency.webp" width="220" alt="Pantalla de transparencia con convocatorias, estatuto y ejercicios por año"><br><sub><b>Transparencia</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/songs.webp" width="220" alt="Lista con las versiones del himno y las canciones de la hinchada"><br><sub><b>Himno y Canciones</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/document.webp" width="220" alt="Convocatoria abierta en el visor de PDF con botón de compartir"><br><sub><b>Documentos</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/partners.webp" width="220" alt="Cuadrícula con las marcas aliadas del club"><br><sub><b>Socios comerciales</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/media.webp" width="220" alt="Pestaña Medios con los videos de YouTube del club y pestañas de noticias, Instagram y X"><br><sub><b>Medios</b></sub></td></tr>
</table>

### Entradas y socios

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/tickets.webp" width="220" alt="Pantalla de entradas con el próximo evento, botón de compra y acceso rápido a mis entradas y pedidos"><br><sub><b>Entradas</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/ticket-sectors.webp" width="220" alt="Selección de sector y cantidad de entradas por categoría, con sectores de la hinchada local y precios"><br><sub><b>Sectores</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/purchase.webp" width="220" alt="Resumen de la compra con ítems, total, datos de los titulares y aviso de demostración"><br><sub><b>Resumen de la compra</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/purchased.webp" width="220" alt="Confirmación de entrada comprada con acceso directo a Mis entradas"><br><sub><b>Compra completada</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/my-tickets.webp" width="220" alt="Mis entradas con una entrada de demostración próxima y válida, su sector, titular y opción de reembolso"><br><sub><b>Mis entradas</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/ticket.webp" width="220" alt="Entrada digital con datos del partido, sector, titular y código QR, marcada como demostración"><br><sub><b>Entrada</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/member-signup.webp" width="220" alt="Primer paso del registro de socio, con el plan elegido y los datos de acceso"><br><sub><b>Registro de socio</b></sub></td></tr>
</table>

### Arena y pasaporte

<table>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/arena.webp" width="220" alt="Arena Esmeraldina con la Alineación de la Hinchada a la espera del próximo partido, el Pasaporte y los desafíos"><br><sub><b>Arena Esmeraldina</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/challenges.webp" width="220" alt="Desafíos de la Arena: Quiz del Goiás, Adivina la Alineación, Adivina el Jugador y Quién Vistió la Camiseta"><br><sub><b>Desafíos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/crowd.webp" width="220" alt="Alineación de la Hinchada: campo con la formación más votada y el porcentaje de cada jugador"><br><sub><b>Equipo de la hinchada</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/pitch.webp" width="220" alt="Armado de la alineación en el campo con elección de formación y botón de confirmar"><br><sub><b>Arma tu equipo</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/guess-lineup.webp" width="220" alt="Adivina la Alineación: campo con la alineación de un partido histórico por descubrir camiseta a camiseta"><br><sub><b>Campo de la alineación</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/who-wore.webp" width="220" alt="Quién Vistió la Camiseta: foto desenfocada de un exjugador, búsqueda por nombre y tabla de pistas"><br><sub><b>¿Quién Vistió la Camiseta?</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/who-wore-hit.webp" width="220" alt="Resultado de Quién Vistió la Camiseta: acierto al primer intento, con el jugador revelado"><br><sub><b>Respuesta correcta</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/passport.webp" width="220" alt="Pasaporte con la temporada, los partidos a los que asistió el aficionado y cada resultado"><br><sub><b>Pasaporte Esmeraldino</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/es/trajectory.webp" width="220" alt="Resumen de la trayectoria del aficionado con partidos, estadios, temporadas, victorias, goles y partido más memorable"><br><sub><b>Mi trayectoria</b></sub></td></tr>
<tr><td align="center" valign="top"><img src="docs/screenshots/es/ranking.webp" width="220" alt="Ranking de la hinchada con posición, avatar, nombre y puntuación de cada participante"><br><sub><b>Ranking de la hinchada</b></sub></td></tr>
</table>

## Funcionalidades

**Inicio**
- Último resultado, próximo partido y accesos al club, la Arena y la tienda.

**Partidos**
- Próximo partido, jornada actual con navegación entre jornadas, calendario mensual y tabla de posiciones completa con el club destacado.
- Detalle del partido con marcador, cronología de eventos, estadísticas y alineaciones sobre el campo.
- Marcador en vivo con indicador de partido en curso.

**Club**
- Historia, títulos por competición y año, ídolos, directiva y plantel, con perfil y trayectoria de cada jugador.
- Himno y canciones de la hinchada con reproductor de audio y letra en pantalla.
- Documentos de transparencia organizados por categoría, abiertos en PDF dentro de la app y compartibles.
- Patrocinadores.

**Medios**
- Noticias del club leídas dentro de la app, además de Instagram, YouTube y X en un solo feed con filtro por plataforma.

**Socios**
- Planes con beneficios, alta paso a paso con búsqueda de dirección por código postal (CEP), reglamento y preguntas frecuentes.

**Entradas**
- Flujo de entradas para el próximo partido: sector, categoría (entera, media y otras) y cantidad, resumen de la compra con los titulares y confirmación.
- "Mis entradas" con próximos partidos e historial, y entrada digital con código QR, también disponible en PDF.

**Tienda**
- Catálogo por categoría, carrito, checkout e historial de pedidos.

**Arena Esmeraldina**
- **Alineación de la Hinchada**: la hinchada vota la alineación del próximo partido y ve el equipo más votado.
- **Quiz** sobre la historia del club, con niveles de dificultad.
- **Adivina la Alineación**: arma la alineación de un partido histórico, camiseta por camiseta.
- **Adivina el Jugador**: descubre al jugador con pistas de su trayectoria (clubes, partidos y goles).
- **¿Quién vistió la camiseta?**: una foto desenfocada y pistas reveladas en cada intento.
- **Tests de perfil**: un quiz de identidad futbolística que asocia al hincha con un perfil de jugador, y un test de identidad táctica.
- **Ranking de la hinchada**: puntuación acumulada entre los juegos, con vista general, mensual y semanal.

**Pasaporte Esmeraldino**
- El hincha registra los partidos a los que asistió, temporada por temporada, con un ranking del pasaporte y un resumen "Mi trayectoria" con sus números.

**Notificaciones**
- Push para los eventos del partido en vivo (inicio, goles, descanso, segundo tiempo y final), con preferencias por usuario.

**Cuenta**
- Registro con verificación de correo, inicio de sesión, recuperación de contraseña, datos personales, direcciones, avatar, y términos de uso y política de privacidad dentro de la app.
- Eliminación de la cuenta por el propio usuario.

## Arquitectura

- **Un código, un build por club.** La identidad, el contenido y las funcionalidades de cada club se definen en una configuración de club elegida en el build (`APP_CLUB` más flavors de Android/iOS). Las funcionalidades que un club no ofrece desaparecen de la navegación y se bloquean en el enrutador.
- **Backend aislado por club.** Cada club tiene su propio proyecto de Supabase y su propio Cloudflare Worker, con las mismas migraciones y el mismo código de Worker. El aislamiento de datos viene de esa separación física; las columnas `club_id` son una segunda capa defensiva.
- **Dos fuentes de datos en la app.**
  - El **Cloudflare Worker** (TypeScript) entrega datos deportivos públicos, noticias y el feed de redes sociales, con caché por endpoint, almacenamiento en KV, sincronizaciones programadas y un proxy de imágenes.
  - **Supabase** guarda todo lo vinculado a un usuario o al contenido del club: autenticación, socios, entradas y pedidos, contenido de la Arena, progreso y rankings, y el pasaporte.
- **Reglas en el servidor.** Las tablas están protegidas con Row Level Security, y las escrituras que afectan puntuaciones, rankings, socios o pedidos pasan por RPCs `security definer`: el cliente nunca define sus propios resultados.
- **Partidos en vivo.** La app consulta los datos del partido en vivo cada 45 segundos. En el servidor, un job de `pg_cron` llama cada minuto a una Edge Function que detecta los eventos del partido y envía push mediante Firebase Cloud Messaging. La app no usa Supabase Realtime.
- **Comercio en modo demostración.** Los sectores y precios de las entradas y el catálogo de la tienda vienen de datos locales, y no hay pasarela de pago. Los pedidos, entradas y check-ins del usuario se guardan en Supabase detrás de interfaces de repositorio, así que se puede conectar un proveedor real sin cambiar las pantallas.
- **App Flutter** con Clean Architecture organizada por feature (domain, data, presentation), Cubits para el estado, `get_it` para la inyección de dependencias y `go_router`. Un control de versión puede exigir la actualización de la app cuando se define una versión mínima.
- **Observabilidad** con Sentry.

## Tecnologías

| Capa | Tecnología |
| --- | --- |
| App | Flutter, Dart |
| Estado | `flutter_bloc` (Cubit) + `equatable` |
| DI / Navegación | `get_it`, `go_router` |
| Red | `dio` (Worker), `supabase_flutter` (Supabase) |
| Backend | Supabase: Auth, PostgreSQL, RLS, RPCs, Storage, Edge Functions (Deno), `pg_cron` |
| Borde | Cloudflare Workers (TypeScript), Workers KV |
| Push | Firebase Cloud Messaging |
| Motor de minijuegos | Flame |
| Observabilidad | Sentry |
| Tests | `flutter_test`, Vitest (Worker) |

## Estructura del proyecto

```
lib/
├── core/           configuración y capacidades del club, DI, rutas, tema, l10n, red
├── features/       home, match, club, squad, news, social, membership, ticket, store,
│                   arena, crowd_lineup, passport, notifications, partners, profile,
│                   auth, release_gate, splash
├── shared/         widgets reutilizables
└── l10n/           archivos ARB por idioma y por club

src/                Cloudflare Worker (datos deportivos, noticias, feed social, proxy de imágenes)
supabase/           migraciones, SQL y Edge Functions
docs/architecture/  notas de arquitectura, flujo de datos, multiclub, seguridad y tests
```

## Ejecución local

Requisitos: Flutter (canal stable) y Node.js para el Worker.

```bash
flutter pub get
flutter run --flavor goias --dart-define=APP_CLUB=goias
```

En la web no se usa `--flavor`:

```bash
flutter run -d chrome --dart-define=APP_CLUB=goias
```

Worker (Cloudflare):

```bash
npm install
npm run dev:worker
```

Verificaciones:

```bash
flutter analyze
flutter test
npm run test:worker
```

Más detalles en [`docs/architecture`](docs/architecture/README.md).

## Estado del proyecto

En desarrollo. Las funciones de comercio (entradas, tienda y pago de socios) funcionan en modo demostración, sin pagos reales.

## Licencia

No se concede ninguna licencia de código abierto. El código está visible como parte de un portafolio; todos los derechos reservados.

Goiás App es un producto independiente. No representa una alianza, contrato ni respaldo oficial del Goiás Esporte Clube. El nombre, el escudo y las demás marcas del club pertenecen a sus respectivos dueños.

## Acerca de

Desarrollado por Lucas Diogo França. Caso de estudio: [lucksrei.com/projects/fan-hub](https://lucksrei.com/projects/fan-hub/)
