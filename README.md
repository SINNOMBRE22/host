# HostFinder Pro (finder.sh)

HostFinder Pro es un script en Bash para buscar subhosts/hosts relacionados con un dominio (usa la API de hackertarget) y comprobar el estado HTTP/HTTPS de cada host de forma compacta y coloreada en la terminal. Está pensado para usarse en entornos ligeros como Termux en Android o VPS con Ubuntu.

Versión: 0.8  
Autor: SINNOMBRE22  
Última actualización: 2026-02-19

---

## Características principales

- Interfaz compacta y coloreada (si el terminal es TTY).
- Búsqueda de hosts mediante la API de `api.hackertarget.com/hostsearch`.
- Comprobación del estado HTTP/HTTPS (HEAD por defecto, con opción GET).
- Preferencia configurable: HTTPS primero o HTTP primero.
- Manejo de Ctrl+C para cerrar inmediatamente.
- Usa `curl` si está disponible; usa `wget` como alternativa.

---

## Requisitos

- bash (compatible POSIX/Bash)
- git (para clonar el repo)
- wget (obligatorio en la comprobación/consulta de API)
- curl (recomendado, si no está instalado se usará wget)
- Conexión a Internet (la búsqueda depende de la API externa)

---

## Instalación y uso

A continuación se muestran los pasos y comandos tanto para Termux (Android) como para una VPS Ubuntu.

IMPORTANTE: la URL del repositorio:
- https://github.com/SINNOMBRE22/host.git

### En Termux (Android)

1. Abrir Termux y actualizar paquetes:
```sh
pkg update && pkg upgrade
```

2. Instalar dependencias:
```sh
pkg install git wget curl bash
```

3. Clonar el repositorio:
```sh
git clone https://github.com/SINNOMBRE22/host.git
cd host
```

4. Dar permiso de ejecución al script y ejecutarlo:
```sh
chmod +x finder.sh
./finder.sh
```
O si prefieres forzar bash:
```sh
bash finder.sh
```

### En una VPS Ubuntu (Debian/Ubuntu)

1. Actualizar sistema:
```sh
sudo apt update && sudo apt upgrade -y
```

2. Instalar dependencias:
```sh
sudo apt install -y git wget curl bash
```

3. Clonar el repositorio y entrar:
```sh
git clone https://github.com/SINNOMBRE22/host.git
cd host
```

4. Hacer ejecutable y ejecutar:
```sh
chmod +x finder.sh
./finder.sh
```
O con bash:
```sh
bash finder.sh
```

---

## Uso básico

- Al ejecutar `./finder.sh` verás el menú principal:
  - 1: Buscar hosts (requiere dominio, usa API externa)
  - 2: Ajustes (cambiar preferencia HTTP/HTTPS, método HEAD/GET, timeout)
  - 99: Presentación / Autor
  - 00: Salir

- En "Buscar hosts" introduce el dominio objetivo (ej: ejemplo.com). El script consultará la API y luego intentará verificar HTTP/HTTPS para cada host encontrado.

---

## Ajustes (cómo cambiarlos)

Los valores por defecto están en la parte superior de `finder.sh`:

```sh
PREFER_HTTP_FIRST=0   # 0 = HTTPS primero, 1 = HTTP primero
REQUEST_METHOD="HEAD" # "HEAD" o "GET"
HTTP_TIMEOUT=6        # segundos
```

Puedes:
- Editar el archivo con `nano finder.sh` o `vim finder.sh` y cambiar esas variables.
- O usar la opción 2 del menú `Ajustes` para alternar sin editar el archivo.

---

## Ejemplo rápido

1. Ejecutar:
```sh
./finder.sh
```

2. Seleccionar `1` para buscar hosts y escribir:
```
ejemplo.com
```

El script imprimirá una lista de hosts con su IP y el estado HTTP (código, esquema y etiqueta legible: Activo, Redirección, Inactivo, No disponible).

---

## Advertencias y notas

- El script depende de la API pública `api.hackertarget.com/hostsearch`. Esa API puede tener límites o restricciones y puede devolver errores o resultados incompletos.
- `000` se usa para indicar que no se obtuvo respuesta HTTP (timeout o conexión denegada).
- Asegúrate de respetar las políticas del servicio y la legalidad al escanear dominios/hosts que no posees.
- Si `curl` no está disponible, el script usa `wget` como alternativa; `wget` es requerido para la consulta a la API en la implementación actual.

---

## Solución de problemas

- Mensaje: "Error: 'wget' no está instalado." → Instala wget (en Termux `pkg install wget`, en Ubuntu `sudo apt install wget`).
- Si ves muchos `000` revisa la conectividad de red, firewall o bloqueos por parte del host/ISP.
- Para pruebas rápidas sin permisos: `bash finder.sh` evita problemas de permisos si no quieres usar `chmod`.

---

## Contribuciones

Si deseas contribuir:
1. Haz un fork del repositorio.
2. Crea una rama con tu cambio.
3. Abre un pull request explicando los cambios.

---

## Licencia & Autor

- Autor: SINNOMBRE22  
- Archivo principal: `finder.sh` (Bash script)

Si quieres que incluya un bloque de licencia (MIT, GPL, etc.) indícamelo y lo agrego.

