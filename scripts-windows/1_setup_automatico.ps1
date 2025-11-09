# ========================================
# AUTOMATED SETUP SCRIPT (Windows)
# Runs all steps from scratch
# ========================================

$ErrorActionPreference = "Stop"

# Function: check if Docker engine is running
function Test-DockerRunning {
    try {
        docker info 2>$null | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Go to project root (parent folder of this script)
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "========================================="
Write-Host "PROJECT AUTOMATED SETUP"
Write-Host "========================================="
Write-Host ""

# ========================================
# STEP 1: Check prerequisites
# ========================================
Write-Host "[1/7] Checking prerequisites..."

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker CLI is not installed or not in PATH."
    exit 1
}

if (-not (Test-Path "datasets")) {
    Write-Host "ERROR: Folder 'datasets' not found!"
    exit 1
}

if (-not (Test-Path "datasets/sp500_data_part1.csv")) {
    Write-Host "ERROR: File datasets/sp500_data_part1.csv not found!"
    exit 1
}

if (-not (Test-Path "datasets/sp500_data_part2.csv")) {
    Write-Host "ERROR: File datasets/sp500_data_part2.csv not found!"
    exit 1
}

Write-Host "Prerequisites OK."
Write-Host ""

# ========================================
# STEP 2: Ensure Docker engine is running and start container
# ========================================
Write-Host "[2/7] Ensuring Docker engine is running..."

if (-not (Test-DockerRunning)) {
    Write-Host "Docker engine is not running. Trying to start Docker Desktop..."

    $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    if (Test-Path $dockerDesktopPath) {
        Start-Process $dockerDesktopPath | Out-Null
        Write-Host "Waiting up to 90 seconds for Docker to start..."

        $maxSeconds = 90
        $started = $false

        for ($i = 1; $i -le $maxSeconds; $i++) {
            Start-Sleep -Seconds 1
            if (Test-DockerRunning) {
                $started = $true
                break
            }
        }

        if (-not $started) {
            Write-Host "ERROR: Docker engine did not start within 90 seconds."
            Write-Host "Please open Docker Desktop manually, wait until it shows 'Docker is running', and run this script again."
            exit 1
        }
    }
    else {
        Write-Host "ERROR: Docker Desktop executable not found at:"
        Write-Host "  $dockerDesktopPath"
        Write-Host "Start Docker Desktop manually and run this script again."
        exit 1
    }
}

Write-Host "Docker engine is running."
Write-Host ""
Write-Host "[2/7] Starting Docker container with docker compose..."

docker compose down -v 2>$null | Out-Null
docker compose up -d

Write-Host "Container started."
Write-Host ""

# ========================================
# STEP 3: Wait for SQL Server to start
# ========================================
Write-Host "[3/7] Waiting 60 seconds for SQL Server to start..."
Start-Sleep -Seconds 60
Write-Host "Wait complete."
Write-Host ""

Write-Host "Checking SQL Server logs (docker logs sqlserverCC)..."
docker logs sqlserverCC 2>&1 | Select-String "Server is listening" -ErrorAction SilentlyContinue | Out-Null
Write-Host "Log check done."
Write-Host ""

# ========================================
# STEP 4: Copy setup script into container
# ========================================
Write-Host "[4/7] Copying setup script into container..."

if (-not (Test-Path "scripts/1-setup/01_setup_completo.sql")) {
    Write-Host "ERROR: File scripts/1-setup/01_setup_completo.sql not found!"
    exit 1
}

docker cp "scripts/1-setup/01_setup_completo.sql" sqlserverCC:/tmp/01_setup_completo.sql

Write-Host "Setup script copied."
Write-Host ""

# ========================================
# STEP 5: Execute full setup
# ========================================
Write-Host "[5/7] Running full setup inside container..."
Write-Host ""

docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" -C `
    -i /tmp/01_setup_completo.sql

Write-Host ""
Write-Host "Setup execution finished."
Write-Host ""

# ========================================
# STEP 6: Verify installation
# ========================================
Write-Host "[6/7] Verifying installation..."
Write-Host ""

Write-Host "Databases created (master and datasets expected):"
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" -C -h-1 -W `
    -Q "SELECT name FROM sys.databases WHERE name IN ('master', 'datasets') ORDER BY name;"

Write-Host ""
Write-Host "Tables in FinanceDB:"
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" -C -h-1 -W `
    -Q "USE FinanceDB; SELECT name FROM sys.tables WHERE type = 'U' ORDER BY name;"

Write-Host ""
Write-Host "Row count for imported tables in database 'datasets':"
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" -C -h-1 -W `
    -Q "USE datasets;
        SELECT 'SP500_data' AS TableName, COUNT(*) AS TotalRows FROM SP500_data
        UNION ALL
        SELECT 'CSI500' AS TableName, COUNT(*) AS TotalRows FROM CSI500;"

Write-Host ""
Write-Host "Verification finished."
Write-Host ""

# ========================================
# STEP 7: Final information
# ========================================
Write-Host "[7/7] Access information"
Write-Host ""
Write-Host "========================================="
Write-Host "SETUP COMPLETED SUCCESSFULLY"
Write-Host "========================================="
Write-Host ""
Write-Host "DataGrip connection:"
Write-Host "  Host: localhost"
Write-Host "  Port: 1433"
Write-Host "  User: SA"
Write-Host "  Password: Cc202505!"
Write-Host "  Databases: FinanceDB, datasets"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open DataGrip"
Write-Host "  2. Create a new connection using the credentials above"
Write-Host "  3. Check schemas FinanceDB and datasets"
Write-Host "  4. Refresh (F5)"
Write-Host "  5. Run analysis scripts (folder 2-analise)"
Write-Host ""
Write-Host "Useful Docker commands:"
Write-Host "  docker compose ps        # Container status"
Write-Host "  docker compose down      # Stop container"
Write-Host "  docker compose up -d     # Start container"
Write-Host ""
Write-Host "========================================="
