#!/usr/bin/env bash
#
# HostFinder Pro - Interfaz compacta + exit on Ctrl+C
# Autor: SINNOMBRE22
# Versión: 0.8
# Fecha: 2026-02-19
#
# - Cabecera compacta estilo solicitado
# - Ctrl+C (SIGINT) cierra el programa inmediatamente
# - Preferencia HTTP/HTTPS y método HEAD/GET desde Ajustes
# - Usa curl (preferido) y wget (fallback)
#

set -o errexit
set -o nounset
set -o pipefail

VERSION="0.8"
AUTHOR="SINNOMBRE22"
LAST_UPDATED="2026-02-19"
BOX_WIDTH=70

# Preferencias por defecto
PREFER_HTTP_FIRST=0   # 0 = HTTPS primero, 1 = HTTP primero
REQUEST_METHOD="HEAD" # "HEAD" o "GET"
HTTP_TIMEOUT=6        # segundos

# -----------------------------------------------------
# Inicialización de colores (solo si la salida es un TTY)
# -----------------------------------------------------
declare -A color

init_colors() {
    if [[ -t 1 ]]; then
        color[reset]=$'\033[0m'
        color[bold]=$'\033[1m'
        color[dim]=$'\033[2m'
        color[title]=$'\033[38;5;81m'
        color[accent]=$'\033[38;5;208m'
        color[success]=$'\033[38;5;46m'
        color[warning]=$'\033[38;5;226m'
        color[error]=$'\033[38;5;196m'
        color[cyan]=$'\033[38;5;51m'
        color[purple]=$'\033[38;5;141m'
        color[bg]=$'\033[48;5;236m'
    else
        # Sin colores si no es TTY
        color[reset]=""; color[bold]=""; color[dim]=""; color[title]=""
        color[accent]=""; color[success]=""; color[warning]=""; color[error]=""
        color[cyan]=""; color[purple]=""; color[bg]=""
    fi
}
init_colors

# -----------------------------------------------------
# Utilidades
# -----------------------------------------------------
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

repeat_char() {
    local ch="$1"; local n="$2"
    local i=0; local out=""
    while (( i < n )); do out+="$ch"; ((i++)); done
    printf '%s' "$out"
}

strip_ansi() { printf '%s' "$1" | sed -r $'s/\x1B\\[[0-9;]*[mK]//g'; }
visible_length() { local s; s=$(strip_ansi "$1"); printf '%d' "$(printf '%s' "$s" | wc -c | tr -d ' ')"; }

# -----------------------------------------------------
# Cabecera compacta (estilo solicitado)
# -----------------------------------------------------
print_compact_header() {
    # Líneas exactas similares a tu ejemplo, con color opcional
    printf "%b╭─ %bHostFinder Pro · v%s%b\n" "${color[title]}" "${color[bold]}${color[accent]}" "${VERSION}" "${color[reset]}"
    printf "%b│  %bExplorador de Hosts & Estado HTTP%b\n" "${color[title]}" "${color[cyan]}" "${color[reset]}"
    printf "%b│  %b%s  ·  %s%b\n" "${color[title]}" "${color[bold]}" "${AUTHOR}" "${LAST_UPDATED}" "${color[reset]}"
    # línea final con longitud aproximada (ajustable)
    printf "%b╰%s%b\n\n" "${color[title]}" "$(repeat_char '─' 44)" "${color[reset]}"
}

# -----------------------------------------------------
# Manejo de señales: Ctrl+C ahora cierra el programa
# -----------------------------------------------------
on_interrupt() {
    # Mensaje limpio y salida
    printf "\n  %b✖ Interrupción recibida - cerrando HostFinder...%b\n\n" "${color[error]}" "${color[reset]}"
    farewell_quiet
}
trap on_interrupt INT

farewell_quiet() {
    # Mensaje de despedida sin preguntar
    printf "  %b✓ %b%bGracias por usar HostFinder!%b\n" "${color[success]}" "${color[reset]}" "${color[bold]}" "${color[reset]}"
    printf "  %bDesarrollado por %b%s%b\n\n" "${color[dim]}" "${color[bold]}" "${AUTHOR}" "${color[reset]}"
    exit 0
}

farewell() {
    printf "\n  %b✓ %b%b¡Gracias por usar HostFinder! 👋%b\n" "${color[success]}" "${color[reset]}" "${color[bold]}" "${color[reset]}"
    printf "  %bDesarrollado por %b%s%b\n\n" "${color[dim]}" "${color[bold]}" "${AUTHOR}" "${color[reset]}"
    exit 0
}

# -----------------------------------------------------
# Otras utilidades UI
# -----------------------------------------------------
clear_screen() {
    clear
    print_compact_header
}

show_header_prompt() {
    printf "  %b┌─%b %bDominio objetivo%b\n" "${color[dim]}" "${color[reset]}" "${color[cyan]}" "${color[reset]}"
    printf "  %b└─%b %bEj: ejemplo.com%b\n\n" "${color[dim]}" "${color[reset]}" "${color[accent]}" "${color[reset]}"
}

show_legend() {
    printf "  %bLeyenda:%b %bActivo%b / %bRedirección%b / %bInactivo%b / %bNo disponible%b\n" \
        "${color[dim]}" "${color[reset]}" \
        "${color[success]}" "${color[reset]}" \
        "${color[warning]}" "${color[reset]}" \
        "${color[error]}" "${color[reset]}" \
        "${color[warning]}" "${color[reset]}"
    printf "  %bHTTP:%b muestra <código> (<esquema>) y una etiqueta legible\n\n" "${color[dim]}" "${color[reset]}"
}

back_or_exit_prompt() {
    printf "\n  %b[B]%b Regresar  •  %b[E]%b Salir\n" "${color[warning]}" "${color[reset]}" "${color[error]}" "${color[reset]}"
    printf "  %b└─> %b" "${color[dim]}" "${color[reset]}"
    read -r opt
    case "$(trim "$opt")" in
        [Bb]) menu ;;
        [Ee]) farewell ;;
        *) printf "  %b✗ Opción no válida%b\n" "${color[error]}" "${color[reset]}"; sleep 1; menu ;;
    esac
}

# -----------------------------------------------------
# Dependencias
# -----------------------------------------------------
check_dependencies() {
    local missing=0
    if ! command -v wget &>/dev/null; then
        printf "  %b✗ Error: 'wget' no está instalado.%b\n" "${color[error]}" "${color[reset]}"
        printf "    %bInstálalo con: pkg install wget (o apt install wget)%b\n" "${color[dim]}" "${color[reset]}"
        missing=1
    fi
    if ! command -v curl &>/dev/null; then
        printf "  %b! Aviso: 'curl' no está instalado.%b\n" "${color[warning]}" "${color[reset]}"
        printf "    %bSe usará 'wget' como alternativa para comprobar códigos HTTP.%b\n" "${color[dim]}" "${color[reset]}"
    fi
    if [[ "$missing" -eq 1 ]]; then printf "\n"; exit 1; fi
}

# -----------------------------------------------------
# Obtener código HTTP (respeta preferencias y método)
# -----------------------------------------------------
get_http_code() {
    local target="$1"
    local schemes
    if [[ "$PREFER_HTTP_FIRST" -eq 1 ]]; then
        schemes=("http" "https")
    else
        schemes=("https" "http")
    fi

    local timeout_secs=$HTTP_TIMEOUT
    local code=""
    local used_scheme="-"

    for scheme in "${schemes[@]}"; do
        if command -v curl &>/dev/null; then
            if [[ "$REQUEST_METHOD" == "HEAD" ]]; then
                code=$(curl -s -o /dev/null -w "%{http_code}" -I -L --max-time "${timeout_secs}" "${scheme}://${target}" || echo "000")
            else
                code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time "${timeout_secs}" "${scheme}://${target}" || echo "000")
            fi
            if [[ -n "$code" && "$code" != "000" ]]; then
                used_scheme="$scheme"
                printf "%s %s" "$code" "$used_scheme"
                return 0
            fi
        else
            if command -v timeout &>/dev/null; then
                out=$(timeout "${timeout_secs}"s wget --server-response --spider -S "${scheme}://${target}" 2>&1 || true)
            else
                out=$(wget --server-response --spider -S --timeout="${timeout_secs}" "${scheme}://${target}" 2>&1 || true)
            fi
            code=$(awk '/^  HTTP/{c=$2} END{if (c=="") print "000"; else print c}' <<<"$out")
            if [[ -n "$code" && "$code" != "000" ]]; then
                used_scheme="$scheme"
                printf "%s %s" "$code" "$used_scheme"
                return 0
            fi
        fi
    done

    printf "000 -"
    return 0
}

# -----------------------------------------------------
# Clasificar HTTP
# -----------------------------------------------------
classify_http() {
    local code="$1"; local label colored_label
    if [[ "$code" == "000" || -z "$code" ]]; then
        label="No disponible"; colored_label="${color[warning]}${label}${color[reset]}"; printf "%s" "${colored_label}"; return 0
    fi
    local first="${code:0:1}"
    case "$first" in
        2) label="Activo"; colored_label="${color[success]}${label}${color[reset]}" ;;
        3) label="Redirección"; colored_label="${color[warning]}${label}${color[reset]}" ;;
        4|5) label="Inactivo"; colored_label="${color[error]}${label}${color[reset]}" ;;
        *) label="Desconocido"; colored_label="${color[dim]}${label}${color[reset]}" ;;
    esac
    printf "%s" "${colored_label}"
}

# -----------------------------------------------------
# Búsqueda y presentación
# -----------------------------------------------------
hostfinder() {
    clear_screen; show_header_prompt; show_legend
    printf "  %b┌─%b Ingresa dominio: %b" "${color[purple]}" "${color[reset]}" "${color[accent]}"
    read -r target; printf "%b" "${color[reset]}"
    target=$(trim "$target")
    if [[ -z "$target" ]]; then printf "  %b✗ El campo no puede estar vacío%b\n" "${color[error]}" "${color[reset]}"; sleep 1.5; menu; return; fi
    printf "  %b└─%b %bBuscando...%b\n\n" "${color[dim]}" "${color[reset]}" "${color[cyan]}" "${color[reset]}"
    local encoded_target; encoded_target=$(printf '%s' "$target" | sed 's/ /%20/g')
    local result
    if ! result=$(wget -q -O - "http://api.hackertarget.com/hostsearch/?q=${encoded_target}" 2>/dev/null); then
        printf "  %b✗ Error en la consulta a la API%b\n" "${color[error]}" "${color[reset]}"; back_or_exit_prompt; return
    fi
    if [[ -z "$result" ]] || grep -qi "error" <<<"$result"; then
        printf "  %b✗ No se encontraron resultados para: %b%s%b\n" "${color[error]}" "${color[accent]}" "$target" "${color[reset]}"; back_or_exit_prompt; return
    fi

    printf "  %b┌─ Resultados:%b\n" "${color[success]}" "${color[reset]}"
    printf "  %b├%s%b\n" "${color[success]}" "$(repeat_char '─' 64)" "${color[reset]}"

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(trim "$line"); [[ -z "$line" ]] && continue
        local f1 f2 ip host code_and_scheme code scheme display_target colored_label
        f1=$(printf '%s' "$line" | cut -d',' -f1); f2=$(printf '%s' "$line" | cut -d',' -f2)
        f1=$(trim "$f1"); f2=$(trim "$f2")
        if [[ "$f1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then ip="$f1"; host="$f2"
        elif [[ "$f2" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then ip="$f2"; host="$f1"
        else host="$f1"; ip="$f2"; fi

        if [[ -n "$host" && "$host" != "-" ]]; then display_target="$host"
        elif [[ -n "$ip" && "$ip" != "-" ]]; then display_target="$ip"
        else display_target="$f1"; fi

        code_and_scheme=$(get_http_code "$display_target")
        code=$(awk '{print $1}' <<<"$code_and_scheme")
        scheme=$(awk '{print $2}' <<<"$code_and_scheme")
        colored_label=$(classify_http "$code")

        if [[ "$code" == "000" || -z "$code" ]]; then
            printf "  %b▸%b %b%s%b %b→%b %b%s%b %b|%b HTTP: %bNo disponible%b %b(%s)%b\n" \
                "${color[cyan]}" "${color[reset]}" "${color[bold]}" "${display_target}" "${color[reset]}" \
                "${color[dim]}" "${color[reset]}" "${color[accent]}" "${ip}" "${color[reset]}" \
                "${color[dim]}" "${color[reset]}" "${color[warning]}" "${color[reset]}" "${scheme}"
        else
            printf "  %b▸%b %b%s%b %b→%b %b%s%b %b|%b HTTP: %b%s%b %b(%s)%b %b|%b %s\n" \
                "${color[cyan]}" "${color[reset]}" "${color[bold]}" "${display_target}" "${color[reset]}" \
                "${color[dim]}" "${color[reset]}" "${color[accent]}" "${ip}" "${color[reset]}" \
                "${color[dim]}" "${color[reset]}" "${color[bold]}" "${code}" "${color[reset]}" "${scheme}" \
                "${color[dim]}" "${color[reset]}" "${colored_label}"
        fi
    done <<<"$result"

    printf "  %b└%s%b\n\n" "${color[success]}" "$(repeat_char '─' 64)" "${color[reset]}"
    back_or_exit_prompt
}

# -----------------------------------------------------
# Ajustes
# -----------------------------------------------------
settings_menu() {
    clear_screen
    # Compact header re-used
    print_compact_header
    printf "  %bAjustes%b\n\n" "${color[bold]}" "${color[reset]}"
    local pref_text method_text
    if [[ "$PREFER_HTTP_FIRST" -eq 1 ]]; then pref_text="${color[bold]}HTTP primero${color[reset]}"; else pref_text="${color[bold]}HTTPS primero${color[reset]}"; fi
    method_text="${color[bold]}${REQUEST_METHOD}${color[reset]}"
    printf "  Preferencia de protocolo: %s\n" "$pref_text"
    printf "  Método de petición HTTP: %s\n" "$method_text"
    printf "  Timeout por petición: %s segundos\n\n" "$HTTP_TIMEOUT"

    printf "  %b1%b Alternar preferencia (HTTPS/HTTP)\n" "${color[success]}" "${color[reset]}"
    printf "  %b2%b Cambiar método (HEAD/GET)\n" "${color[success]}" "${color[reset]}"
    printf "  %b3%b Cambiar timeout (actual: %s s)\n" "${color[success]}" "${color[reset]}" "$HTTP_TIMEOUT"
    printf "  %bB%b Volver\n\n" "${color[warning]}" "${color[reset]}"
    printf "  %b└─> %b" "${color[dim]}" "${color[reset]}"
    read -r opt; opt=$(trim "$opt")
    case "$opt" in
        1)
            PREFER_HTTP_FIRST=$((1 - PREFER_HTTP_FIRST))
            printf "\n  %b✓ Preferencia cambiada.%b\n" "${color[success]}" "${color[reset]}"
            sleep 1
            settings_menu
            ;;
        2)
            if [[ "$REQUEST_METHOD" == "HEAD" ]]; then REQUEST_METHOD="GET"; else REQUEST_METHOD="HEAD"; fi
            printf "\n  %b✓ Método cambiado a %s.%b\n" "${color[success]}" "$REQUEST_METHOD" "${color[reset]}"
            sleep 1
            settings_menu
            ;;
        3)
            printf "\n  Introduce nuevo timeout en segundos (ej: 6): "
            read -r val
            val=$(trim "$val")
            if [[ "$val" =~ ^[0-9]+$ ]] && (( val > 0 )); then
                HTTP_TIMEOUT=$val
                printf "  %b✓ Timeout actualizado a %s s.%b\n" "${color[success]}" "$HTTP_TIMEOUT" "${color[reset]}"
            else
                printf "  %b✗ Valor inválido.%b\n" "${color[error]}" "${color[reset]}"
            fi
            sleep 1
            settings_menu
            ;;
        [Bb]) menu ;;
        *) printf "  %b✗ Opción inválida.%b\n" "${color[error]}" "${color[reset]}"; sleep 1; settings_menu ;;
    esac
}

# -----------------------------------------------------
# Acerca del autor
# -----------------------------------------------------
about_author() {
    clear_screen
    print_compact_header
    printf "  %bHostFinder Pro — Presentación%b\n\n" "${color[bold]}" "${color[reset]}"
    printf "  %bAutor:%b %b%s%b\n" "${color[cyan]}" "${color[reset]}" "${color[bold]}" "${AUTHOR}" "${color[reset]}"
    printf "  %bVersión:%b %s   %bActualizado:%b %s\n\n" "${color[cyan]}" "${color[reset]}" "${VERSION}" "${color[cyan]}" "${color[reset]}" "${LAST_UPDATED}"
    printf "  %bNotas:%b\n" "${color[dim]}" "${color[reset]}"
    printf "   - Se intentará el protocolo según la preferencia configurada en Ajustes.\n"
    printf "   - '000' indica que no se obtuvo código (timeout/conexión denegada).\n\n"
    back_or_exit_prompt
}

invalid_option() { printf "\n  %b✗ Opción inválida%b\n" "${color[error]}" "${color[reset]}"; sleep 1; menu; }

# -----------------------------------------------------
# Menú principal (formato similar al solicitado)
# -----------------------------------------------------
menu() {
    clear_screen
    printf "  %b▸ Menú principal%b    %b(versión %s)%b\n\n" "${color[accent]}" "${color[reset]}" "${color[dim]}" "${VERSION}" "${color[reset]}"
    printf "%s\n" "─────────────── ◈ ───────────────"
    printf "\n"
    printf "  %b[1]%b Buscar hosts (API hostsearch)\n" "${color[success]}" "${color[reset]}"
    printf "  %b[2]%b Ajustes (preferencia HTTP/HTTPS, método HEAD/GET)\n" "${color[success]}" "${color[reset]}"
    printf "  %b[99]%b Presentación / Autor\n" "${color[warning]}" "${color[reset]}"
    printf "  %b[00]%b Salir\n\n" "${color[error]}" "${color[reset]}"
    printf "%s\n" "─────────────── ◈ ───────────────"
    printf "  %b└─ Opción › %b" "${color[purple]}" "${color[reset]}"
    read -r select; select=$(trim "$select")
    case "$select" in
        1) hostfinder ;;
        2) settings_menu ;;
        99) about_author ;;
        00|0) farewell ;;
        *) invalid_option ;;
    esac
}

# -----------------------------------------------------
# Inicio
# -----------------------------------------------------
check_dependencies
menu
