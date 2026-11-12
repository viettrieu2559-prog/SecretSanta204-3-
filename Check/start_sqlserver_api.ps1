# =============================================================================
# BACKEND API KẾT NỐI TRỰC TIẾP SQL SERVER CHO SECRET SANTA 2026
# Tự động đồng bộ 5 bảng trong SQL Server Management Studio (SSMS):
#   - dbo.SinhVien
#   - dbo.CheckinQua
#   - dbo.BangTin
#   - dbo.KenhChat
#   - dbo.SecretSantaRows
# =============================================================================
param(
    [string]$Server = "",
    [string]$Database = "SecretSanta2026",
    [string]$User = "",
    [string]$Password = "",
    [int]$Port = 8080
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Data
Add-Type -AssemblyName System.Web

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " 🎄 TRẠM DỮ LIỆU SQL SERVER — SECRET SANTA 2026 BACKEND API 🎄" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

function Test-SqlConn([string]$connStr) {
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
        $conn.Open()
        $conn.Close()
        return $true
    } catch {
        return $false
    }
}

# 1. Tự động dò tìm SQL Server trên máy
$masterConnStr = ""
$activeServerLabel = ""

$candidateServers = @("localhost", "(local)", ".\SQLEXPRESS", "localhost\SQLEXPRESS", "127.0.0.1")
$candidateSaPasswords = @("123456", "1234", "123", "sa", "admin", "12345", "Password123")

if ($Server -ne "") {
    $tryStr = if ($User -ne "") {
        "Server=$Server;Database=master;User Id=$User;Password=$Password;Connection Timeout=3;"
    } else {
        "Server=$Server;Database=master;Integrated Security=True;Connection Timeout=3;"
    }
    if (Test-SqlConn $tryStr) {
        $masterConnStr = $tryStr
        $activeServerLabel = $Server
    }
}

if ($masterConnStr -eq "") {
    Write-Host "🔍 Đang tự động kết nối vào ứng dụng SQL Server trên máy tính..." -ForegroundColor Gray
    foreach ($srv in $candidateServers) {
        $winAuth = "Server=$srv;Database=master;Integrated Security=True;Connection Timeout=2;"
        if (Test-SqlConn $winAuth) {
            $masterConnStr = $winAuth
            $activeServerLabel = "$srv (Windows Auth)"
            break
        }
        foreach ($pw in $candidateSaPasswords) {
            $sqlAuth = "Server=$srv;Database=master;User Id=sa;Password=$pw;Connection Timeout=2;"
            if (Test-SqlConn $sqlAuth) {
                $masterConnStr = $sqlAuth
                $activeServerLabel = "$srv (SQL Auth: sa)"
                break
            }
        }
        if ($masterConnStr -ne "") { break }
    }
}

$useSqlServer = $false
$dbConnStr = ""

if ($masterConnStr -ne "") {
    try {
        Write-Host "✅ Đã kết nối SQL Server thành công: $activeServerLabel" -ForegroundColor Green
        $initConn = New-Object System.Data.SqlClient.SqlConnection($masterConnStr)
        $initConn.Open()
        $createDbCmd = $initConn.CreateCommand()
        $createDbCmd.CommandText = "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'$Database') CREATE DATABASE [$Database];"
        [void]$createDbCmd.ExecuteNonQuery()
        $initConn.Close()

        $dbConnStr = $masterConnStr -replace "Database=master;", "Database=$Database;"
        $dbConn = New-Object System.Data.SqlClient.SqlConnection($dbConnStr)
        $dbConn.Open()

        $schemaCmd = $dbConn.CreateCommand()
        $schemaCmd.CommandText = @"
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

IF NOT EXISTS (SELECT 1 FROM dbo.SecretSantaRows)
BEGIN
    INSERT INTO dbo.SecretSantaRows (thoigian, hoten, phongban, wishlist, blacklist)
    VALUES
    (N'16:20:13 12-11-2026 | TH07941 | W01 | 150PTS', N'TH07941 - Triệu Lân Việt', N'', N'123', N'123'),
    (N'14:23:57 12-11-2026 | TH00001 | W02 | 150PTS', N'TH00001 - Nguyễn Tiến Thành', N'', N'Canon r5, rf 70-200', N'Đồ dễ vỡ'),
    (N'16:28:55 12-11-2026 | TH00002 | W03 | 150PTS', N'TH00002 - Nguyễn Tiến Long', N'', N'Gấu bông Noel', N'Mùi bưởi');
END
"@
        [void]$schemaCmd.ExecuteNonQuery()
        $dbConn.Close()
        $useSqlServer = $true
        Write-Host "✅ CSDL [$Database] với 5 Bảng (SinhVien, CheckinQua, BangTin, KenhChat, SecretSantaRows) đã sẵn sàng trong SSMS!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Lỗi khởi tạo bảng SQL Server: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Hàm tự động đồng bộ từ bảng tổng SecretSantaRows sang 4 bảng chuyên biệt trong SQL Server (để xem đẹp trong SSMS)
function Sync-NormalizedSqlTables([System.Data.SqlClient.SqlConnection]$conn) {
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT id, thoigian, hoten, phongban, wishlist, blacklist FROM dbo.SecretSantaRows ORDER BY id ASC"
        $reader = $cmd.ExecuteReader()
        $all = New-Object System.Collections.Generic.List[object]
        while ($reader.Read()) {
            $all.Add(@{
                thoigian  = [string]$reader["thoigian"]
                hoten     = [string]$reader["hoten"]
                phongban  = if ($reader.IsDBNull(3)) { "" } else { [string]$reader["phongban"] }
                wishlist  = if ($reader.IsDBNull(4)) { "" } else { [string]$reader["wishlist"] }
                blacklist = if ($reader.IsDBNull(5)) { "" } else { [string]$reader["blacklist"] }
            })
        }
        $reader.Close()

        $clearCmd = $conn.CreateCommand()
        $clearCmd.CommandText = "DELETE FROM dbo.SinhVien; DELETE FROM dbo.CheckinQua; DELETE FROM dbo.BangTin; DELETE FROM dbo.KenhChat;"
        [void]$clearCmd.ExecuteNonQuery()

        foreach ($r in $all) {
            $h = ($r.hoten).Trim()
            $t = ($r.thoigian).Trim()
            if ($h.StartsWith("CHECKIN_GIFT |")) {
                $parts = $h.Split("|") | ForEach-Object { $_.Trim() }
                $mssv = if ($parts.Count -gt 1) { $parts[1].ToUpper() } else { "UNKNOWN" }
                $name = if ($parts.Count -gt 2) { $parts[2] } else { "" }
                $c = $conn.CreateCommand()
                $c.CommandText = @"
MERGE dbo.CheckinQua AS target
USING (SELECT @mssv AS MSSV) AS src ON target.MSSV = src.MSSV
WHEN MATCHED THEN UPDATE SET HoTen=@name, GhiChuQua=@note, TrangThaiDuyet=@st, AnhQuaBase64=@img, ThoiGianCheckin=@time, UpdatedAt=SYSDATETIME()
WHEN NOT MATCHED THEN INSERT (MSSV, HoTen, GhiChuQua, TrangThaiDuyet, AnhQuaBase64, ThoiGianCheckin) VALUES (@mssv, @name, @note, @st, @img, @time);
"@
                [void]$c.Parameters.AddWithValue("@mssv", $mssv)
                [void]$c.Parameters.AddWithValue("@name", $name)
                [void]$c.Parameters.AddWithValue("@note", $r.wishlist)
                [void]$c.Parameters.AddWithValue("@st", $(if ($r.blacklist -match "APPROVED") { "APPROVED" } else { "PENDING" }))
                [void]$c.Parameters.AddWithValue("@img", $r.phongban)
                [void]$c.Parameters.AddWithValue("@time", $t)
                [void]$c.ExecuteNonQuery()
            } elseif ($h.StartsWith("POST_FEED |")) {
                $parts = $h.Split("|") | ForEach-Object { $_.Trim() }
                $postId = if ($parts.Count -ge 4) { $parts[1] } else { "POST_" + [guid]::NewGuid().ToString("N").Substring(0,8) }
                $mssv = if ($parts.Count -ge 4) { $parts[2] } elseif ($parts.Count -gt 1) { $parts[1] } else { "" }
                $name = if ($parts.Count -ge 4) { $parts[3] } elseif ($parts.Count -gt 2) { $parts[2] } else { "" }
                $likes = 1
                if ($r.blacklist -match "LIKES:(\d+)") { $likes = [int]$Matches[1] }
                $c = $conn.CreateCommand()
                $c.CommandText = @"
MERGE dbo.BangTin AS target
USING (SELECT @pid AS PostId) AS src ON target.PostId = src.PostId
WHEN MATCHED THEN UPDATE SET MSSV=@mssv, HoTen=@name, Caption=@cap, LuotThich=@likes, AnhBaiDangBase64=@img, ThoiGianDang=@time
WHEN NOT MATCHED THEN INSERT (PostId, MSSV, HoTen, Caption, LuotThich, AnhBaiDangBase64, ThoiGianDang) VALUES (@pid, @mssv, @name, @cap, @likes, @img, @time);
"@
                [void]$c.Parameters.AddWithValue("@pid", $postId)
                [void]$c.Parameters.AddWithValue("@mssv", $mssv)
                [void]$c.Parameters.AddWithValue("@name", $name)
                [void]$c.Parameters.AddWithValue("@cap", $r.wishlist)
                [void]$c.Parameters.AddWithValue("@likes", $likes)
                [void]$c.Parameters.AddWithValue("@img", $r.phongban)
                [void]$c.Parameters.AddWithValue("@time", $t)
                [void]$c.ExecuteNonQuery()
            } elseif ($h.StartsWith("CHAT_MSG |")) {
                $parts = $h.Split("|") | ForEach-Object { $_.Trim() }
                $msgId = if ($parts.Count -gt 1) { $parts[1] } else { "MSG_" + [guid]::NewGuid().ToString("N").Substring(0,8) }
                $mssv = if ($parts.Count -gt 2) { $parts[2] } else { "" }
                $name = if ($parts.Count -gt 3) { $parts[3] } else { "" }
                $c = $conn.CreateCommand()
                $c.CommandText = @"
MERGE dbo.KenhChat AS target
USING (SELECT @mid AS MsgId) AS src ON target.MsgId = src.MsgId
WHEN MATCHED THEN UPDATE SET MSSV=@mssv, HoTen=@name, NoiDungChat=@msg, ThoiGianNhan=@time
WHEN NOT MATCHED THEN INSERT (MsgId, MSSV, HoTen, NoiDungChat, ThoiGianNhan) VALUES (@mid, @mssv, @name, @msg, @time);
"@
                [void]$c.Parameters.AddWithValue("@mid", $msgId)
                [void]$c.Parameters.AddWithValue("@mssv", $mssv)
                [void]$c.Parameters.AddWithValue("@name", $name)
                [void]$c.Parameters.AddWithValue("@msg", $r.wishlist)
                [void]$c.Parameters.AddWithValue("@time", $t)
                [void]$c.ExecuteNonQuery()
            } else {
                $mssv = ""
                $cleanName = $h
                if ($h -match "^([A-Za-z0-9]{3,15})\s*-\s*(.+)$") {
                    $mssv = $Matches[1].ToUpper()
                    $cleanName = $Matches[2].Trim()
                }
                if ($mssv -eq "") { $mssv = "USER_" + [Math]::Abs($h.GetHashCode()) }
                $pts = 150
                if ($t -match "(\d+)PTS") { $pts = [int]$Matches[1] }
                $wishId = "W01"
                if ($t -match "(W\d{2,3})") { $wishId = $Matches[1] }
                $cleanTime = ($t.Split("|")[0]).Trim()

                $c = $conn.CreateCommand()
                $c.CommandText = @"
MERGE dbo.SinhVien AS target
USING (SELECT @mssv AS MSSV) AS src ON target.MSSV = src.MSSV
WHEN MATCHED THEN UPDATE SET HoTen=@name, DiemBXH=@pts, MaThiepChuc=@wid, Wishlist=@wish, Blacklist=@black, AnhSelfieBase64=@img, ThoiGianCapNhat=@time, UpdatedAt=SYSDATETIME()
WHEN NOT MATCHED THEN INSERT (MSSV, HoTen, DiemBXH, MaThiepChuc, Wishlist, Blacklist, AnhSelfieBase64, ThoiGianCapNhat) VALUES (@mssv, @name, @pts, @wid, @wish, @black, @img, @time);
"@
                [void]$c.Parameters.AddWithValue("@mssv", $mssv)
                [void]$c.Parameters.AddWithValue("@name", $cleanName)
                [void]$c.Parameters.AddWithValue("@pts", $pts)
                [void]$c.Parameters.AddWithValue("@wid", $wishId)
                [void]$c.Parameters.AddWithValue("@wish", $r.wishlist)
                [void]$c.Parameters.AddWithValue("@black", $r.blacklist)
                [void]$c.Parameters.AddWithValue("@img", $r.phongban)
                [void]$c.Parameters.AddWithValue("@time", $cleanTime)
                [void]$c.ExecuteNonQuery()
            }
        }
    } catch {
        Write-Host "[WARN] Đồng bộ bảng phụ: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

if ($useSqlServer) {
    $syncConn = New-Object System.Data.SqlClient.SqlConnection($dbConnStr)
    $syncConn.Open()
    Sync-NormalizedSqlTables $syncConn
    $syncConn.Close()
}

# 3. Khởi chạy HTTP REST API Server
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host ""
Write-Host "🚀 Server SQL Server API đang chạy tại: http://localhost:$Port/api/v1/secret-santa" -ForegroundColor Green
Write-Host "🌐 Bạn có thể dùng trên Live Server (127.0.0.1:5500) hoặc mở: http://localhost:$Port/index.html" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray

function Send-JsonResponse($response, [int]$statusCode, [string]$jsonText) {
    $response.StatusCode = $statusCode
    $response.ContentType = "application/json; charset=utf-8"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonText)
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.OutputStream.Close()
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response

    $res.Headers.Add("Access-Control-Allow-Origin", "*")
    $res.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS")
    $res.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Accept, Authorization")

    if ($req.HttpMethod -eq "OPTIONS") {
        $res.StatusCode = 204
        $res.OutputStream.Close()
        continue
    }

    $path = $req.Url.AbsolutePath

    try {
        if (-not $path.StartsWith("/api/")) {
            $relPath = $path.TrimStart("/")
            if ($relPath -eq "") { $relPath = "index.html" }
            $localFile = Join-Path $PSScriptRoot $relPath
            if (Test-Path $localFile -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($localFile).ToLower()
                $mime = switch ($ext) {
                    ".html" { "text/html; charset=utf-8" }
                    ".jpg"  { "image/jpeg" }
                    ".jpeg" { "image/jpeg" }
                    ".png"  { "image/png" }
                    ".js"   { "application/javascript; charset=utf-8" }
                    ".css"  { "text/css; charset=utf-8" }
                    default { "application/octet-stream" }
                }
                $res.StatusCode = 200
                $res.ContentType = $mime
                $fileBytes = [System.IO.File]::ReadAllBytes($localFile)
                $res.ContentLength64 = $fileBytes.Length
                $res.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
                $res.OutputStream.Close()
                continue
            }
        }

        if ($path -eq "/api/v1/secret-santa/status" -and $req.HttpMethod -eq "GET") {
            $conn = New-Object System.Data.SqlClient.SqlConnection($dbConnStr)
            $conn.Open()
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "SELECT COUNT(*) FROM dbo.SecretSantaRows"
            $count = [int]$cmd.ExecuteScalar()
            $conn.Close()

            $statusObj = @{
                ok = $true
                engine = "SQL Server"
                server = $activeServerLabel
                database = $Database
                totalRows = $count
            }
            Send-JsonResponse $res 200 ($statusObj | ConvertTo-Json -Compress)
            continue
        }

        if ($path -eq "/api/v1/secret-santa" -and $req.HttpMethod -eq "GET") {
            $conn = New-Object System.Data.SqlClient.SqlConnection($dbConnStr)
            $conn.Open()
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "SELECT id, thoigian, hoten, phongban, wishlist, blacklist FROM dbo.SecretSantaRows ORDER BY id ASC"
            $reader = $cmd.ExecuteReader()

            $rows = New-Object System.Collections.Generic.List[object]
            while ($reader.Read()) {
                $rows.Add([ordered]@{
                    id        = $reader["id"]
                    thoigian  = [string]$reader["thoigian"]
                    hoten     = [string]$reader["hoten"]
                    phongban  = if ($reader.IsDBNull(3)) { "" } else { [string]$reader["phongban"] }
                    wishlist  = if ($reader.IsDBNull(4)) { "" } else { [string]$reader["wishlist"] }
                    blacklist = if ($reader.IsDBNull(5)) { "" } else { [string]$reader["blacklist"] }
                })
            }
            $reader.Close()
            $conn.Close()

            $json = ConvertTo-Json -InputObject @($rows) -Depth 4 -Compress
            if ([string]::IsNullOrWhiteSpace($json)) { $json = "[]" }
            if (-not $json.StartsWith("[")) { $json = "[$json]" }
            Send-JsonResponse $res 200 $json
            continue
        }

        if ($path -eq "/api/v1/secret-santa" -and $req.HttpMethod -eq "POST") {
            $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
            $bodyText = $sr.ReadToEnd()
            $sr.Close()

            $parsed = ConvertFrom-Json $bodyText
            $itemsToInsert = @()
            if ($null -ne $parsed.data) {
                if ($parsed.data -is [System.Array]) { $itemsToInsert = $parsed.data } else { $itemsToInsert = @($parsed.data) }
            } elseif ($parsed -is [System.Array]) {
                $itemsToInsert = $parsed
            } else {
                $itemsToInsert = @($parsed)
            }

            $conn = New-Object System.Data.SqlClient.SqlConnection($dbConnStr)
            $conn.Open()
            $inserted = 0
            foreach ($item in $itemsToInsert) {
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = @"
INSERT INTO dbo.SecretSantaRows (thoigian, hoten, phongban, wishlist, blacklist)
VALUES (@thoigian, @hoten, @phongban, @wishlist, @blacklist)
"@
                [void]$cmd.Parameters.Add("@thoigian", [System.Data.SqlDbType]::NVarChar, 255)
                [void]$cmd.Parameters.Add("@hoten", [System.Data.SqlDbType]::NVarChar, 500)
                [void]$cmd.Parameters.Add("@phongban", [System.Data.SqlDbType]::NVarChar, -1)
                [void]$cmd.Parameters.Add("@wishlist", [System.Data.SqlDbType]::NVarChar, -1)
                [void]$cmd.Parameters.Add("@blacklist", [System.Data.SqlDbType]::NVarChar, -1)

                $cmd.Parameters["@thoigian"].Value = [string]($item.thoigian)
                $cmd.Parameters["@hoten"].Value    = [string]($item.hoten)
                $cmd.Parameters["@phongban"].Value = [string]($item.phongban)
                $cmd.Parameters["@wishlist"].Value = [string]($item.wishlist)
                $cmd.Parameters["@blacklist"].Value= [string]($item.blacklist)

                $inserted += $cmd.ExecuteNonQuery()
            }
            Sync-NormalizedSqlTables $conn
            $conn.Close()

            Write-Host "[SQL INSERT] Đã lưu $inserted bản ghi vào SQL Server" -ForegroundColor Green
            Send-JsonResponse $res 201 (@{ created = $inserted } | ConvertTo-Json -Compress)
            continue
        }

        if ($path.StartsWith("/api/v1/secret-santa/") -and ($req.HttpMethod -eq "PATCH" -or $req.HttpMethod -eq "PUT")) {
            $segments = $path.Substring("/api/v1/secret-santa/".Length).Split("/", 2)
            $colName = $segments[0].ToLower()
            $rawVal = if ($segments.Length -gt 1) { [System.Uri]::UnescapeDataString($segments[1]) } else { "" }

            if ($colName -notin @("hoten", "thoigian", "id")) {
                Send-JsonResponse $res 400 '{"error":"Invalid column"}'
                continue
            }

            $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
            $bodyText = $sr.ReadToEnd()
            $sr.Close()

            $parsed = ConvertFrom-Json $bodyText
            $dataObj = if ($null -ne $parsed.data) { $parsed.data } else { $parsed }

            $setClauses = New-Object System.Collections.Generic.List[string]
            $conn = New-Object System.Data.SqlClient.SqlConnection($dbConnStr)
            $conn.Open()
            $cmd = $conn.CreateCommand()

            foreach ($prop in @("thoigian", "hoten", "phongban", "wishlist", "blacklist")) {
                if ($null -ne $dataObj.$prop) {
                    $setClauses.Add("$prop = @$prop")
                    $size = if ($prop -eq "thoigian") { 255 } elseif ($prop -eq "hoten") { 500 } else { -1 }
                    [void]$cmd.Parameters.Add("@$prop", [System.Data.SqlDbType]::NVarChar, $size)
                    $cmd.Parameters["@$prop"].Value = [string]($dataObj.$prop)
                }
            }

            $updated = 0
            if ($setClauses.Count -gt 0) {
                $cmd.CommandText = "UPDATE dbo.SecretSantaRows SET " + ($setClauses -join ", ") + " WHERE $colName = @matchVal"
                [void]$cmd.Parameters.Add("@matchVal", [System.Data.SqlDbType]::NVarChar, 500)
                $cmd.Parameters["@matchVal"].Value = $rawVal
                $updated = $cmd.ExecuteNonQuery()
            }
            Sync-NormalizedSqlTables $conn
            $conn.Close()

            Write-Host "[SQL UPDATE] Đã cập nhật $updated bản ghi ($colName = $rawVal)" -ForegroundColor Cyan
            Send-JsonResponse $res 200 (@{ updated = $updated } | ConvertTo-Json -Compress)
            continue
        }

        if ($path.StartsWith("/api/v1/secret-santa/") -and $req.HttpMethod -eq "DELETE") {
            $segments = $path.Substring("/api/v1/secret-santa/".Length).Split("/", 2)
            $colName = $segments[0].ToLower()
            $rawVal = if ($segments.Length -gt 1) { [System.Uri]::UnescapeDataString($segments[1]) } else { "" }

            if ($colName -notin @("hoten", "thoigian", "id")) {
                Send-JsonResponse $res 400 '{"error":"Invalid column"}'
                continue
            }

            $conn = New-Object System.Data.SqlClient.SqlConnection($dbConnStr)
            $conn.Open()
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "DELETE FROM dbo.SecretSantaRows WHERE $colName = @matchVal"
            [void]$cmd.Parameters.Add("@matchVal", [System.Data.SqlDbType]::NVarChar, 500)
            $cmd.Parameters["@matchVal"].Value = $rawVal
            $deleted = $cmd.ExecuteNonQuery()
            Sync-NormalizedSqlTables $conn
            $conn.Close()

            Write-Host "[SQL DELETE] Đã xóa $deleted bản ghi ($colName = $rawVal)" -ForegroundColor Yellow
            Send-JsonResponse $res 200 (@{ deleted = $deleted } | ConvertTo-Json -Compress)
            continue
        }

        Send-JsonResponse $res 404 '{"error":"Not Found"}'
    } catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        Send-JsonResponse $res 500 (@{ error = $_.Exception.Message } | ConvertTo-Json -Compress)
    }
}
