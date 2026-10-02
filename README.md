# Laboratorio Local LLM Secure

Laboratorio para ejecutar un modelo de lenguaje local dentro de un contenedor Podman, aplicando controles de seguridad y aislamiento.

El objetivo es construir un entorno reproducible para ejecutar un LLM sin depender de servicios externos durante la ejecución y limitando el acceso del contenedor al sistema host.

## Objetivos

* Ejecutar un LLM local mediante `llama.cpp`.
* Utilizar un modelo en formato GGUF.
* Ejecutar el servicio dentro de un contenedor Podman.
* Mantener el modelo fuera de la imagen.
* Ejecutar el proceso con un usuario sin privilegios.
* Limitar el acceso al filesystem del host.
* Bloquear el acceso a Internet durante la ejecución.
* Exponer únicamente el puerto necesario para la API.
* Generar una imagen portable para ejecución offline.
* Documentar y validar los controles de seguridad.

## Arquitectura

```text
Host
 |
 | Podman
 |
 +-------------------------------+
 | Container                    |
 |                              |
 |  llama-server                |
 |  UID 10001                   |
 |  CPU                         |
 |                              |
 |  Port 8080                   |
 |                              |
 |  /models:ro                  |
 +-------------------------------+
          |
          | Modelo GGUF
          |
       Host volume
```

El modelo GGUF no forma parte de la imagen. Se monta externamente y en modo de solo lectura.

La comunicación con el servicio se realizará mediante HTTP utilizando la API compatible con OpenAI proporcionada por `llama-server`.

## Tecnologías

* Podman
* llama.cpp
* llama-server
* GGUF
* Ubuntu 24.04
* GitLab

## Modelo

El modelo seleccionado para el laboratorio es:

```text
Qwen2.5-1.5B-Instruct
Formato: GGUF
Cuantización: Q4_K_M
```

La selección está orientada a las restricciones de hardware disponibles y al objetivo de ejecutar el modelo utilizando CPU.

## Seguridad

El laboratorio busca aplicar las siguientes medidas:

* Usuario no-root.
* UID fijo para el proceso.
* Imagen multi-stage.
* Runtime separado del entorno de compilación.
* Modelo montado como `read-only`.
* Sin herramientas de compilación en la imagen final.
* Sin acceso a filesystem del host fuera de los volúmenes explícitamente definidos.
* Sin acceso a Internet durante la ejecución.
* Eliminación de capacidades Linux innecesarias.
* `no-new-privileges`.
* Filesystem raíz de solo lectura cuando sea compatible con el runtime.
* Exposición del servicio únicamente mediante el puerto requerido.

Las restricciones de red y aislamiento se aplicarán mediante la configuración de ejecución de Podman y serán verificadas mediante pruebas específicas.

## Estado del proyecto

### Sprint E1

| Issue | Descripción                        | Estado    |
| ----- | ---------------------------------- | --------- |
| E1-01 | Definir arquitectura               | Cerrado   |
| E1-02 | Seleccionar modelo GGUF            | Cerrado   |
| E1-03 | Crear Containerfile                | Cerrado   |
| E1-04 | Pruebas de ejecución y aislamiento | Pendiente |

## Imagen actual

Imagen generada:

```text
localhost/local-llm:0.1.0
```

La imagen utiliza un build multi-stage:

```text
Builder
  |
  +-- Compilación de llama.cpp
  |
  v
Runtime
  |
  +-- llama-server
  +-- librerías necesarias
  +-- usuario llama
```

El runtime no contiene las herramientas utilizadas para compilar `llama.cpp`.

## Próximos pasos

1. Ejecutar `llama-server` con un modelo GGUF externo.
2. Configurar el volumen del modelo como `read-only`.
3. Publicar el servicio únicamente en `127.0.0.1:8080`.
4. Bloquear el acceso de red saliente.
5. Aplicar `cap-drop=ALL`.
6. Aplicar `no-new-privileges`.
7. Utilizar filesystem raíz de solo lectura.
8. Validar que el contenedor no pueda acceder al filesystem del host.
9. Ejecutar pruebas de seguridad.
10. Documentar la evidencia de cada control.
11. Exportar la imagen para distribución offline mediante Podman.

## Estructura prevista

```text
local-llm-secure/
├── Containerfile
├── README.md
├── docs/
├── models/
├── reports/
├── scripts/
└── tests/
```

El directorio `models/` no forma parte de la imagen y se utilizará para almacenar los modelos GGUF localmente.

## Filosofía del laboratorio

El proyecto utiliza un enfoque incremental:

```text
Arquitectura
     |
     v
Modelo
     |
     v
Containerfile
     |
     v
Runtime funcional
     |
     v
Aislamiento
     |
     v
Pruebas de seguridad
     |
     v
Evidencia
     |
     v
Imagen portable
```

Cada etapa se implementa, prueba y documenta antes de avanzar a la siguiente.
