# Rupak: Guardianes de la Historia

Juego de plataformas hecho en Scratch y empaquetado con TurboWarp Packager. Kusi recorre los escenarios, recoge monedas, esquiva a los huaqueros y a Supay, y aprende sobre la historia de la cultura Chancay.

## Cómo abrir el juego

> **Importante:** no abras `index.html` con doble clic. Si lo haces, aparecerá este error:
> *"Zip environment must be used on a website, not on a local file"*.
> El juego carga sus imágenes y sonidos desde la carpeta `assets/`, y el navegador lo bloquea si la página se abre como archivo local.

### En la computadora

1. Abre una terminal dentro de la carpeta del juego.
2. Inicia un servidor local:
   ```bash
   python3 -m http.server 8765
   ```
3. En el navegador, entra a **http://localhost:8765/index.html**
4. Deja la terminal abierta mientras juegas. Para detener el servidor, presiona `Ctrl + C`.

### En el celular (misma red Wi‑Fi)

1. Inicia el servidor en la computadora, como en el paso anterior.
2. Averigua la IP local de la computadora:
   ```bash
   hostname -I
   ```
3. En el navegador del celular, entra a `http://<IP-de-la-computadora>:8765/index.html`
   (por ejemplo: `http://192.168.101.37:8765/index.html`).
4. Si no carga, revisa que el firewall permita conexiones al puerto 8765.

### Publicarlo en internet

La carpeta completa (`index.html`, `script.js` y `assets/`) se puede subir a cualquier hosting de páginas estáticas, por ejemplo GitHub Pages, itch.io (como juego HTML), Netlify o el servidor del colegio. Una vez publicado, se abre con un enlace normal y no hace falta el servidor local.

## Controles

| Acción | Teclado | Celular |
|---|---|---|
| Moverse a la izquierda | `←` o `A` | Botón **◀** |
| Moverse a la derecha | `→` o `D` | Botón **▶** |
| Saltar | `Espacio` | Botón **SALTAR** |
| Interactuar (puertas) | `E` | Botón **E** |
| Avanzar en textos e información | `Enter` | Botón **ENTER** |

### Controles táctiles

- Aparecen solos en celulares y tablets.
- Se pueden presionar dos botones a la vez; por ejemplo, correr y saltar.
- El botón **🎮** (arriba a la derecha) muestra u oculta los controles, y el navegador recuerda la elección. En la computadora también sirve para mostrarlos y probarlos con el ratón.

### Pantalla completa y modo horizontal

- **Android (Chrome):** al tocar la pantalla de inicio, el juego pasa a pantalla completa y gira a horizontal. Si sales de la pantalla completa, toca el botón **⛶** para volver.
- **Celular en vertical:** aparece el aviso "Gira tu celular para jugar".
- **iPhone (Safari):** Safari no permite poner una página en pantalla completa ni bloquear la rotación. Para jugar sin las barras del navegador, usa **Compartir → "Agregar a inicio"** y abre el juego desde ese ícono.

El juego mantiene su proporción original de 4:3. En celulares anchos quedan franjas negras a los lados, y ahí se ubican los botones táctiles para no tapar la escena.

## Archivos

```
Rupak_Guardianes_Historia/
├── index.html            ← página del juego (incluye los controles táctiles)
├── index.original.html   ← copia de respaldo, tal como salió del TurboWarp Packager
├── script.js             ← motor de TurboWarp
├── assets/               ← proyecto (project.json), imágenes y sonidos
└── README.md
```

## Cambios sobre la exportación original

Estos cambios se hicieron a mano en `index.html`, después de exportar desde TurboWarp Packager:

1. **Controles táctiles flotantes.** Envían al juego las mismas teclas que el teclado.
2. **Pantalla completa y bloqueo en horizontal.** Se activan al empezar en el celular, y se agregó el aviso para girar el celular.
3. **Etiquetas `meta` para celular.** Permiten respetar la muesca de la pantalla (`viewport-fit=cover`) y abrir el juego en pantalla completa desde el ícono de inicio en iPhone.

Todo el código agregado está entre los comentarios
`<!-- ===== Controles táctiles para celular ===== -->` y `<!-- ===== Fin controles táctiles ===== -->`,
al final de `index.html`.

> **Ojo:** si vuelves a exportar el juego desde TurboWarp Packager, el `index.html` nuevo no tendrá estos cambios. Para recuperarlos, copia el bloque marcado y pégalo antes de `</body>` en el nuevo `index.html`. Copia también las etiquetas `meta` del inicio del archivo.

## Problemas comunes

| Problema | Solución |
|---|---|
| Error *"Zip environment must be used on a website…"* | Abriste el archivo con doble clic. Usa el servidor local (ver arriba). |
| *"Address already in use"* al iniciar el servidor | Ese puerto está ocupado. Usa otro, por ejemplo `python3 -m http.server 8080`. |
| El celular no carga la página | Revisa que el celular esté en la misma red Wi‑Fi y que el firewall permita el puerto. |
| No aparecen los botones en el celular | Toca el botón **🎮** de arriba a la derecha. |
| No gira a horizontal | Gira el celular a mano. En iPhone no se puede forzar la rotación, y en Android revisa que la rotación automática no esté bloqueada. |
