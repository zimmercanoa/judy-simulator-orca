-- ============================================================
-- migracion_api_tokens.sql — Tablas para la API REST móvil
-- Ejecutar UNA vez en phpMyAdmin después de JuDyb.sql.
-- Compatible con InfinityFree (sin CREATE DATABASE ni USE).
-- Charset: utf8mb4 | Collation: utf8mb4_unicode_ci | Engine: InnoDB
-- ============================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------
-- Tabla: api_tokens
-- Solo se guarda el hash SHA-256 del token Bearer; el token en
-- claro únicamente lo conoce la app que inició sesión.
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `api_tokens` (
  `id_token`    INT          NOT NULL AUTO_INCREMENT,
  `id_usuario`  INT          NOT NULL,
  `token_hash`  CHAR(64)     NOT NULL COMMENT 'SHA-256 hex del token Bearer',
  `creado_en`   DATETIME     NOT NULL,
  `expira_en`   DATETIME     NOT NULL,
  `ultimo_uso`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id_token`),
  UNIQUE KEY `uq_token_hash` (`token_hash`),
  KEY `idx_token_usuario` (`id_usuario`),
  KEY `idx_token_expira` (`expira_en`),
  CONSTRAINT `fk_api_tokens_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
    ON DELETE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- Tabla: api_rate_limits
-- Ventanas fijas por clave (hash de IP/usuario + endpoint).
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS `api_rate_limits` (
  `clave`          CHAR(64)  NOT NULL COMMENT 'SHA-256 de cubeta + IP o usuario',
  `ventana_inicio` INT       NOT NULL COMMENT 'Unix timestamp de inicio de la ventana',
  `contador`       INT       NOT NULL DEFAULT 0,
  PRIMARY KEY (`clave`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Fin de la migración | JuDy Simulator API
-- ============================================================
