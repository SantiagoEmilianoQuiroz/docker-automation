# -----------------------------------
#1.CONSTRUCCION DE REDIS
#--------------------------

# -----------------------------------
# Construir una imagen de Redis
# Asignar un nombre al contenedor
# Asignar el tag mediante una variable
# -----------------------------------

REDIS_TAG = 3
REDIS_CONTAINER_NAME = redis
REDIS_IMAGE_NAME = redis

# -----------------------------------
# Construccion y despliegue de la imagen de Redis
# -----------------------------------

build_redis:
	@echo 'Construyendo la imagen de Redis con el TAG $(REDIS_TAG)...'
	docker pull $(REDIS_IMAGE_NAME):$(REDIS_TAG)
	@echo 'Ejecutando el contenedor de Redis con el nombre $(REDIS_CONTAINER_NAME)...'
	docker run -d --name $(REDIS_CONTAINER_NAME) -p 6379:6379 $(REDIS_IMAGE_NAME):$(REDIS_TAG)

# -----------------------------------
# Visualizar todas las imágenes de docker
# Visualizar contenedores activos
# Visualizar contenedores inactivos
# -----------------------------------

show_images_containers:
	@echo 'Mostrando todas las imágenes de Docker...'
	docker images
	@echo 'Mostrando contenedores activos...'
	docker ps --filter "status=running"
	@echo 'Mostrando contenedores inactivos...'
	docker ps --filter "status=exited"

# -----------------------------------
# Eliminar el contenedor de redis
# Visualizar de nuevo 
# -----------------------------------

delete_redis:
	@echo 'Parar redis'
	docker stop $(REDIS_CONTAINER_NAME)
	@echo 'Eliminación del contenedor $(REDIS_CONTAINER_NAME)'
	docker rm $(REDIS_CONTAINER_NAME)
	@echo 'Eliminación de la imagen $(REDIS_IMAGE_NAME)'
	docker rmi $(REDIS_IMAGE_NAME):$(REDIS_TAG)
	@echo 'Imágenes de docker'
	docker images -a
	@echo 'Verificación de la eliminación'
	docker ps -a

# -----------------------------------
# 2. DESPLIEGUE DEL MONITOR
# -----------------------------------

# Construcción del monitor
build_monitor_prometheus:## Construcción y despliegue de Prometheus
	@echo 'Construcción y despliegue de Prometheus'
	cd monitor/prometheus && docker compose up -d
build_monitor_grafana:## Construcción y despliegue de Grafana
	@echo 'Construcción y despliegue de Grafana'
	cd monitor/grafana && docker compose up -d

build_monitor_redis:## Construcción y despliegue de Redis
	@echo 'Construcción y despliegue de redis'
	cd monitor/redis && docker compose up -d

build_monitor_redis_exporter:## Construcción y despliegue de Redis Exporter
	@echo 'Construcción y despliegue de redis-exporter'
	cd monitor/redis-exporter && docker compose up -d

# Levantamiento de todos los servicios del monitor
build_monitor:## Construcción y despliegue de todos los servicios del monitor
	@echo 'Construcción y despliegue de todos los servicios del monitor'
	$(MAKE) build_monitor_prometheus
	$(MAKE) build_monitor_grafana
	$(MAKE) build_monitor_redis
	$(MAKE) build_monitor_redis_exporter
	echo 'Todos los servicios del monitor han sido construidos y desplegados'
	docker ps --filter "status=running"

# Eliminación de los servicios del monitor
down_monitor_prometheus:## Parar el servicio de Prometheus
	@echo 'Parar el servicio de Prometheus'
	cd monitor/prometheus && docker compose down prometheus

down_monitor_grafana:## Parar el servicio de Grafana
	@echo 'Parar el servicio de grafana'
	cd monitor/grafana && docker compose down grafana

down_monitor_redis:## Parar el servicio de Redis
	@echo 'Parar el servicio de redis'
	cd monitor/redis && docker compose down redis

down_monitor_redis_exporter:## Parar el servicio de Redis Exporter
	@echo 'Parar el servicio de redis-exporter'
	cd monitor/redis-exporter && docker compose down redis-exporter

down_monitor: ## Eliminación de los contenedores del monitor
	@echo 'Contenedores en ejecución'
	docker ps -a
	$(MAKE) down_monitor_prometheus
	$(MAKE) down_monitor_grafana
	$(MAKE) down_monitor_redis
	$(MAKE) down_monitor_redis_exporter
	@echo 'Contenedores en ejecución'
	docker ps -a

# Eliminar las imagenes de cada servicio del monitor
down_monitor_images: ## Eliminación de las imágenes del monitor
	@echo 'Eliminación de la imagen de Prometheus'
	cd monitor/prometheus && docker compose down --rmi all
	@echo 'Eliminación de la imagen de Grafana'
	cd monitor/grafana && docker compose down --rmi all
	@echo 'Eliminación de la imagen de Redis'
	cd monitor/redis && docker compose down --rmi all
	@echo 'Eliminación de la imagen de Redis Exporter'
	cd monitor/redis-exporter && docker compose down --rmi all
	@echo 'Todas las imágenes del monitor han sido eliminadas'

# Eliminar todas las imagenes del monitor
down_monitor_all: ## Eliminación de los contenedores e imágenes del monitor
	$(MAKE) down_monitor
	$(MAKE) down_monitor_images

# Proporciona ayuda
.PHONY: help
help: ## Comando de ayuda
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

# -----------------------------------
# 3. DESPLIEGUE DE ELK
# -----------------------------------
build_elk: ## Construcción y despliegue de ELK
	@echo 'Construcción de ELK'
	cd ELK && docker compose build
	@echo 'Despliegue de ELK'
	cd ELK && docker compose up -d

stop_elk: ## Parar los servicios ELK
	@echo 'Parar los servicios ELK'
	cd ELK && docker compose stop

start_elk: ## Encender los servicios ELK
	@echo 'Encender los servicios ELK'
	cd ELK && docker compose start

restart_elk: ## Reinicio de los servicios ELK
	@echo 'Reinicio de ELK'
	$(MAKE) stop_elk
	$(MAKE) start_elk
	docker ps

# Variables
ELASTICSEARCH_IMAGE=elasticsearch:7.9.2
LOGSTASH_IMAGE=logstash:7.9.2
KIBANA_IMAGE=kibana:7.9.2

.PHONY: show show_elk deep_delete
show: show_elk ## Mostrar imágenes y contenedores

show_elk: ## Mostrar imágenes y contenedores de ELK
	@echo 'Estado actual de imágenes y contenedores Docker'
	docker images -a 
	@echo 'Contenedores en ejecución'
	docker ps --filter status=running
	@echo 'Contenedores fuera de ejecución'
	docker ps --filter status=exited

deep_delete: ## Eliminación profunda de ELK
	$(MAKE) show_elk
	@echo 'Eliminación de contenedores'
	cd ELK && docker compose down 
	@echo 'Purgación de las imágenes'
	docker rmi $(ELASTICSEARCH_IMAGE) $(LOGSTASH_IMAGE) $(KIBANA_IMAGE)
	$(MAKE) show_elk

# -----------------------------------
# 3. DESPLIEGUE DE CADVISOR
# -----------------------------------

CADVISOR_IMAGE=gcr.io/cadvisor/cadvisor
CADVISOR_TAG=v0.49.1
CADVISOR_CONTAINER=cadvisor_container
PATH_CADVISOR_IMAGE=/home/santi/Escritorio/docker-automatizacion
CADVISOR_RUN_ARGS = \
	--privileged \
	--device=/dev/kmsg \
	--volume=/:/rootfs:ro \
	--volume=/var/run:/var/run:ro \
	--volume=/sys:/sys:ro \
	--volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
	--volume=/var/lib/docker:/var/lib/docker:ro \
	--volume=/dev/disk:/dev/disk:ro

build_cadvisor: ## Construcción y despliegue de cadvisor
	@echo 'Descarga de la imagen de $(CADVISOR_IMAGE)'
	docker pull $(CADVISOR_IMAGE):$(CADVISOR_TAG)
	@echo 'Ejecución de $(CADVISOR_IMAGE)'
	@set -e; container_id=$$(docker ps -aq --filter "name=^/$(CADVISOR_CONTAINER)$$"); if [ -n "$$container_id" ]; then docker rm -f "$$container_id"; fi
	docker run -d -p 8080:8080 --name $(CADVISOR_CONTAINER) $(CADVISOR_RUN_ARGS) $(CADVISOR_IMAGE):$(CADVISOR_TAG)

save_cadvisor: ## Guarda la imagen de cAdvisor
	@echo 'Guarda la imagen de cAdvisor'
	docker save $(CADVISOR_IMAGE):$(CADVISOR_TAG) | gzip > $(PATH_CADVISOR_IMAGE)/cadvisor.tar.gz

load_cadvisor: ## Carga de la imagen de cadvisor y ejecución
	@echo 'Carga de la imagen'
	docker load --input $(PATH_CADVISOR_IMAGE)/cadvisor.tar.gz
	@echo 'Ejecución de un contenedor para cAdvisor'
	@set -e; container_id=$$(docker ps -aq --filter "name=^/$(CADVISOR_CONTAINER)$$"); if [ -n "$$container_id" ]; then docker rm -f "$$container_id"; fi
	docker run -d -p 8080:8080 --name $(CADVISOR_CONTAINER) $(CADVISOR_RUN_ARGS) $(CADVISOR_IMAGE):$(CADVISOR_TAG)

delete_cadvisor: ## Eliminación de contenedores y imagenes de cadvisor
	docker rm -f $(CADVISOR_CONTAINER)
	docker rmi $(CADVISOR_IMAGE):$(CADVISOR_TAG)