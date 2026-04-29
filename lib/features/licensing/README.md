# Licensing Feature

Este feature queda reservado para el flujo comercial de licencias de administrador.

## Alcance actual

- catalogo local de planes
- pantalla de seleccion de licencia
- navegacion posterior al registro de administrador

## Objetivo futuro

Separar este flujo de `auth` cuando exista:
- compra o renovacion de licencia
- validacion de plan activo
- onboarding comercial
- sincronizacion con backend o pasarela de pago

## Regla temporal

Mientras la compra aun no exista:
- `auth` puede navegar a este feature
- `licensing` no debe contener logica de autenticacion
- los planes deben vivir fuera del widget
