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

El juego se publica en **https://rupak.playschool.edu.pe**, en un VPS con Apache2. Una vez publicado, se abre con un enlace normal y no hace falta el servidor local. Los pasos están en [Despliegue en el VPS](#despliegue-en-el-vps-apache2).

## Despliegue en el VPS (Apache2)

Son solo archivos estáticos: no hace falta PHP, Node ni base de datos. El script [`deploy/deploy.sh`](deploy/deploy.sh) hace todo el trabajo:

- Actualiza el código con `git pull`.
- Instala Apache y Certbot si faltan.
- Ajusta los permisos y activa los módulos de Apache (`headers`, `deflate`, `ssl`, `http2`).
- Genera la configuración del sitio en `/etc/apache2/sites-available/rupak.playschool.edu.pe.conf`.
- Obtiene el certificado HTTPS de Let's Encrypt (solo la primera vez) y redirige HTTP → HTTPS.
- Comprueba que el juego responde.

Si Apache rechaza una configuración nueva, el script restaura la anterior y el sitio sigue funcionando.

### Primera vez

**1. DNS.** En el panel DNS de `playschool.edu.pe`, crea un registro **A**: `rupak` → IP del VPS. Verifícalo con:
```bash
ping rupak.playschool.edu.pe
```

**2. Clonar el repositorio en el VPS** (por SSH):
```bash
cd /var/www
sudo git clone https://github.com/aragonc/Rupak_Guardianes_Historia.git rupak
sudo chown -R $USER:$USER /var/www/rupak
```
Si el repositorio es privado, clónalo con SSH (`git@github.com:aragonc/Rupak_Guardianes_Historia.git`) usando una *deploy key* de GitHub.

**3. Abrir los puertos** (si usas `ufw`):
```bash
sudo ufw allow 'Apache Full'
```

**4. Desplegar:**
```bash
cd /var/www/rupak
sudo EMAIL=tu-correo@playschool.edu.pe ./deploy/deploy.sh
```
`EMAIL` es opcional: Let's Encrypt lo usa para avisar si el certificado está por vencer.

Si el DNS todavía no apunta al VPS, el sitio queda en HTTP. Cuando el DNS ya funcione, vuelve a ejecutar el script y activará HTTPS.

### Actualizar el juego

1. Desde tu computadora, sube los cambios: `git push`.
2. En el VPS, ejecuta:
   ```bash
   cd /var/www/rupak && sudo ./deploy/deploy.sh
   ```

### Opciones del script

| Comando | Qué hace |
|---|---|
| `sudo ./deploy/deploy.sh` | Actualiza con `git pull` y publica |
| `sudo ./deploy/deploy.sh --sin-pull` | Publica sin actualizar el código |
| `sudo ./deploy/deploy.sh --sin-https` | Solo HTTP, sin pedir certificado |
| `./deploy/deploy.sh --imprimir-conf` | Muestra la configuración de Apache que generaría, sin instalar nada |
| `sudo DOMINIO=otro.dominio.pe ./deploy/deploy.sh` | Usa otro dominio |

### Seguridad

El repositorio completo queda dentro de la carpeta del sitio, así que la configuración bloquea lo que no debe ser público:

- `/.git/` y `/deploy/` devuelven 404.
- `README.md`, `index.original.html` y los archivos ocultos (`.gitignore`, `.env`…) devuelven 403.

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

### Vertical u horizontal

El juego funciona con el celular en las dos posiciones. Cada jugador elige la que prefiera:

- **Horizontal:** el juego se ve más grande y los botones quedan a los costados.
- **Vertical:** el juego queda arriba y los botones debajo. Conviene usarlo cuando el juego pide **escribir una respuesta**, porque el teclado en pantalla solo tapa los botones y el juego sigue a la vista.

Mientras escribes, los botones táctiles se ocultan solos y vuelven al terminar.

### Pantalla completa

- **Android (Chrome):** al tocar la pantalla de inicio, el juego pasa a pantalla completa, sin bloquear la rotación. Si sales de la pantalla completa, toca el botón **⛶** para volver.
- **iPhone (Safari):** Safari no permite poner una página en pantalla completa. Para jugar sin las barras del navegador, usa **Compartir → "Agregar a inicio"** y abre el juego desde ese ícono.

El juego mantiene su proporción original de 4:3, así que en horizontal quedan franjas negras a los lados. Los botones van en esas franjas.

## Archivos

```
Rupak_Guardianes_Historia/
├── index.html            ← página del juego (incluye los controles táctiles)
├── index.original.html   ← copia de respaldo, tal como salió del TurboWarp Packager
├── script.js             ← motor de TurboWarp
├── assets/               ← proyecto (project.json), imágenes y sonidos
├── deploy/
│   └── deploy.sh         ← despliegue en el VPS (Apache2 + HTTPS)
├── .gitignore
└── README.md
```

## Cambios sobre la exportación original

Estos cambios se hicieron a mano en `index.html`, después de exportar desde TurboWarp Packager:

1. **Controles táctiles flotantes.** Envían al juego las mismas teclas que el teclado.
2. **Vertical u horizontal.** En vertical, el juego queda arriba y los controles debajo. Al empezar en el celular, el juego pasa a pantalla completa. Los botones se ocultan mientras se escribe.
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
| La web muestra la página por defecto de Apache | Vuelve a ejecutar `sudo ./deploy/deploy.sh` y revisa los mensajes del script. |
| `Forbidden` (403) en el dominio | Vuelve a ejecutar `sudo ./deploy/deploy.sh`: el script corrige los permisos. |
| Certbot falla al validar | El DNS todavía no apunta al VPS, o el firewall bloquea los puertos 80 y 443 (`sudo ufw allow 'Apache Full'`). Corrígelo y vuelve a ejecutar el script. |
| `git pull falló` | Hay cambios hechos a mano en el VPS. Revísalos con `git -C /var/www/rupak status`. |
| El juego no cambia al girar el celular | Revisa que la rotación automática del celular no esté bloqueada. |
| El teclado tapa el juego al escribir | Pon el celular en vertical: el juego queda arriba y el teclado solo tapa los botones. |
