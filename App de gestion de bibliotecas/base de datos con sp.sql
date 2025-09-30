CREATE DATABASE IF NOT EXISTS biblioteca_personal;
USE biblioteca_personal;


-- =============================================
-- TABLAS DE LA BASE DE DATOS
-- =============================================

-- 1. TABLA: autores
CREATE TABLE autores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    nacionalidad VARCHAR(50),
    fecha_nacimiento DATE
);

-- 2. TABLA: libros
CREATE TABLE libros (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(100) NOT NULL,
    autor VARCHAR(100) NOT NULL,
    genero VARCHAR(50),
    año_publicacion INT,
    isbn VARCHAR(20),
    disponible BOOLEAN DEFAULT TRUE
);

-- 3. TABLA: usuarios
CREATE TABLE usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15),
    fecha_registro DATE DEFAULT CURRENT_DATE
);

-- 4. TABLA: prestamos
CREATE TABLE prestamos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    libro_id INT,
    usuario_id INT,
    fecha_prestamo DATE DEFAULT CURRENT_DATE,
    fecha_devolucion DATE,
    devuelto BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (libro_id) REFERENCES libros(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- 5. TABLA: reseñas (extra para completar 5 tablas)
CREATE TABLE reseñas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    libro_id INT,
    usuario_id INT,
    calificacion INT CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario TEXT,
    fecha_reseña DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (libro_id) REFERENCES libros(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =============================================
-- PROCEDIMIENTOS ALMACENADOS
-- =============================================

-- 1. Procedimiento para insertar libro
DELIMITER //
CREATE PROCEDURE sp_InsertarLibro(
    IN p_titulo VARCHAR(100),
    IN p_autor VARCHAR(100),
    IN p_genero VARCHAR(50),
    IN p_anio_publicacion INT,
    IN p_isbn VARCHAR(20)
)
BEGIN
    INSERT INTO libros (titulo, autor, genero, año_publicacion, isbn) 
    VALUES (p_titulo, p_autor, p_genero, p_anio_publicacion, p_isbn);
    
    SELECT CONCAT('Libro "', p_titulo, '" insertado correctamente') AS resultado;
END //
DELIMITER ;

-- 2. Procedimiento para actualizar libro
DELIMITER //
CREATE PROCEDURE sp_ActualizarLibro(
    IN p_id INT,
    IN p_titulo VARCHAR(100),
    IN p_autor VARCHAR(100),
    IN p_genero VARCHAR(50),
    IN p_anio_publicacion INT,
    IN p_isbn VARCHAR(20)
)
BEGIN
    UPDATE libros 
    SET titulo = p_titulo, 
        autor = p_autor, 
        genero = p_genero, 
        año_publicacion = p_anio_publicacion, 
        isbn = p_isbn
    WHERE id = p_id;
    
    SELECT CONCAT('Libro ID ', p_id, ' actualizado correctamente') AS resultado;
END //
DELIMITER ;

-- 3. Procedimiento para eliminar libro
DELIMITER //
CREATE PROCEDURE sp_EliminarLibro(IN p_id INT)
BEGIN
    DECLARE libro_count INT;
    
    -- Verificar si el libro existe
    SELECT COUNT(*) INTO libro_count FROM libros WHERE id = p_id;
    
    IF libro_count = 0 THEN
        SELECT CONCAT('Error: No existe el libro con ID ', p_id) AS resultado;
    ELSE
        -- Verificar si el libro está prestado
        IF EXISTS (SELECT 1 FROM prestamos WHERE libro_id = p_id AND devuelto = FALSE) THEN
            SELECT 'Error: No se puede eliminar un libro que está prestado' AS resultado;
        ELSE
            DELETE FROM libros WHERE id = p_id;
            SELECT CONCAT('Libro ID ', p_id, ' eliminado correctamente') AS resultado;
        END IF;
    END IF;
END //
DELIMITER ;

-- 4. Procedimiento para insertar usuario
DELIMITER //
CREATE PROCEDURE sp_InsertarUsuario(
    IN p_nombre VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefono VARCHAR(15)
)
BEGIN
    -- Verificar si el email ya existe
    IF EXISTS (SELECT 1 FROM usuarios WHERE email = p_email) THEN
        SELECT CONCAT('Error: El email ', p_email, ' ya está registrado') AS resultado;
    ELSE
        INSERT INTO usuarios (nombre, email, telefono) 
        VALUES (p_nombre, p_email, p_telefono);
        
        SELECT CONCAT('Usuario "', p_nombre, '" registrado correctamente') AS resultado;
    END IF;
END //
DELIMITER ;

-- 5. Procedimiento para realizar préstamo
DELIMITER //
CREATE PROCEDURE sp_RealizarPrestamo(
    IN p_libro_id INT,
    IN p_usuario_id INT
)
BEGIN
    DECLARE v_disponible BOOLEAN;
    DECLARE v_libro_titulo VARCHAR(100);
    DECLARE v_usuario_nombre VARCHAR(100);
    
    -- Verificar si el libro existe y está disponible
    SELECT disponible, titulo INTO v_disponible, v_libro_titulo 
    FROM libros WHERE id = p_libro_id;
    
    -- Verificar si el usuario existe
    SELECT nombre INTO v_usuario_nombre FROM usuarios WHERE id = p_usuario_id;
    
    IF v_libro_titulo IS NULL THEN
        SELECT CONCAT('Error: No existe el libro con ID ', p_libro_id) AS resultado;
    ELSEIF v_usuario_nombre IS NULL THEN
        SELECT CONCAT('Error: No existe el usuario con ID ', p_usuario_id) AS resultado;
    ELSEIF NOT v_disponible THEN
        SELECT CONCAT('Error: El libro "', v_libro_titulo, '" no está disponible') AS resultado;
    ELSE
        -- Registrar el préstamo
        INSERT INTO prestamos (libro_id, usuario_id) VALUES (p_libro_id, p_usuario_id);
        
        -- Marcar libro como no disponible
        UPDATE libros SET disponible = FALSE WHERE id = p_libro_id;
        
        SELECT CONCAT('Préstamo realizado: ', v_usuario_nombre, ' -> ', v_libro_titulo) AS resultado;
    END IF;
END //
DELIMITER ;

-- 6. Procedimiento para devolver libro
DELIMITER //
CREATE PROCEDURE sp_DevolverLibro(IN p_prestamo_id INT)
BEGIN
    DECLARE v_libro_id INT;
    DECLARE v_libro_titulo VARCHAR(100);
    DECLARE v_devuelto BOOLEAN;
    
    -- Obtener información del préstamo
    SELECT p.libro_id, l.titulo, p.devuelto INTO v_libro_id, v_libro_titulo, v_devuelto
    FROM prestamos p
    JOIN libros l ON p.libro_id = l.id
    WHERE p.id = p_prestamo_id;
    
    IF v_libro_id IS NULL THEN
        SELECT CONCAT('Error: No existe el préstamo con ID ', p_prestamo_id) AS resultado;
    ELSEIF v_devuelto THEN
        SELECT 'Error: Este préstamo ya fue devuelto' AS resultado;
    ELSE
        -- Marcar préstamo como devuelto
        UPDATE prestamos 
        SET devuelto = TRUE, fecha_devolucion = CURDATE() 
        WHERE id = p_prestamo_id;
        
        -- Marcar libro como disponible
        UPDATE libros SET disponible = TRUE WHERE id = v_libro_id;
        
        SELECT CONCAT('Libro "', v_libro_titulo, '" devuelto correctamente') AS resultado;
    END IF;
END //
DELIMITER ;

-- 7. Procedimiento para insertar autor
DELIMITER //
CREATE PROCEDURE sp_InsertarAutor(
    IN p_nombre VARCHAR(100),
    IN p_nacionalidad VARCHAR(50),
    IN p_fecha_nacimiento DATE
)
BEGIN
    INSERT INTO autores (nombre, nacionalidad, fecha_nacimiento) 
    VALUES (p_nombre, p_nacionalidad, p_fecha_nacimiento);
    
    SELECT CONCAT('Autor "', p_nombre, '" insertado correctamente') AS resultado;
END //
DELIMITER ;

-- 8. Procedimiento para obtener estadísticas
DELIMITER //
CREATE PROCEDURE sp_ObtenerEstadisticas()
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM libros) AS total_libros,
        (SELECT COUNT(*) FROM libros WHERE disponible = TRUE) AS libros_disponibles,
        (SELECT COUNT(*) FROM usuarios) AS total_usuarios,
        (SELECT COUNT(*) FROM prestamos WHERE devuelto = FALSE) AS prestamos_activos,
        (SELECT COUNT(*) FROM autores) AS total_autores,
        (SELECT COUNT(*) FROM reseñas) AS total_reseñas;
END //
DELIMITER ;

-- 9. Procedimiento para buscar libros por título
DELIMITER //
CREATE PROCEDURE sp_BuscarLibrosPorTitulo(IN p_titulo VARCHAR(100))
BEGIN
    SELECT id, titulo, autor, genero, año_publicacion, 
           CASE WHEN disponible THEN 'Sí' ELSE 'No' END AS disponible
    FROM libros 
    WHERE titulo LIKE CONCAT('%', p_titulo, '%')
    ORDER BY titulo;
END //
DELIMITER ;

-- 10. Procedimiento para obtener préstamos activos
DELIMITER //
CREATE PROCEDURE sp_ObtenerPrestamosActivos()
BEGIN
    SELECT p.id, l.titulo, u.nombre, p.fecha_prestamo,
           DATEDIFF(CURDATE(), p.fecha_prestamo) AS dias_transcurridos
    FROM prestamos p
    JOIN libros l ON p.libro_id = l.id
    JOIN usuarios u ON p.usuario_id = u.id
    WHERE p.devuelto = FALSE
    ORDER BY p.fecha_prestamo;
END //
DELIMITER ;

-- 11. Procedimiento para insertar reseña
DELIMITER //
CREATE PROCEDURE sp_InsertarReseña(
    IN p_libro_id INT,
    IN p_usuario_id INT,
    IN p_calificacion INT,
    IN p_comentario TEXT
)
BEGIN
    -- Validar calificación
    IF p_calificacion < 1 OR p_calificacion > 5 THEN
        SELECT 'Error: La calificación debe ser entre 1 y 5' AS resultado;
    ELSE
        INSERT INTO reseñas (libro_id, usuario_id, calificacion, comentario) 
        VALUES (p_libro_id, p_usuario_id, p_calificacion, p_comentario);
        
        SELECT 'Reseña agregada correctamente' AS resultado;
    END IF;
END //
DELIMITER ;

-- =============================================
-- DATOS DE EJEMPLO
-- =============================================

-- Insertar autores
INSERT INTO autores (nombre, nacionalidad, fecha_nacimiento) VALUES
('Gabriel García Márquez', 'Colombiano', '1927-03-06'),
('Isabel Allende', 'Chilena', '1942-08-02'),
('Mario Vargas Llosa', 'Peruano', '1936-03-28'),
('Julio Cortázar', 'Argentino', '1914-08-26'),
('Laura Esquivel', 'Mexicana', '1950-09-30');

-- Insertar libros
INSERT INTO libros (titulo, autor, genero, año_publicacion, isbn, disponible) VALUES
('Cien años de soledad', 'Gabriel García Márquez', 'Realismo mágico', 1967, '978-8437604947', TRUE),
('La casa de los espíritus', 'Isabel Allende', 'Novela', 1982, '978-8401337208', TRUE),
('La ciudad y los perros', 'Mario Vargas Llosa', 'Novela', 1963, '978-8466337241', TRUE),
('Rayuela', 'Julio Cortázar', 'Novela experimental', 1963, '978-8432216460', TRUE),
('Como agua para chocolate', 'Laura Esquivel', 'Novela romántica', 1989, '978-8420472667', TRUE),
('El amor en los tiempos del cólera', 'Gabriel García Márquez', 'Novela romántica', 1985, '978-8437604948', TRUE);

-- Insertar usuarios
INSERT INTO usuarios (nombre, email, telefono, fecha_registro) VALUES
('Ana García', 'ana.garcia@email.com', '555-1234', '2024-01-15'),
('Carlos López', 'carlos.lopez@email.com', '555-5678', '2024-01-20'),
('María Rodríguez', 'maria.rodriguez@email.com', '555-9012', '2024-02-01'),
('Pedro Martínez', 'pedro.martinez@email.com', '555-3456', '2024-02-10');

-- Insertar préstamos
INSERT INTO prestamos (libro_id, usuario_id, fecha_prestamo, fecha_devolucion, devuelto) VALUES
(1, 1, '2024-02-01', '2024-02-15', TRUE),
(2, 2, '2024-02-05', NULL, FALSE),
(3, 3, '2024-02-10', NULL, FALSE);

-- Insertar reseñas
INSERT INTO reseñas (libro_id, usuario_id, calificacion, comentario, fecha_reseña) VALUES
(1, 1, 5, 'Una obra maestra de la literatura latinoamericana', '2024-02-16'),
(1, 2, 4, 'Muy bueno, aunque complejo de seguir', '2024-02-18'),
(2, 3, 5, 'Isabel Allende en su máximo esplendor', '2024-02-20');

-- =============================================
-- VERIFICACIÓN FINAL
-- =============================================

-- Mostrar todas las tablas
SELECT '=== TABLAS CREADAS ===' AS '';
SHOW TABLES;

-- Mostrar procedimientos almacenados
SELECT '=== PROCEDIMIENTOS ALMACENADOS ===' AS '';
SHOW PROCEDURE STATUS WHERE Db = 'biblioteca_personal';

-- Probar un procedimiento de ejemplo
SELECT '=== PRUEBA DE PROCEDIMIENTO ===' AS '';
CALL sp_ObtenerEstadisticas();

-- Mostrar datos de ejemplo
SELECT '=== AUTORES ===' AS '';
SELECT * FROM autores;

SELECT '=== LIBROS ===' AS '';
SELECT * FROM libros;

SELECT '=== USUARIOS ===' AS '';
SELECT * FROM usuarios;

SELECT '=== PRÉSTAMOS ===' AS '';
SELECT * FROM prestamos;

SELECT '=== RESEÑAS ===' AS '';
SELECT * FROM reseñas;