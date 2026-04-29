# Arquitectura de `lib/`

Este documento define la estructura objetivo del proyecto.

## Capas

### `app/`

Responsabilidad:
- arranque de la aplicacion
- configuracion global
- router
- temas globales

Regla:
- aqui no va logica de negocio

### `core/`

Responsabilidad:
- servicios tecnicos compartidos
- errores comunes
- modelos base
- utilidades de infraestructura

Regla:
- `core/` no debe depender de features concretas

### `features/`

Responsabilidad:
- modulos del negocio
- cada feature vive con sus capas `data`, `domain` y `presentation`

Regla:
- una feature puede usar `core/`
- una feature no debe hablar directamente con otra salvo por contratos claros

### `shared/`

Responsabilidad:
- componentes visuales o helpers realmente neutrales

Regla:
- si un widget conoce alumnos, sucursales, pagos o autenticacion, no va aqui

## Reglas operativas

1. Solo existe un punto de entrada real: `lib/main.dart`.
2. Ninguna pantalla nueva debe declarar `main()` ni `MaterialApp`.
3. Ninguna pantalla nueva debe usar `FirebaseAuth.instance` o `FirebaseFirestore.instance` directamente.
4. La UI llama a controladores.
5. Los controladores llaman a repositorios.
6. Los repositorios usan servicios de `core/`.

## Zona legacy

Todavia existen archivos legacy en:
- `lib/login_page.dart`
- `lib/modules/`
- `lib/pruebas/`

Mientras migramos:
- se pueden seguir usando
- pero toda logica nueva debe nacer en `features/`

## Estrategia de migracion

Orden recomendado:

1. `features/auth`
2. `features/licensing` para el flujo comercial de administradores
3. `features/admin` para sucursales y wallet
4. `features/student`

Cada migracion debe cumplir este criterio:
- la pantalla queda mas delgada
- Firebase sale de la UI
- la navegacion se centraliza o se reduce
- si un flujo aun no tiene backend final, su estado temporal debe vivir en un
  controlador o entidad, no incrustado en widgets grandes

## Patron aplicado en auth

La migracion de autenticacion ya tiene un patron base:

1. `presentation/controllers/*` maneja estado de carga y mensajes.
2. `domain/entities/*` define los datos del flujo.
3. `data/repositories/*` conoce Firebase.
4. Las pantallas legacy pueden seguir en `modules/` mientras deleguen la logica.

Esto permite migrar sin hacer un "big bang" de carpetas.

## Patron aplicado en admin

La migracion de sucursales sigue una variante del mismo patron:

1. La pantalla conserva dialogs y navegacion.
2. El controlador concentra estado visual y acciones de usuario.
3. El repositorio concentra CRUD, validaciones y sincronizaciones complejas.

Esto es especialmente importante cuando una accion impacta varias colecciones.
