
#!/bin/bash
set -e

CERTS_DIR=./secrets
CA_KEY=$CERTS_DIR/ca.key
CA_CERT=$CERTS_DIR/ca.crt

mkdir -p $CERTS_DIR

echo "🔐 [1/10] Generating CA..."
openssl req -new -x509 -keyout $CA_KEY -out $CA_CERT -days 365 -nodes -subj "/CN=Local Kafka CA"

echo "🖥️ [2/10] Generating Kafka server key and CSR..."
openssl req -newkey rsa:2048 -nodes -keyout $CERTS_DIR/kafka.server.key -out $CERTS_DIR/kafka.server.csr -subj "/CN=localhost"

echo "📜 [3/10] Signing Kafka server cert with CA..."
openssl x509 -req -in $CERTS_DIR/kafka.server.csr -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out $CERTS_DIR/kafka.server.crt -days 365

echo "👤 [4/10] Generating Kafka UI client key and CSR..."
openssl req -newkey rsa:2048 -nodes -keyout $CERTS_DIR/kafka.client.key -out $CERTS_DIR/kafka.client.csr -subj "/CN=kafka-ui"

echo "📜 [5/10] Signing Kafka UI client cert with CA..."
openssl x509 -req -in $CERTS_DIR/kafka.client.csr -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out $CERTS_DIR/kafka.client.crt -days 365

echo "📦 [6/10] Converting server cert to PKCS12..."
openssl pkcs12 -export -in $CERTS_DIR/kafka.server.crt -inkey $CERTS_DIR/kafka.server.key \
  -out $CERTS_DIR/kafka.server.p12 -name kafka-server -CAfile $CA_CERT -caname root -password pass:password

echo "📦 [7/10] Converting client cert to PKCS12..."
openssl pkcs12 -export -in $CERTS_DIR/kafka.client.crt -inkey $CERTS_DIR/kafka.client.key \
  -out $CERTS_DIR/kafka.client.p12 -name kafka-client -CAfile $CA_CERT -caname root -password pass:password

echo "🔧 [8/10] Creating server keystore (JKS)..."
keytool -importkeystore \
  -deststorepass password -destkeypass password \
  -destkeystore $CERTS_DIR/kafka.server.keystore.jks \
  -srckeystore $CERTS_DIR/kafka.server.p12 \
  -srcstoretype PKCS12 -srcstorepass password \
  -alias kafka-server

echo "🔧 [9/10] Creating client keystore (JKS)..."
keytool -importkeystore \
  -deststorepass password -destkeypass password \
  -destkeystore $CERTS_DIR/kafka.client.keystore.jks \
  -srckeystore $CERTS_DIR/kafka.client.p12 \
  -srcstoretype PKCS12 -srcstorepass password \
  -alias kafka-client

echo "🔐 [10/10] Creating truststores..."
keytool -import -trustcacerts -alias CARoot -file $CA_CERT -keystore $CERTS_DIR/kafka.server.truststore.jks -storepass password -noprompt
keytool -import -trustcacerts -alias CARoot -file $CA_CERT -keystore $CERTS_DIR/kafka.client.truststore.jks -storepass password -noprompt

echo "📂 Creating passwords.txt for Kafka..."
echo "password" > $CERTS_DIR/passwords.txt

echo "✅ All certificates, keystores, and truststores generated in $CERTS_DIR"
