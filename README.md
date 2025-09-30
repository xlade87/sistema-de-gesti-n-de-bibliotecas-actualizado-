# Sistema de Gestión de Biblioteca

## Descripción
Sistema de gestión de biblioteca desarrollado en Python con interfaz gráfica Tkinter y base de datos MySQL. Permite administrar libros, usuarios, autores y préstamos de manera eficiente.

## Características

### Gestión de Libros
- Agregar, buscar, editar y eliminar libros
- Campos: Título, Autor, Género, Año de publicación, ISBN
- Sistema de disponibilidad automática

### Gestión de Usuarios
- Registrar y administrar usuarios
- Campos: Nombre, Email, Teléfono
- Validación de formato de email

### Gestión de Autores
- Registrar información de autores
- Campos: Nombre, Nacionalidad, Fecha de nacimiento
- Selector de fecha integrado

### Sistema de Préstamos
- Realizar préstamos de libros
- Registrar devoluciones
- Control automático de disponibilidad
- Historial de préstamos activos

## Requisitos del Sistema

### Software Requerido
- Python 3.8 o superior
- MySQL Server
- XAMPP, WAMP o servidor MySQL local

### Librerías Python
```bash
pip install mysql-connector-python
pip install tkcalendar
pip install Pillow
```

## Instalación y Configuración

### 1. Configuración de la Base de Datos
El sistema crea automáticamente la base de datos y tablas necesarias. Asegúrate de que MySQL esté ejecutándose.

### 2. Configuración de Conexión
En el archivo principal, verifica los parámetros de conexión en la clase `DatabaseConnection`:

```python
self.connection = mysql.connector.connect(
    host="localhost",
    database="biblioteca_personal",
    user="root",
    password="",  # Tu contraseña de MySQL
    autocommit=True
)
```

### 3. Estructura de la Base de Datos
El sistema crea automáticamente las siguientes tablas:

- **libros**: Almacena información de libros
- **usuarios**: Registro de usuarios de la biblioteca
- **autores**: Información de autores
- **prestamos**: Control de préstamos y devoluciones

## Uso del Sistema

### Pestaña Libros
1. **Agregar Libro**: Completa los campos obligatorios (Título y Autor)
2. **Buscar por ID**: Ingresa el ID para cargar datos existentes
3. **Eliminar**: Elimina un libro usando su ID
4. **Limpiar**: Vacía el formulario

### Pestaña Usuarios
1. **Registrar Usuario**: Completa nombre y email obligatorios
2. **Validación**: Verificación automática de formato de email

### Pestaña Autores
1. **Registrar Autor**: Nombre obligatorio, datos adicionales opcionales
2. **Selector de fecha**: Para fecha de nacimiento

### Pestaña Préstamos
1. **Realizar Préstamo**: Ingresa ID de libro y usuario
2. **Devolución**: Ingresa ID del préstamo a devolver

## Validaciones Implementadas

### Validaciones de Entrada
- Campos obligatorios marcados con *
- Validación de formato de email
- Solo números en campos numéricos
- Validación de año de publicación

### Validaciones de Negocio
- Libro debe estar disponible para préstamo
- No se puede eliminar libros con préstamos activos
- Control de duplicados en emails de usuarios

## Funcionalidades Avanzadas

### Sistema de Imágenes
- Soporte para portadas de libros (JPG, JPEG, PNG, GIF)
- Límite de 2MB por imagen
- Visualización en interfaz

### Interfaz de Usuario
- Diseño con pestañas para mejor organización
- Listas actualizables en tiempo real
- Mensajes de confirmación y error
- Validaciones en tiempo real

## Solución de Problemas

### Error de Conexión a Base de Datos
1. Verifica que MySQL esté ejecutándose
2. Confirma credenciales de acceso
3. Asegúrate de que el puerto 3306 esté disponible

### Problemas con Imágenes
1. Verifica formatos soportados
2. Confirma que el tamaño no exceda 2MB
3. Revisa permisos de archivos

## Estructura del Código

### Clases Principales
- `DatabaseConnection`: Manejo de conexión a BD
- `Validaciones`: Funciones de validación
- `ImagenManager`: Gestión de imágenes

### Funciones Clave
- `guardar_libro()`: Registro de libros
- `realizar_prestamo()`: Control de préstamos
- `actualizar_lista_*()`: Actualización de vistas
