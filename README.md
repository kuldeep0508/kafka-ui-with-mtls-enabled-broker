# 🔐 Kafka UI with mTLS Enabled Broker + ACLs

This repository contains a fully working local Kafka setup using Docker Compose, with the following features:
- Mutual TLS (mTLS) enabled between Kafka brokers and clients
- ACL-based authorization
- Integration with Kafka UI for a user-friendly web interface
- Easy-to-run certificate generation script

## ✅ Problem Statement

Setting up a secure Kafka environment locally with mTLS and ACLs can be complex. We wanted to validate the entire chain including:
- SSL handshake validation with broker/client certificates
- Enforcing ACL-based access
- Using Kafka UI with a custom keystore/truststore to visualize the cluster securely

And… of course, it should all work out of the box 💥

---

## 🛠️ Getting Started

### 1. Clone this repository
```bash
git clone https://github.com/kuldeep0508/kafka-ui-with-mtls-enabled-broker.git
cd kafka-ui-with-mtls-enabled-broker
```

---

### 2. Generate Certificates

Use the bundled script to generate required certs for the broker and client (Kafka UI):

```bash
chmod +x generate-certs-full.sh
./generate-certs-full.sh
```

This will generate all certificates in the `secrets/` directory:
- `kafka.server.keystore.jks`, `kafka.server.truststore.jks`
- `kafka.client.keystore.jks`, `kafka.client.truststore.jks`
- CA cert, CSRs, and plain-text client config

---

### 3. Start the Services

```bash
docker compose -f dockercompose-mtls.yml up -d
```

This brings up:
- Zookeeper
- Kafka broker with mTLS + ACL enabled
- Kafka UI secured via client certificate

---

### 4. Access Kafka UI

Navigate to: [http://localhost:8080](http://localhost:8080)

Kafka UI is now connected to your secure Kafka broker with mutual TLS 🎉

---

## 🔐 Managing Topics and ACLs

### 💡 Exec into Kafka container:
```bash
docker exec -it kafka1 bash
```

### ✅ Create a Topic:
```bash
kafka-topics --bootstrap-server kafka1:9092 \
  --create --topic my-topic \
  --partitions 1 --replication-factor 1 \
  --command-config /etc/kafka/secrets/client.properties
```

### ✅ Add an ACL for your user (CN from client cert):
```bash
kafka-acls --bootstrap-server kafka1:9092 \
  --add --allow-principal "User:CN=kafka-ui" \
  --operation All --topic my-topic \
  --command-config /etc/kafka/secrets/client.properties
```

You can also use prefixes:
```bash
kafka-acls --bootstrap-server kafka1:9092 \
  --add --allow-principal "User:CN=kafka-ui" \
  --operation All --topic my-prefix-* \
  --command-config /etc/kafka/secrets/client.properties
```

---

## 🔍 Debugging Tips

If you see:
```text
SSL handshake failed / No name matching kafka1 found
```
Make sure:
- Kafka broker cert has `kafka1` in its `SAN` field (already done in `generate-certs-full.sh`)
- Kafka UI or CLI uses proper truststore and disables hostname verification

---

## 📁 Project Structure

```
.
├── dockercompose-mtls.yml
├── generate-certs-full.sh
├── secrets/
│   ├── kafka.{client,server}.*.jks
│   ├── ca.crt, *.csr, *.crt
│   └── client.properties
└── ...
```

---

## 🧠 Learnings

Setting up secure Kafka locally isn't just plug-and-play. It took some effort to:
- Generate proper SAN in the server certificate
- Configure Kafka UI to speak SSL with correct keystore/truststore
- Avoid `javax.net.ssl.SSLHandshakeException` traps due to hostname mismatches

But now, it just works 🔥

---
