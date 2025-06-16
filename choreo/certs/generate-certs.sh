#!/bin/bash

# Fixed seed for consistent certificate generation
SEED="LDFArchitecture2024"

# Generate server certificate
echo "Generating server certificate..."
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout server.key \
  -out server.crt \
  -days 365 \
  -config openssl.cnf \
  -rand /dev/urandom \
  -seed "$SEED"

# Generate client certificate
echo "Generating client certificate..."
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout client.key \
  -out client.crt \
  -days 365 \
  -config openssl.cnf \
  -rand /dev/urandom \
  -seed "$SEED"

# Create truststore
echo "Creating truststore..."
openssl pkcs12 -export \
  -out truststore.p12 \
  -inkey client.key \
  -in client.crt \
  -password pass:ballerina

# Set secure permissions
echo "Setting secure permissions..."
chmod 600 *.key
chmod 644 *.crt
chmod 600 *.p12

echo "Certificate generation complete!"
echo "Generated files:"
echo "- server.key: Server private key"
echo "- server.crt: Server certificate"
echo "- client.key: Client private key"
echo "- client.crt: Client certificate"
echo "- truststore.p12: Trust store for client verification" 