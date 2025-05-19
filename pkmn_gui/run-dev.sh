flutter run -d web-server \
    --dart-define=API_URL="https://${1:-127.0.0.1}:8081" \
    --web-hostname=0.0.0.0 \
    --web-port=5005 \
    --web-tls-cert-path=dev-cert/localhost+3.pem \
    --web-tls-cert-key-path=dev-cert/localhost+3-key.pem