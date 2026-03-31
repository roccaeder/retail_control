# 🚀 Retail Control MVP - Rails 8.1 & Ruby 3.4

Este es un sistema de gestión minorista enfocado en el control de ventas rápidas y administración de deudas (fiados). Diseñado con una arquitectura moderna de **Rails 8.1** y **Ruby 3.4**, utilizando **Docker** para un entorno de desarrollo consistente y despliegues simplificados en **Linux**.

---

## 🛠️ Stack Tecnológico
* **Lenguaje:** Ruby 3.4.2
* **Framework:** Rails 8.1.3 (Modern Rails)
* **Base de Datos:** PostgreSQL 16
* **Estilos:** Tailwind CSS (v4 compatible)
* **JS Runtime:** Bun
* **Contenedores:** Docker & Docker Compose

---

## 📦 Instalación y Configuración (Linux)

Sigue estos pasos para levantar el proyecto en tu máquina local:

### 1. Clonar el repositorio
```bash
git clone [https://github.com/TU_USUARIO/retail_control.git](https://github.com/TU_USUARIO/retail_control.git)
cd retail_control
````

### 2\. Configurar permisos de carpeta

En Linux, Docker a veces crea archivos como usuario `root`. Ejecuta esto para tomar el control total de la carpeta:

```bash
sudo chown -R $USER:$USER .
chmod +x bin/*
```

### 3\. Construir e Iniciar Contenedores

Este proceso instalará las gemas y configurará el entorno:

```bash
docker compose up --build
```

### 4\. Crear y Preparar la Base de Datos

En una terminal nueva (mientras los contenedores están corriendo), ejecuta:

```bash
docker compose exec app bundle exec rails db:prepare
```

-----

## 🚀 Comandos de Uso Diario

| Acción | Comando |
| :--- | :--- |
| **Levantar la App** | `docker compose up` |
| **Detener la App** | `docker compose down` |
| **Entrar a la Consola de Rails** | `docker compose exec app bundle exec rails c` |
| **Correr Migraciones** | `docker compose exec app bundle exec rails db:migrate` |
| **Ver Logs en tiempo real** | `docker compose logs -f` |
| **Instalar nuevas gemas** | `docker compose exec app bundle install` |

-----

## 🔧 Solución de Problemas Comunes (Linux/Docker)

### Error: `Permission Denied` al guardar archivos

Si tu editor no te deja guardar cambios, es porque Docker cambió el dueño de los archivos a `root`. Ejecuta:

```bash
sudo chown -R $USER:$USER .
```

### Error: `Address already in use (port 5432)`

Si al subir Docker te dice que el puerto 5432 está ocupado, detén el PostgreSQL de tu sistema local:

```bash
sudo systemctl stop postgresql
```

### Error: `bin/rails: no such file or directory`

Si los binarios fallan, fuerza su actualización dentro del contenedor:

```bash
docker compose exec app bundle exec rails app:update:bin
```

-----

## 📈 Roadmap del Proyecto

  - [ ] Implementar modelo de **Clientes** y **Productos**.
  - [ ] Interfaz **FastQuick**: Teclado numérico para ventas de un solo clic.
  - [ ] Sistema de **Deuda Envejecida** (Alertas: Al día, Vencido, Crítico).
  - [ ] Reportes en PDF con la gema **Grover**.

-----

## ⚖️ Licencia

Este proyecto es de código abierto bajo la licencia [MIT](https://www.google.com/search?q=LICENSE).

-----

```
```