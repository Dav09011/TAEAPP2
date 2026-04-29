# Admin Feature

Este feature concentra la logica del panel administrativo.

## Primer corte aplicado

La pantalla de sucursales ya no resuelve su logica principal directamente con Firebase.

Ahora el flujo se divide asi:

1. `presentation/controllers/branches_controller.dart`
2. `domain/repositories/branch_repository.dart`
3. `data/repositories/firebase_branch_repository.dart`

## Responsabilidad del repositorio de sucursales

- listar sucursales del administrador actual
- crear sucursales
- renombrar sucursales
- borrar sucursales
- sincronizar grupos y usuarios afectados

## Regla de migracion para admin

Las pantallas pueden conservar:
- dialogs
- snackbars
- navegacion

Pero no deben conservar:
- queries de Firestore
- reglas de duplicados
- borrado en cascada
- sincronizaciones masivas

## Impacto del corte

`branch_selection_tab.dart` dejo de tener:
- `main()`
- `MaterialApp`
- acceso directo a Firebase Auth
- acceso directo a Firestore para CRUD de sucursales

La pantalla ahora solo:
- muestra estados
- abre dialogs
- decide navegacion a grupos

## Segundo corte aplicado

La pantalla de grupos ahora sigue el mismo patron.

Archivos base:

1. `presentation/controllers/branch_groups_controller.dart`
2. `domain/repositories/group_repository.dart`
3. `data/repositories/firebase_group_repository.dart`

Responsabilidades migradas:

- listar grupos por sucursal
- crear grupos
- renombrar grupos
- borrar grupos
- limpiar alumnos, actividades y secciones al borrar
- sincronizar usuarios afectados

## Tercer corte aplicado

La pantalla de actividades ya no persiste cambios directamente contra Firebase.

Archivos base:

1. `presentation/controllers/activities_controller.dart`
2. `domain/repositories/activity_repository.dart`
3. `data/repositories/firebase_activity_repository.dart`

Responsabilidades migradas:

- listar secciones de cinta
- listar actividades por seccion
- crear actividades
- crear secciones
- renombrar actividades
- renombrar secciones
- borrar actividades

## Cuarto corte aplicado

`activity_detail_screen.dart` ya no usa Firestore directamente para el CRUD
de ejercicios.

Archivos base:

1. `presentation/controllers/activity_detail_controller.dart`
2. extension del contrato `activity_repository.dart`
3. extension de `firebase_activity_repository.dart`

Responsabilidades migradas:

- agregar ejercicios
- renombrar ejercicios
- eliminar ejercicios

Pendiente a futuro:

- decidir como persistir multimedia de ejercicios

## Quinto corte aplicado

`students_section.dart` ya no lista ni borra alumnos directamente con Firebase.

Archivos base:

1. `presentation/controllers/students_controller.dart`
2. `domain/repositories/student_repository.dart`
3. `data/repositories/firebase_student_repository.dart`

Responsabilidades migradas:

- listar alumnos por grupo
- agrupar alumnos por cinta
- filtrar alumnos por nombre
- borrar alumnos seleccionados por lote

## Sexto corte aplicado

`profile_screen.dart` ya no lee, actualiza ni cierra sesion directamente con
Firebase.

Archivos base:

1. `presentation/controllers/profile_controller.dart`
2. `domain/repositories/profile_repository.dart`
3. `data/repositories/firebase_profile_repository.dart`

Responsabilidades migradas:

- observar el perfil actual
- cargar el perfil para edicion
- actualizar datos personales
- solicitar cambio de correo
- cerrar sesion

## Septimo corte aplicado

`wallet_screen.dart` ya no obtiene directamente desde Firebase:
- el saludo del administrador
- el listado de sucursales para el selector

Archivos base:

1. `presentation/controllers/wallet_controller.dart`
2. `domain/repositories/wallet_repository.dart`
3. `data/repositories/firebase_wallet_repository.dart`

Responsabilidades migradas:

- cargar nombre del administrador
- observar sucursales del administrador
- mantener sucursal seleccionada en estado de presentacion

## Octavo corte aplicado

`wallet_fees.dart` y `wallet_student_status.dart` dejaron de ser pantallas
vacias y ahora preparan la siguiente fase del modulo financiero con logica
fuera de la UI.

Archivos base:

1. `presentation/controllers/wallet_fees_controller.dart`
2. `presentation/controllers/wallet_student_status_controller.dart`
3. `domain/entities/wallet_fee_configuration.dart`
4. `domain/entities/student_billing_status.dart`

Responsabilidades migradas:

- modelar el catalogo inicial de tarifas
- modelar estados de pago de alumnos
- mantener filtros de busqueda en presentacion
- dejar la UI lista para reemplazar datos semilla por repositorios reales
