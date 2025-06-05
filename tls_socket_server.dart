// tls_socket_server.dart
import 'dart:io';
import 'dart:convert'; // For utf8 encoding/decoding
import 'package:crypto/crypto.dart'; // Import the crypto package

void main() async {
  // Define certificate and key paths
  final serverCertPath = 'certs/server.crt';
  final serverKeyPath = 'certs/server.key';
  final caCertPath = 'certs/ca.crt'; // CA certificate to verify client certificates

  final serverHost = 'atsign.test';
  final serverPort = 8443;

  try {
    // 1. Create a SecurityContext for the server
    final securityContext = SecurityContext()
      // Load the server's certificate chain (public key)
      ..useCertificateChain(serverCertPath)
      // Load the server's private key
      ..usePrivateKey(serverKeyPath)
      // Set the client authorities. This tells the server which CA
      // it trusts to sign client certificates. For mTLS, this is crucial.
      ..setClientAuthorities(caCertPath);

    // 2. Bind the server to a secure socket port
    final server = await SecureServerSocket.bind(
      serverHost,
      serverPort, // Port for TLS socket
      securityContext,
      requestClientCertificate: true, // IMPORTANT: Require client certificates for mTLS
      requireClientCertificate: true, // Also require it, otherwise handshake might proceed without client cert
    );

    print('mTLS TLS Socket Server listening on ${server.address.host}:${server.port}');

    // 3. Handle incoming secure socket connections
    await for (SecureSocket socket in server) {
      print('\n--- New connection from ${socket.remoteAddress.address}:${socket.remotePort} ---');

      // Verify client certificate details
      final x509 = socket.peerCertificate;

      if (x509 != null) {
        // Calculate SHA-256 fingerprint from the PEM string
        final sha256Fingerprint = sha256.convert(utf8.encode(x509.pem)).toString();

        print('  Client Certificate Subject: ${x509.subject}');
        print('  Client Certificate Issuer: ${x509.issuer}');
        print('  Client Certificate Valid From: ${x509.startValidity}');
        print('  Client Certificate Valid To: ${x509.endValidity}');
        print('  Client Certificate Fingerprint (SHA-256): $sha256Fingerprint'); // Use calculated fingerprint

        // Write a welcome message to the client
        final welcomeMessage = 'Server: Hello, client! Your certificate subject is: ${x509.subject}\n';
        socket.write(utf8.encode(welcomeMessage));

        // Listen for data from the client
        socket.listen(
          (List<int> data) {
            final message = utf8.decode(data).trim();
            print('  Received from client: "$message"');
            // Echo back the received message
            socket.write(utf8.encode('Server Echo: "$message"\n'));
          },
          onDone: () {
            print('  Client disconnected.');
            socket.destroy(); // Ensure socket is closed
          },
          onError: (error) {
            print('  Error on socket: $error');
            socket.destroy();
          },
        );
      } else {
        print('  Unauthorized: Client certificate not provided or not verified. Closing connection.');
        final errorMessage = 'Unauthorized: Client certificate required.\n';
        socket.write(utf8.encode(errorMessage));
        socket.destroy(); // Destroy connection if client cert is missing/invalid
      }
    }
  } catch (e) {
    print('Error starting or running server: $e');
    if (e is HandshakeException) {
      print('TLS Handshake failed. This often indicates a certificate issue (e.g., client did not present a trusted cert).');
    } else if (e is TlsException) {
      print('TLS Error: ${e.message}');
    } else if (e is FileSystemException) {
      print('File System Error: Could not read certificate/key file. Check paths and permissions.');
    } else if (e is SocketException && e.osError?.errorCode == 48) { // Error code 48 is "Address already in use" on macOS/Linux
      print('Socket Error: Address already in use. Is the server already running?');
    }
    exit(1);
  }
}

