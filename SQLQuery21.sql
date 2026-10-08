-- =========================================================================
-- 0. ПОДГОТОВКА: Создание папки для данных (если её нет)
-- =========================================================================
-- Примечание: SQL Server не умеет создавать папки на диске через T-SQL.
-- Убедитесь, что папка C:\SQLData\ существует, или замените путь ниже.

USE master;
GO

-- =========================================================================
-- 1. ВОССТАНОВЛЕНИЕ БАЗЫ ДАННЫХ AdventureWorks2019
-- =========================================================================
-- Внимание: Файл AdventureWorks2019.bak должен находиться в C:\SQLData\
-- Если он лежит в другом месте, измените путь в DISK = ...

RESTORE DATABASE AdventureWorks2019
FROM DISK = 'C:\SQLData\AdventureWorks2019.bak'
WITH MOVE 'AdventureWorks2019' TO 'C:\SQLData\AdventureWorks2019.mdf',
MOVE 'AdventureWorks2019_log' TO 'C:\SQLData\AdventureWorks2019_log.ldf',
REPLACE; -- REPLACE перезапишет базу, если она уже существует
GO

-- =========================================================================
-- 2. СОЗДАНИЕ ФАЙЛОВЫХ ГРУПП И ФАЙЛОВ
-- =========================================================================
-- Создаем две новые файловые группы. В них не должно быть таблиц PRIMARY.

-- Группа 1: FG_Data1
ALTER DATABASE AdventureWorks2019 ADD FILEGROUP FG_Data1;
GO
ALTER DATABASE AdventureWorks2019 
ADD FILE (
    NAME = 'AdventureWorks2019_Data1', 
    FILENAME = 'C:\SQLData\AdventureWorks2019_Data1.ndf', 
    SIZE = 5MB, 
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5MB
) TO FILEGROUP FG_Data1;
GO

-- Группа 2: FG_Data2
ALTER DATABASE AdventureWorks2019 ADD FILEGROUP FG_Data2;
GO
ALTER DATABASE AdventureWorks2019 
ADD FILE (
    NAME = 'AdventureWorks2019_Data2', 
    FILENAME = 'C:\SQLData\AdventureWorks2019_Data2.ndf', 
    SIZE = 5MB, 
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5MB
) TO FILEGROUP FG_Data2;
GO

-- =========================================================================
-- 3. СОЗДАНИЕ ТАБЛИЦ СО СЖИМАЕМЫМИ (SPARSE) СТОЛБЦАМИ
-- =========================================================================
USE AdventureWorks2019;
GO

-- Таблица 1: Продажи (Sparse columns для редко заполняемых данных)
CREATE TABLE dbo.SalesSparse1 (
    SalesID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    SaleDate DATE NOT NULL,
    Amount MONEY NOT NULL,
    DiscountPercent DECIMAL(5,2) SPARSE NULL, -- Сжимаемый столбец
    PromoCode VARCHAR(50) SPARSE NULL,        -- Сжимаемый столбец
    Comments VARCHAR(255) SPARSE NULL,        -- Сжимаемый столбец
    RegionID INT SPARSE NULL                  -- Сжимаемый столбец
) ON FG_Data1; -- Помещаем в новую файловую группу
GO

-- Таблица 2: Логи изменений (Sparse columns)
CREATE TABLE dbo.AuditLogSparse1 (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(100) NOT NULL,
    ActionType VARCHAR(20) NOT NULL,
    LogDate DATETIME NOT NULL,
    OldValue VARCHAR(MAX) SPARSE NULL,
    NewValue VARCHAR(MAX) SPARSE NULL,
    ChangedBy INT SPARSE NULL,
    IPAddress VARCHAR(45) SPARSE NULL
) ON FG_Data1;
GO

-- Таблица 3: Профили пользователей (Sparse columns)
CREATE TABLE dbo.UserProfilesSparse (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    LastLogin DATETIME NOT NULL,
    PhoneNumber VARCHAR(20) SPARSE NULL,
    Address VARCHAR(255) SPARSE NULL,
    Bio TEXT SPARSE NULL,
    SocialMediaLink VARCHAR(255) SPARSE NULL
) ON FG_Data2; -- Помещаем во вторую файловую группу
GO

-- Таблица 4: Инвентаризация (Sparse columns)
CREATE TABLE dbo.InventorySparse (
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    ItemName VARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    LastChecked DATETIME NOT NULL,
    LocationCode VARCHAR(20) SPARSE NULL,
    BatchNumber VARCHAR(50) SPARSE NULL,
    ExpiryDate DATE SPARSE NULL,
    SupplierNotes VARCHAR(MAX) SPARSE NULL
) ON FG_Data2;
GO

-- Таблица 5: Настройки системы (Sparse columns)
CREATE TABLE dbo.SystemSettingsSparse (
    SettingID INT IDENTITY(1,1) PRIMARY KEY,
    SettingKey VARCHAR(50) NOT NULL,
    SettingValue VARCHAR(255) NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    ModifiedBy INT SPARSE NULL,
    OldValue VARCHAR(255) SPARSE NULL,
    Description VARCHAR(MAX) SPARSE NULL,
    IsEncrypted BIT SPARSE NULL
) ON FG_Data1;
GO

-- Таблица 6: Геолокация (Sparse columns)
CREATE TABLE dbo.GeoLocationsSparse (
    LocationID INT IDENTITY(1,1) PRIMARY KEY,
    CityName VARCHAR(100) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    Latitude DECIMAL(9,6) NOT NULL,
    Longitude DECIMAL(9,6) NOT NULL,
    Altitude INT SPARSE NULL,
    Population BIGINT SPARSE NULL,
    TimeZone VARCHAR(50) SPARSE NULL,
    IsCapital BIT SPARSE NULL
) ON FG_Data2;
GO

-- =========================================================================
-- 4. ЗАПОЛНЕНИЕ ТАБЛИЦ ДАННЫМИ (INSERT)
-- =========================================================================
-- Добавляем по несколько строк в каждую таблицу

-- 1. SalesSparse1
INSERT INTO dbo.SalesSparse1 (ProductID, SaleDate, Amount, DiscountPercent, PromoCode, Comments, RegionID)
VALUES 
(101, '2023-10-01', 1500.00, 10.00, 'SALE10', 'Первый заказ', 1),
(102, '2023-10-02', 2000.00, NULL, NULL, NULL, 2),
(103, '2023-10-03', 500.00, 5.00, NULL, NULL, NULL);

-- 2. AuditLogSparse1
INSERT INTO dbo.AuditLogSparse1 (TableName, ActionType, LogDate, OldValue, NewValue, ChangedBy, IPAddress)
VALUES 
('Users', 'UPDATE', GETDATE(), 'OldName', 'NewName', 1, '192.168.1.1'),
('Orders', 'INSERT', GETDATE(), NULL, 'NewOrder', 2, NULL);

-- 3. UserProfilesSparse
INSERT INTO dbo.UserProfilesSparse (Username, Email, LastLogin, PhoneNumber, Address, Bio, SocialMediaLink)
VALUES 
('john_doe', 'john@example.com', GETDATE(), '+123456789', '123 Main St', 'Люблю SQL', 'twitter.com/john'),
('jane_smith', 'jane@example.com', GETDATE(), NULL, NULL, NULL, NULL);

-- 4. InventorySparse
INSERT INTO dbo.InventorySparse (ItemName, Quantity, LastChecked, LocationCode, BatchNumber, ExpiryDate, SupplierNotes)
VALUES 
('Ноутбук', 50, GETDATE(), 'A1', 'BATCH001', '2025-01-01', 'Хрупкий'),
('Монитор', 100, GETDATE(), NULL, NULL, NULL, NULL);

-- 5. SystemSettingsSparse
INSERT INTO dbo.SystemSettingsSparse (SettingKey, SettingValue, ModifiedDate, ModifiedBy, OldValue, Description, IsEncrypted)
VALUES 
('Theme', 'Dark', GETDATE(), 1, 'Light', 'Тема оформления', 0),
('Language', 'RU', GETDATE(), NULL, NULL, NULL, NULL);

-- 6. GeoLocationsSparse
INSERT INTO dbo.GeoLocationsSparse (CityName, CountryCode, Latitude, Longitude, Altitude, Population, TimeZone, IsCapital)
VALUES 
('Москва', 'RU', 55.7558, 37.6173, 156, 12500000, 'MSK', 1),
('Санкт-Петербург', 'RU', 59.9343, 30.3351, NULL, NULL, 'MSK', 0);

PRINT 'Все задачи выполнены успешно!';
GO