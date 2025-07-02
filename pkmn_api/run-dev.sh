DATABASE_PATH=../Database/base.db \
CERT=dev-certs/localhost+3.pem \
CERT_KEY=dev-certs/localhost+3-key.pem \
EXPOSE_IP="0.0.0.0" \
RUST_LOG=info \
cargo run
