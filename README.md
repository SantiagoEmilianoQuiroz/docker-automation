# Automatización de servicios Docker

Este proyecto reúne en un único `Makefile` comandos para descargar, iniciar,
consultar, detener y eliminar contenedores Docker. Incluye un Redis independiente,
un conjunto de monitorización (Prometheus, Grafana, Redis y Redis Exporter), la
pila ELK (Elasticsearch, Logstash y Kibana) y cAdvisor.

Los objetivos de Make ejecutan Docker o Docker Compose en el equipo local. No son
simulaciones: los objetivos de inicio y eliminación modifican los contenedores,
imágenes, redes y, según el servicio, los datos de Docker del usuario.

## Contenido del proyecto

```text
.
├── Makefile
├── ELK/
│   ├── docker-compose.yml
│   ├── ports.conf
│   └── titanic.csv
└── monitor/
    ├── grafana/
    │   ├── docker-compose.yml
    │   └── redis-dashboard-for-prometheus-redis-exporter-1-x_rev3.json
    ├── prometheus/
    │   ├── docker-compose.yml
    │   └── prometheus.yml
    ├── redis/
    │   └── docker-compose.yml
    └── redis-exporter/
        └── docker-compose.yml
```

Cada directorio de servicio Compose contiene su propia configuración. Los
objetivos del `Makefile` cambian a ese directorio antes de ejecutar `docker
compose`, por lo que se deben invocar desde el directorio raíz del proyecto.

Archivos de configuración y datos relevantes:

- `monitor/prometheus/prometheus.yml` define el intervalo de recopilación y los
  destinos de Prometheus y Redis Exporter.
- `monitor/grafana/redis-dashboard-for-prometheus-redis-exporter-1-x_rev3.json`
  es un dashboard que se puede importar manualmente en Grafana.
- `ELK/ports.conf` define una entrada TCP de Logstash en el puerto `5000` y una
  salida hacia Elasticsearch en `elasticsearch:9200`. Compose monta el
  directorio `ELK/` como directorio de pipelines de Logstash, en modo de solo
  lectura.
- `ELK/titanic.csv` contiene datos del Titanic. El Compose no configura una
  entrada de Logstash que lea este CSV, así que desplegar ELK por sí solo no lo
  importa ni lo indexa.

## Requisitos

- GNU Make.
- Docker Engine en ejecución y permiso para usar el socket de Docker (por ejemplo,
  pertenecer al grupo `docker` o ejecutar los comandos con permisos adecuados).
- Docker Compose v2, disponible como `docker compose`.
- Acceso a los registros de imágenes de Docker al descargar imágenes. El objetivo
  `load_cadvisor` requiere en cambio el archivo guardado previamente.
- Linux para ejecutar cAdvisor con los montajes configurados en el Makefile. Su
  configuración usa rutas del host como `/sys`, `/var/lib/docker` y `/dev/kmsg`.

Comprueba la instalación con:

```bash
docker --version
docker compose version
make --version
```

## Uso básico

Desde la raíz del proyecto:

```bash
make help
make <objetivo>
```

Por ejemplo:

```bash
make build_elk
make show_elk
```

Los objetivos que descargan o inician servicios pueden tardar según la red y el
equipo. Si un puerto ya está ocupado, Docker no podrá publicar ese puerto y el
objetivo fallará. Consulta los logs con `docker logs <contenedor>` y el estado
con `docker ps -a`.

> **Importante:** `make` sin un objetivo no muestra la ayuda. El primer objetivo
> del Makefile es `build_redis`, por lo que `make` intenta descargar e iniciar
> ese Redis. Usa explícitamente `make help` para consultar la ayuda.

## Objetivos disponibles

### Redis independiente

| Objetivo | Función |
|---|---|
| `build_redis` | Descarga `redis:3` y crea en segundo plano el contenedor `redis`, publicando el puerto `6379` del host. |
| `delete_redis` | Detiene y elimina el contenedor `redis`, elimina la imagen `redis:3` y muestra las imágenes y contenedores restantes. |

`delete_redis` elimina la imagen local, aunque otros contenedores podrían depender
de ella. El objetivo puede fallar si el contenedor no existe o no está en
ejecución. El servicio Redis del monitor también se llama `redis` y usa el puerto
`6379`; no ejecutes ambos Redis a la vez con la configuración actual.

### Monitorización

Los servicios del monitor están definidos en `monitor/`. Se ejecutan en segundo
plano mediante `docker compose up -d`.

| Objetivo | Función |
|---|---|
| `build_monitor_prometheus` | Inicia Prometheus. |
| `build_monitor_grafana` | Inicia Grafana. |
| `build_monitor_redis` | Inicia el Redis del monitor. |
| `build_monitor_redis_exporter` | Inicia Redis Exporter. |
| `build_monitor` | Ejecuta los cuatro objetivos anteriores, uno tras otro, y lista los contenedores activos. |
| `down_monitor_prometheus` | Ejecuta `docker compose down prometheus` en el proyecto de Prometheus. |
| `down_monitor_grafana` | Ejecuta `docker compose down grafana` en el proyecto de Grafana. |
| `down_monitor_redis` | Ejecuta `docker compose down redis` en el proyecto de Redis. |
| `down_monitor_redis_exporter` | Ejecuta `docker compose down redis-exporter` en el proyecto de Redis Exporter. |
| `down_monitor` | Muestra el estado, ejecuta los cuatro objetivos `down_monitor_*` y vuelve a mostrar el estado. |
| `down_monitor_images` | Ejecuta `docker compose down --rmi all` en cada uno de los cuatro proyectos del monitor. |
| `down_monitor_all` | Ejecuta `down_monitor` y después `down_monitor_images`. |

Puertos publicados:

| Servicio | Puerto del host |
|---|---:|
| Prometheus | `9090` |
| Grafana | `3000` |
| Redis del monitor | `6379` |
| Redis Exporter | `9121` |

Prometheus lee `monitor/prometheus/prometheus.yml`. Su configuración consulta
Prometheus en `localhost:9090` y Redis Exporter en `redis-exporter:9121`.
Redis Exporter está conectado a las redes Compose externas `redis` y
`prometheus`; por eso, para que pueda conectarse correctamente, inicia primero
Prometheus y Redis. El objetivo agrupador `build_monitor` respeta ese orden.

Grafana publica el puerto `3000`; el dashboard JSON incluido en su directorio
está disponible para importarlo desde la interfaz, pero el Compose actual no lo
importa automáticamente ni declara credenciales de usuario.

Los objetivos `down_monitor_*` usan `docker compose down` con el servicio
indicado. `down_monitor_images` solicita eliminar las imágenes asociadas a cada
proyecto y es más destructivo que detener los servicios.

### ELK

La definición de la pila está en `ELK/docker-compose.yml`.

| Objetivo | Función |
|---|---|
| `build_elk` | Ejecuta `docker compose build` y después `docker compose up -d` en `ELK/`. |
| `stop_elk` | Detiene los servicios ELK sin eliminar sus contenedores. |
| `start_elk` | Vuelve a iniciar los contenedores ELK detenidos. |
| `restart_elk` | Ejecuta `stop_elk`, después `start_elk` y finalmente muestra los contenedores. |
| `show` / `show_elk` | Muestra las imágenes, los contenedores en ejecución y los contenedores detenidos. |
| `deep_delete` | Muestra el estado, ejecuta `docker compose down` en `ELK/`, elimina las imágenes configuradas y vuelve a mostrar el estado. |

Puertos publicados por Compose:

| Servicio | Puerto del host |
|---|---:|
| Elasticsearch | `9200` |
| Kibana | `5601` |
| Logstash | `5000` |

El Compose utiliza Elasticsearch, Kibana y Logstash `7.9.2`, y configura
Elasticsearch en modo de un único nodo. Las imágenes que elimina `deep_delete`
son `elasticsearch:7.9.2`, `logstash:7.9.2` y `kibana:7.9.2`. Ese objetivo
elimina contenedores e imágenes, por lo que puede requerir volver a descargar
las imágenes la próxima vez que se despliegue ELK. No es un objetivo de limpieza
de datos del host.

Los servicios se comunican por la red predeterminada que Compose crea para el
proyecto; por eso Logstash puede resolver `elasticsearch` como nombre de host.
La configuración de Elasticsearch permite un nodo único para desarrollo o
pruebas, no proporciona por sí sola una configuración de alta disponibilidad.

### cAdvisor

cAdvisor usa la imagen `gcr.io/cadvisor/cadvisor:v0.49.1` y publica su interfaz
en el puerto `8080`.

| Objetivo | Función |
|---|---|
| `build_cadvisor` | Descarga la imagen y crea el contenedor `cadvisor_container` en segundo plano. Si ya existe un contenedor con ese nombre, lo elimina primero. |
| `save_cadvisor` | Guarda la imagen como archivo gzip `cadvisor.tar.gz` en `PATH_CADVISOR_IMAGE`. |
| `load_cadvisor` | Carga el archivo `cadvisor.tar.gz` desde `PATH_CADVISOR_IMAGE` y crea el contenedor con la configuración de cAdvisor. |
| `delete_cadvisor` | Elimina forzosamente el contenedor `cadvisor_container` y elimina la imagen configurada. |

El contenedor se ejecuta con privilegios y acceso de solo lectura a partes del
host necesarias para recopilar métricas: `/`, `/var/run`, `/sys`,
`/sys/fs/cgroup`, `/var/lib/docker` y `/dev/disk`; además, recibe `/dev/kmsg`
como dispositivo. `--privileged` concede permisos amplios al contenedor:
ejecuta cAdvisor solo si confías en la imagen y necesitas esas métricas.

La ruta de archivo predeterminada está fijada en el Makefile:

```make
PATH_CADVISOR_IMAGE=/home/santi/Escritorio/docker-automatizacion
```

Para guardar o cargar en otra ubicación, se puede sobreescribir al invocar Make:

```bash
make save_cadvisor PATH_CADVISOR_IMAGE=/ruta/del/directorio
make load_cadvisor PATH_CADVISOR_IMAGE=/ruta/del/directorio
```

El directorio debe existir y el usuario debe tener permisos de escritura para
guardar o lectura para cargar. El archivo se llama `cadvisor.tar.gz`; la
operación de guardado lo genera mediante `docker save` y `gzip`, y `docker load`
acepta ese archivo comprimido.

## Variables del Makefile

Las variables permiten consultar o reemplazar algunos nombres, etiquetas y rutas
desde la línea de comandos. Por ejemplo, `make build_redis REDIS_TAG=7`.

| Variable | Valor predeterminado | Uso |
|---|---|---|
| `REDIS_TAG` | `3` | Etiqueta de imagen del Redis independiente. |
| `REDIS_CONTAINER_NAME` | `redis` | Nombre del contenedor Redis independiente. |
| `REDIS_IMAGE_NAME` | `redis` | Nombre de la imagen Redis independiente. |
| `ELASTICSEARCH_IMAGE` | `elasticsearch:7.9.2` | Imagen que elimina `deep_delete`. |
| `LOGSTASH_IMAGE` | `logstash:7.9.2` | Imagen que elimina `deep_delete`. |
| `KIBANA_IMAGE` | `kibana:7.9.2` | Imagen que elimina `deep_delete`. |
| `CADVISOR_IMAGE` | `gcr.io/cadvisor/cadvisor` | Repositorio de la imagen de cAdvisor. |
| `CADVISOR_TAG` | `v0.49.1` | Etiqueta de la imagen de cAdvisor. |
| `CADVISOR_CONTAINER` | `cadvisor_container` | Nombre del contenedor de cAdvisor. |
| `PATH_CADVISOR_IMAGE` | `/home/santi/Escritorio/docker-automatizacion` | Directorio del archivo `cadvisor.tar.gz`. |
| `CADVISOR_RUN_ARGS` | Montajes y permisos Linux definidos en el Makefile | Argumentos Docker usados para ejecutar cAdvisor. |

Los nombres de imágenes usados dentro de los archivos Compose se configuran en
esos archivos y no necesariamente cambian al modificar una variable del
Makefile.

## Ayuda y diagnóstico

`make help` muestra los objetivos que incluyen una descripción `##` en el
Makefile. Para consultar manualmente el estado de Docker:

```bash
docker ps
docker ps -a
docker images
docker logs <nombre-o-id-del-contenedor>
docker inspect <nombre-o-id-del-contenedor>
```

Para comprobar los objetivos que ejecutaría Make sin realizar esas operaciones:

```bash
make -n build_cadvisor
make -n deep_delete
```

Si un objetivo falla porque ya existe un contenedor con el mismo nombre, revisa
primero su estado con `docker ps -a`. Si falla por un puerto ocupado, identifica
qué servicio lo está usando antes de detenerlo o cambiar la configuración.
