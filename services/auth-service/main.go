package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"

    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/secretsmanager"
)

// SecretData represents the structure of our secret
type SecretData struct {
    DBPassword string `json:"DB_PASSWORD"`
}

// getSecretValue retrieves a secret from AWS Secrets Manager
func getSecretValue(secretName string) (*SecretData, error) {
    sess := session.Must(session.NewSession())
    sm := secretsmanager.New(sess, &aws.Config{Region: aws.String("eu-west-2")})

    input := &secretsmanager.GetSecretValueInput{
        SecretId: aws.String(secretName),
    }

    result, err := sm.GetSecretValue(input)
    if err != nil {
        return nil, fmt.Errorf("failed to get secret: %w", err)
    }

    var secretData SecretData
    err = json.Unmarshal([]byte(*result.SecretString), &secretData)
    if err != nil {
        return nil, fmt.Errorf("failed to parse secret: %w", err)
    }

    return &secretData, nil
}

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "3003"
    }

    // Retrieve DB password from Secrets Manager
    secret, err := getSecretValue("nimbuscloud/db-password")
    if err != nil {
        log.Printf("WARNING: Could not retrieve secret from Secrets Manager: %v", err)
        log.Println("Falling back to environment variable DB_PASSWORD")
    } else {
        log.Printf("✅ Successfully retrieved DB password from Secrets Manager")
        log.Printf("DB Password retrieved (length: %d)", len(secret.DBPassword))
        // Store in environment for use by application
        os.Setenv("DB_PASSWORD", secret.DBPassword)
    }

    // Health endpoints
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, "Auth Service (Secure - Secrets Manager)")
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, `{"status":"healthy","service":"auth-service","secrets-manager":"enabled"}`)
    })

    http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, `{"status":"ready","service":"auth-service"}`)
    })

    log.Printf("Auth Service starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
