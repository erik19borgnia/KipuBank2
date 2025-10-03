# TP Final del Módulo 2 del curso de Ethereum

Este contrato es un proyecto de banco seguro, con las siguientes características:
 - Hay un límite de extracción establecido (s_extractionLimit) fijo en 10'000'000'000'000 wei. (10 billones, o 10 trillions)
 - Hay un límite de depósitos (s_bankCap) definido en el despliegue.
 - Hay un conteo de depósitos y extracciones
 - Si hay algún error, se revierte con un error personalizado

## Despliegue

Usando Remix, copiar el repositorio y desplegar utilizando RemixVM para testear, o Injected Provider con Metamask para alguna testnet o red principal.\
Obviamente también se puede usar algún otro método de despliegue.\
**Se debe asignar un límite para el balance de una cuenta al desplegar, se recomienda que sea al menos de 10000000000000 (10 billones o 10 trillions)**

## Interacciones con el contrato

**deposit** Función payable para depositar una cantidad. Debe ser mayor a 0 y no aumentar el balance por encima del límite permitido\
**withdraw(uint amount)** Función que permite extraer, siempre que sea menor o igual al límite de extracción (por defecto 10 billones / 10 trillions), y al balance de la cuenta\
**getBalance, getDeposits, getWithdrawals** Funciones external view para ver informaciones de las cuentas. Se incluye una versión que permite al dueño auditar cualquier cuenta con un parámetro address.