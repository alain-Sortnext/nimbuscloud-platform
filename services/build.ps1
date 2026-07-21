Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  NimbusCloud Services Builder" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan

$services = @(
    @{Name="auth-service"; Port=3003},
    @{Name="booking-api"; Port=3001},
    @{Name="payment-api"; Port=3002},
    @{Name="notification-service"; Port=3004}
)

foreach ($s in $services) {
    Write-Host "`n=== Processing $($s.Name) ===" -ForegroundColor Yellow
    cd $($s.Name)
    
    # Create main.go if it doesn't exist
    if (-not (Test-Path "main.go")) {
        Write-Host "Creating main.go..." -ForegroundColor Green
        $content = @"
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "$($s.Port)"
    }

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, "$($s.Name) Service")
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, `{"status":"healthy","service":"$($s.Name)"}`)
    })

    http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, `{"status":"ready","service":"$($s.Name)"}`)
    })

    log.Printf("$($s.Name) starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
"@
        $content | Out-File -FilePath main.go -Encoding utf8
    }
    
    # Initialize go module if needed
    if (-not (Test-Path "go.mod")) {
        Write-Host "Initializing go module..." -ForegroundColor Green
        go mod init "nimbuscloud/$($s.Name)"
    }
    
    # Tidy dependencies
    Write-Host "Tidying dependencies..." -ForegroundColor Green
    go mod tidy
    
    # Create Dockerfile if it doesn't exist
    if (-not (Test-Path "Dockerfile")) {
        Write-Host "Creating Dockerfile..." -ForegroundColor Green
        $dockerfile = @'
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM alpine:3.18
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE ' + $s.Port + @'
CMD ["./main"]
'@
        $dockerfile | Out-File -FilePath Dockerfile -Encoding utf8
    }
    
    # Build Docker image
    Write-Host "Building Docker image..." -ForegroundColor Green
    docker build -t "nimbuscloud/$($s.Name):2.4.1" .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $($s.Name) built successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ $($s.Name) build failed!" -ForegroundColor Red
    }
    
    cd ..
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "All services processed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Images built:" -ForegroundColor Yellow
docker images | findstr nimbuscloud

Write-Host ""
Write-Host "To restart Kubernetes pods, run:" -ForegroundColor Yellow
Write-Host "  kubectl delete pods --all -n default" -ForegroundColor White
Write-Host "  kubectl get pods -n default -w" -ForegroundColor White
