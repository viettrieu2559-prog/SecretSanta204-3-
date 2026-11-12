-- =============================================================================
-- CƠ SỞ DỮ LIỆU MICROSOFT SQL SERVER: SECRET SANTA 2026 (BẢN PRO CHUẨN SSMS)
-- Mở file này trong SQL Server Management Studio (SSMS) và nhấn F5 (Execute)
-- Hoặc chạy trực tiếp bằng file run_sqlserver_backend.bat
-- =============================================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'SecretSanta2026')
BEGIN
    CREATE DATABASE [SecretSanta2026];
END
GO

USE [SecretSanta2026];
GO

-- =============================================================================
-- 1. CÁC BẢNG DỮ LIỆU CHUẨN QUAN HỆ (XEM & CHỈNH SỬA TRỰC TIẾP TRÊN APP SQL SERVER)
-- =============================================================================

-- Bảng 1: Danh sách Sinh Viên tham gia
IF OBJECT_ID(N'dbo.SinhVien', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SinhVien (
        MSSV            NVARCHAR(50)   NOT NULL PRIMARY KEY,
        HoTen           NVARCHAR(255)  NOT NULL,
        DiemBXH         INT            NOT NULL DEFAULT 150,
        MaThiepChuc     NVARCHAR(50)   NULL,
        Wishlist        NVARCHAR(MAX)  NULL,
        Blacklist       NVARCHAR(MAX)  NULL,
        AnhSelfieBase64 NVARCHAR(MAX)  NULL,
        ThoiGianCapNhat NVARCHAR(100)  NULL,
        UpdatedAt       DATETIME2      NOT NULL DEFAULT SYSDATETIME()
    );
END
GO

-- Bảng 2: Check-in Đã Chuẩn Bị Xong Quà (Chỉ BTC xem & duyệt)
IF OBJECT_ID(N'dbo.CheckinQua', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CheckinQua (
        MSSV             NVARCHAR(50)   NOT NULL PRIMARY KEY,
        HoTen            NVARCHAR(255)  NULL,
        GhiChuQua        NVARCHAR(MAX)  NULL,
        TrangThaiDuyet   NVARCHAR(50)   NOT NULL DEFAULT N'PENDING',
        AnhQuaBase64     NVARCHAR(MAX)  NULL,
        ThoiGianCheckin  NVARCHAR(100)  NULL,
        UpdatedAt        DATETIME2      NOT NULL DEFAULT SYSDATETIME()
    );
END
GO

-- Bảng 3: Bảng Tin Khoảnh Khắc Giáng Sinh (Public Feed)
IF OBJECT_ID(N'dbo.BangTin', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BangTin (
        PostId            NVARCHAR(120)  NOT NULL PRIMARY KEY,
        MSSV              NVARCHAR(50)   NULL,
        HoTen             NVARCHAR(255)  NULL,
        Caption           NVARCHAR(MAX)  NULL,
        LuotThich         INT            NOT NULL DEFAULT 1,
        AnhBaiDangBase64  NVARCHAR(MAX)  NULL,
        ThoiGianDang      NVARCHAR(100)  NULL,
        CreatedAt         DATETIME2      NOT NULL DEFAULT SYSDATETIME()
    );
END
GO

-- Bảng 4: Kênh Chat Chung Sự Kiện
IF OBJECT_ID(N'dbo.KenhChat', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.KenhChat (
        MsgId         NVARCHAR(120)  NOT NULL PRIMARY KEY,
        MSSV          NVARCHAR(50)   NULL,
        HoTen         NVARCHAR(255)  NULL,
        NoiDungChat   NVARCHAR(MAX)  NULL,
        ThoiGianNhan  NVARCHAR(100)  NULL,
        CreatedAt     DATETIME2      NOT NULL DEFAULT SYSDATETIME()
    );
END
GO

-- Bảng 5: Bảng Đồng Bộ API Tổng Hợp (Tương thích 100% với REST API của Web)
IF OBJECT_ID(N'dbo.SecretSantaRows', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SecretSantaRows (
        id          INT IDENTITY(1,1) PRIMARY KEY,
        thoigian    NVARCHAR(255)  NOT NULL DEFAULT N'',
        hoten       NVARCHAR(500)  NOT NULL DEFAULT N'',
        phongban    NVARCHAR(MAX)  NULL,
        wishlist    NVARCHAR(MAX)  NULL,
        blacklist   NVARCHAR(MAX)  NULL,
        created_at  DATETIME2      NOT NULL DEFAULT SYSDATETIME()
    );
    CREATE INDEX IX_SecretSantaRows_Hoten ON dbo.SecretSantaRows(hoten);
    CREATE INDEX IX_SecretSantaRows_Thoigian ON dbo.SecretSantaRows(thoigian);
END
GO

-- Dữ liệu mẫu khởi tạo (nếu bảng đang trống)
IF NOT EXISTS (SELECT 1 FROM dbo.SecretSantaRows)
BEGIN
    INSERT INTO dbo.SecretSantaRows (thoigian, hoten, phongban, wishlist, blacklist)
    VALUES
    (N'16:20:13 12-11-2026 | TH07941 | W01 | 150PTS', N'TH07941 - Triệu Lân Việt', N'', N'123', N'123'),
    (N'14:23:57 12-11-2026 | TH00001 | W02 | 150PTS', N'TH00001 - Nguyễn Tiến Thành', N'', N'Canon r5, rf 70-200', N'Đồ dễ vỡ'),
    (N'16:28:55 12-11-2026 | TH00002 | W03 | 150PTS', N'TH00002 - Nguyễn Tiến Long', N'', N'Gấu bông Noel', N'Mùi bưởi');

    INSERT INTO dbo.SinhVien (MSSV, HoTen, DiemBXH, MaThiepChuc, Wishlist, Blacklist, AnhSelfieBase64, ThoiGianCapNhat)
    VALUES
    (N'TH07941', N'Triệu Lân Việt', 150, N'W01', N'123', N'123', N'', N'16:20:13 12-11-2026'),
    (N'TH00001', N'Nguyễn Tiến Thành', 150, N'W02', N'Canon r5, rf 70-200', N'Đồ dễ vỡ', N'', N'14:23:57 12-11-2026'),
    (N'TH00002', N'Nguyễn Tiến Long', 150, N'W03', N'Gấu bông Noel', N'Mùi bưởi', N'', N'16:28:55 12-11-2026');
END
GO

PRINT N'✅ Đã khởi tạo thành công CSDL SecretSanta2026 gồm 5 Bảng chuẩn trên SQL Server!';
GO
