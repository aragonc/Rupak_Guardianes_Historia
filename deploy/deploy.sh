#!/usr/bin/env bash
# =============================================================================
#  Despliegue de "Rupak: Guardianes de la Historia" en el VPS (Apache2 + HTTPS)
#
#  Uso, en el VPS y dentro del repositorio clonado:
#     sudo ./deploy/deploy.sh                 # actualiza (git pull) y publica
#     sudo ./deploy/deploy.sh --sin-pull      # publica sin hacer git pull
#     sudo ./deploy/deploy.sh --sin-https     # solo HTTP, sin Let's Encrypt
#     ./deploy/deploy.sh --imprimir-conf      # muestra la config de Apache
#
#  Variables opcionales:
#     DOMINIO=otro.dominio.pe   EMAIL=correo@dominio.pe   sudo -E ./deploy/deploy.sh
# =============================================================================
set -euo pipefail

DOMINIO="${DOMINIO:-rupak.playschool.edu.pe}"
EMAIL="${EMAIL:-}"                         # para avisos de vencimiento de Let's Encrypt
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="/etc/apache2/sites-available/${DOMINIO}.conf"
CERT_DIR="${CERT_DIR:-/etc/letsencrypt/live/${DOMINIO}}"

HACER_PULL=1
USAR_HTTPS=1
SOLO_IMPRIMIR=0
for arg in "$@"; do
  case "$arg" in
    --sin-pull)      HACER_PULL=0 ;;
    --sin-https)     USAR_HTTPS=0 ;;
    --imprimir-conf) SOLO_IMPRIMIR=1 ;;
    -h|--help)       sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 1 ;;
  esac
done

log()  { echo -e "\n\033[1;34m==>\033[0m $*"; }
aviso(){ echo -e "\033[1;33m[!]\033[0m $*"; }
error(){ echo -e "\033[1;31m[x]\033[0m $*" >&2; exit 1; }

hay_certificado() { [[ -f "$CERT_DIR/fullchain.pem" && -f "$CERT_DIR/privkey.pem" ]]; }

# --- Configuración común a HTTP y HTTPS --------------------------------------
bloque_sitio() {
cat <<EOF
    DocumentRoot "${APP_DIR}"
    DirectoryIndex index.html

    <Directory "${APP_DIR}">
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted

        # Archivos ocultos (.gitignore, .env...), README y respaldo: no se publican
        <FilesMatch "^(\.|README\.md$|index\.original\.html$)">
            Require all denied
        </FilesMatch>

        # index.html sin caché, para que las actualizaciones se vean al instante
        <IfModule mod_headers.c>
            <Files "index.html">
                Header set Cache-Control "no-cache"
            </Files>
        </IfModule>
    </Directory>

    # El repositorio y los scripts no son públicos
    RedirectMatch 404 "^/(\.git|deploy)(/|$)"

    # Los assets se nombran por su hash: caché larga
    <Directory "${APP_DIR}/assets">
        <IfModule mod_headers.c>
            Header set Cache-Control "public, max-age=2592000, immutable"
        </IfModule>
    </Directory>

    # Comprimir los archivos de texto grandes (script.js ~1.8 MB, project.json)
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/css application/javascript text/javascript application/json image/svg+xml
    </IfModule>

    ErrorLog \${APACHE_LOG_DIR}/rupak_error.log
    CustomLog \${APACHE_LOG_DIR}/rupak_access.log combined
EOF
}

# --- Genera el VirtualHost (con o sin HTTPS) ---------------------------------
generar_conf() {
  local con_ssl="$1"
  echo "# Generado por deploy/deploy.sh el $(date '+%Y-%m-%d %H:%M'). No editar a mano:"
  echo "# los cambios se pierden en el próximo despliegue. Edita deploy/deploy.sh."
  echo
  if [[ "$con_ssl" == 1 ]]; then
cat <<EOF
<VirtualHost *:80>
    ServerName ${DOMINIO}
    # Se mantiene el DocumentRoot para que Let's Encrypt pueda renovar el certificado
    DocumentRoot "${APP_DIR}"
    <Directory "${APP_DIR}/.well-known/acme-challenge">
        Require all granted
    </Directory>
    RedirectMatch permanent "^/(?!\.well-known/acme-challenge/)(.*)$" "https://${DOMINIO}/\$1"
</VirtualHost>

<VirtualHost *:443>
    ServerName ${DOMINIO}
    <IfModule mod_http2.c>
        Protocols h2 http/1.1
    </IfModule>
    SSLEngine on
    SSLCertificateFile    ${CERT_DIR}/fullchain.pem
    SSLCertificateKeyFile ${CERT_DIR}/privkey.pem
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    <IfModule mod_headers.c>
        Header always set Strict-Transport-Security "max-age=31536000"
    </IfModule>

$(bloque_sitio)
</VirtualHost>
EOF
  else
cat <<EOF
<VirtualHost *:80>
    ServerName ${DOMINIO}

$(bloque_sitio)
</VirtualHost>
EOF
  fi
}

# --- Instala la config solo si cambió; si Apache la rechaza, la revierte -----
instalar_conf() {
  local con_ssl="$1" nueva respaldo=""
  nueva="$(mktemp)"
  generar_conf "$con_ssl" > "$nueva"
  # Comparar ignorando la línea con la fecha
  if [[ -f "$CONF" ]] && diff -q <(sed 1d "$CONF") <(sed 1d "$nueva") >/dev/null; then
    echo "Configuración de Apache sin cambios."
    rm -f "$nueva"; return 0
  fi
  if [[ -f "$CONF" ]]; then respaldo="$(mktemp)"; cp "$CONF" "$respaldo"; fi
  install -m 644 "$nueva" "$CONF"; rm -f "$nueva"
  a2ensite -q "${DOMINIO}.conf" >/dev/null
  if ! apache2ctl configtest; then
    aviso "Apache rechazó la configuración nueva; se restaura la anterior."
    if [[ -n "$respaldo" ]]; then cp "$respaldo" "$CONF"; else a2dissite -q "${DOMINIO}.conf"; rm -f "$CONF"; fi
    error "Revisa el mensaje de apache2ctl de arriba."
  fi
  [[ -n "$respaldo" ]] && rm -f "$respaldo"
  systemctl reload apache2
  echo "Configuración instalada en $CONF"
}

# =============================================================================
if [[ "$SOLO_IMPRIMIR" == 1 ]]; then
  if [[ "$USAR_HTTPS" == 1 ]] && hay_certificado; then generar_conf 1; else generar_conf 0; fi
  exit 0
fi

[[ $EUID -eq 0 ]] || error "Ejecuta el script con sudo:  sudo ./deploy/deploy.sh"
[[ -f "$APP_DIR/index.html" && -f "$APP_DIR/assets/project.json" ]] \
  || error "No encuentro index.html o assets/project.json en $APP_DIR"

echo "Dominio:  $DOMINIO"
echo "Carpeta:  $APP_DIR"

# 1. Actualizar el código ------------------------------------------------------
if [[ "$HACER_PULL" == 1 && -d "$APP_DIR/.git" ]]; then
  log "Actualizando el repositorio (git pull)"
  DUENO="$(stat -c %U "$APP_DIR")"
  sudo -u "$DUENO" git -C "$APP_DIR" pull --ff-only \
    || error "git pull falló. Si hay cambios locales en el VPS, revísalos con: git -C $APP_DIR status"
fi

# 2. Paquetes ------------------------------------------------------------------
log "Revisando paquetes"
PAQUETES=()
command -v apache2 >/dev/null || PAQUETES+=(apache2)
[[ "$USAR_HTTPS" == 1 ]] && ! command -v certbot >/dev/null && PAQUETES+=(certbot)
if (( ${#PAQUETES[@]} )); then
  apt-get update -qq && apt-get install -y -qq "${PAQUETES[@]}"
else
  echo "Todo instalado."
fi

# 3. Permisos: Apache solo necesita leer -------------------------------------
log "Ajustando permisos de lectura"
chmod -R a+rX "$APP_DIR"
# Apache debe poder atravesar las carpetas padre (p. ej. /var/www)
d="$APP_DIR"; while [[ "$d" != "/" ]]; do d="$(dirname "$d")"; chmod a+x "$d"; done

# 4. Módulos de Apache ---------------------------------------------------------
log "Activando módulos de Apache"
a2enmod -q headers deflate alias >/dev/null
[[ "$USAR_HTTPS" == 1 ]] && a2enmod -q ssl >/dev/null
a2enmod -q http2 >/dev/null 2>&1 || true

# 5. Configuración HTTP, y HTTPS si ya hay certificado -------------------------
log "Configurando Apache para $DOMINIO"
if [[ "$USAR_HTTPS" == 1 ]] && hay_certificado; then
  instalar_conf 1
else
  instalar_conf 0
fi

# 6. Certificado (solo la primera vez) -----------------------------------------
if [[ "$USAR_HTTPS" == 1 ]] && ! hay_certificado; then
  log "Solicitando certificado HTTPS a Let's Encrypt"
  if [[ -n "$EMAIL" ]]; then CORREO=(-m "$EMAIL"); else CORREO=(--register-unsafely-without-email); fi
  if certbot certonly --webroot -w "$APP_DIR" -d "$DOMINIO" \
       --non-interactive --agree-tos "${CORREO[@]}" \
       --deploy-hook "systemctl reload apache2"; then
    instalar_conf 1
  else
    aviso "No se pudo obtener el certificado. El sitio queda solo en HTTP."
    aviso "Revisa que el DNS de $DOMINIO apunte a este VPS y que los puertos 80/443 estén abiertos"
    aviso "(sudo ufw allow 'Apache Full'). Luego vuelve a ejecutar este script."
  fi
fi

# 7. Comprobación --------------------------------------------------------------
log "Comprobando"
if hay_certificado && [[ "$USAR_HTTPS" == 1 ]]; then URL="https://$DOMINIO"; else URL="http://$DOMINIO"; fi
if command -v curl >/dev/null; then
  CODIGO="$(curl -s -o /dev/null -w '%{http_code}' --resolve "$DOMINIO:443:127.0.0.1" --resolve "$DOMINIO:80:127.0.0.1" "$URL/assets/project.json" || true)"
  if [[ "$CODIGO" == 200 ]]; then echo "OK: el servidor entrega el juego ($CODIGO)."
  else aviso "El servidor respondió $CODIGO al pedir assets/project.json"; fi
fi

echo -e "\n\033[1;32mListo:\033[0m $URL"
