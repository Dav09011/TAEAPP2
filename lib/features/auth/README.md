# Auth Feature

Este modulo es el nuevo punto de referencia para migrar autenticacion.

## Objetivo

Separar la UI de:
- Firebase Auth
- Firestore
- navegacion basada en rol
- validaciones de formularios

## Estructura

- `data/`: implementaciones concretas que hablan con Firebase.
- `domain/`: contratos y entidades del negocio.
- `presentation/`: pantallas, controladores y widgets del modulo.

## Regla de migracion

Cuando una pantalla de autenticacion necesite leer o escribir datos:

1. La pantalla llama a un controlador.
2. El controlador usa un repositorio del dominio.
3. El repositorio usa servicios de `core/`.

La pantalla no debe:
- usar `FirebaseAuth.instance`
- usar `FirebaseFirestore.instance`
- conocer nombres de colecciones como `usuarios`

## Primer corte aplicado

`login_page.dart` ya no resuelve el inicio de sesion directamente con Firebase.
Ahora delega el flujo a `presentation/controllers/login_controller.dart`.

## Segundo corte aplicado

- `forgot_password_page.dart` ahora usa `presentation/controllers/forgot_password_controller.dart`.
- `register_teacher_student.dart` ahora usa `presentation/controllers/register_account_controller.dart`.
- Los datos compartidos de registro ahora viajan en `domain/entities/registration_request.dart`.

## Tercer corte aplicado

- `register_admin.dart` ahora usa el mismo `RegisterAccountController`.
- `licenses.dart` dejo de ser una mini-app aislada y ahora funciona como pantalla normal del flujo.
- El flujo admin ya no dispara dos navegaciones distintas al mismo tiempo.

## Contratos nuevos

- `AuthRepository.register()` ya no recibe parametros sueltos.
- Ahora recibe un `RegistrationRequest` para evitar firmas distintas por pantalla.

## Pantallas legacy pendientes

- `type_register.dart`
- revisar si `licenses.dart` debe vivir en auth o en onboarding comercial

Estas siguen dentro de `modules/`, pero ya con menos deuda de integracion.
La idea es repetir el mismo patron antes de tocar otros modulos.
