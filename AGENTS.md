# AGENTS.md — Reglas del proyecto para agentes de IA

Este archivo define el contexto y las reglas obligatorias que cualquier agente de IA
(Claude Code, Gemini u otro) debe respetar al leer, generar o modificar código en este
proyecto. Toda propuesta del agente queda sujeta a revisión y aprobación humana antes de
integrarse.

## 1. Descripción del proyecto

Aplicación móvil offline en Flutter para la gestión de inventarios de electrodomésticos.
Permite registrar, consultar, editar y eliminar productos, con persistencia local en
SQLite mediante el paquete `sqflite`.

- Lenguaje: Dart (SDK `^3.9.0`).
- Dependencias de producción: `sqflite`, `path`. No se agregan dependencias nuevas sin
  aprobación explícita.
- Interfaz: Material 3 (`useMaterial3: true`).

## 2. Arquitectura en cuatro capas

El código de `lib/` se organiza en cuatro capas con dependencias en un solo sentido
(Datasource → Repositorio → Presentación; el Modelo es compartido por todas):

| Capa | Ubicación | Responsabilidad |
|---|---|---|
| 1. Datasource | `lib/data/datasources/` | Conexión física a `inventario.db`, sentencias DDL/DML y catálogo inicial. Única capa que importa `sqflite`. |
| 2. Modelo | `lib/data/models/` | Entidad inmutable `Electrodomestico`, serialización `toMap`/`fromMap`, categorías y umbral de stock bajo. |
| 3. Repositorio | `lib/data/repositories/` | Mediador entre la fuente de datos y la presentación; valida reglas de negocio antes de persistir. |
| 4. Presentación | `lib/presentation/` (`controllers/`, `screens/`, `widgets/`) | Estado reactivo con `ChangeNotifier` y vistas que lo consumen mediante `ListenableBuilder`. |

Reglas:

- Las pantallas y widgets **nunca** importan `sqflite` ni `DatabaseHelper`; acceden a los
  datos únicamente a través del controlador.
- El controlador depende del repositorio, nunca del datasource.
- La inyección de dependencias se realiza manualmente en `lib/main.dart`.
- No se crean carpetas adicionales (`core/`, `domain/`, etc.) sin aprobación humana.

## 3. Base de datos SQLite

- Archivo: `inventario.db`. Tabla: `electrodomesticos`.
- Versión actual del esquema: **3** (`DatabaseHelper._version`). Todo cambio de esquema
  exige incrementar la versión y agregar la migración correspondiente en `_onUpgrade`.
- Restricciones de integridad obligatorias:
  - `precio REAL NOT NULL CHECK (precio > 0)`
  - `stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)`
- `DatabaseHelper` es un Singleton que almacena el `Future<Database>` para garantizar una
  única apertura de la base de datos.
- Las consultas usan parámetros (`whereArgs`); no se concatenan valores en el SQL.

### Catálogo inicial (seeding)

Definido en `lib/data/datasources/datos_iniciales.dart` y cargado dentro de una
transacción. Contiene **exactamente 3 productos**, uno por cada estado de alerta:

| Producto | Marca | Categoría | Precio (COP) | Stock | Estado |
|---|---|---|---|---|---|
| Aire acondicionado | Mabe | Climatización | 1.000.000 | 0 | Agotado |
| Nevera | Mabe | Refrigeración | 200.000 | 2 | Stock bajo |
| Televisor 50' | LG | Entretenimiento | 1.850.000 | 5 | Sin alerta |

## 4. Reglas de negocio

- **Stock bajo:** `stock <= Electrodomestico.umbralStockBajo` (3 unidades).
- **Agotado:** `stock == 0`; el botón de decremento se deshabilita.
- **No negatividad:** el stock nunca puede ser negativo. Se valida en el controlador,
  en el repositorio y en la base de datos (`CHECK`).
- **Categorías:** solo se admiten las definidas en `Electrodomestico.categorias`; los
  filtros de la interfaz se derivan de esa constante.
- **Búsqueda:** insensible a mayúsculas y tildes, sobre nombre y marca.

## 5. Pautas de comentarios y documentación

- Todos los comentarios se redactan en **español técnico y formal**, en tercera persona
  o forma impersonal ("Inserta el registro…", "Se almacena el Future…").
- No se permiten comentarios coloquiales, en primera persona ni en plural ("hacemos",
  "vamos a", "ojo", etc.).
- Las clases y métodos públicos se documentan con `///` (compatible con `dart doc`);
  los comentarios internos usan `//`.
- Los comentarios explican el **porqué** de una decisión, no repiten lo que el código ya
  dice.
- Los textos visibles para el usuario (etiquetas, mensajes) pueden tutear al usuario.

## 6. Verificación obligatoria

Antes de entregar cualquier cambio, el agente debe ejecutar y reportar:

```bash
flutter analyze          # sin problemas
flutter test             # todas las pruebas aprobadas
flutter build apk --release
```

Las pruebas unitarias de la lógica de negocio se encuentran en `test/unit_test.dart`.

## 7. Límites del agente

- No ejecutar `git push`, no modificar remotos ni la configuración de Git.
- No eliminar datos, pruebas ni archivos sin aprobación humana.
- Las decisiones de arquitectura, esquema de datos y reglas de negocio son
  responsabilidad del desarrollador humano.
