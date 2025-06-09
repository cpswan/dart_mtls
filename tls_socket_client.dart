// tls_socket_client.dart
import 'dart:io';
import 'dart:convert'; // For utf8 encoding/decoding

void main() async {
  // Define certificate and key paths for the client
  final clientCertPath = 'certs/client.noext.crt';
  // originally final clientCertPath = 'certs/client.crt';
  final clientKeyPath = 'certs/client.key';
  final caCertPath = 'certs/ca.crt'; // CA certificate to trust the server's certificate

  final serverHost = 'atsign.test';
  final serverPort = 8443;

  SecureSocket? socket; // Declare socket outside try-catch for finally block

  try {
    // 1. Create a SecurityContext for the client
    final securityContext = SecurityContext()
      // Load the client's certificate chain (public key)
      ..useCertificateChain(clientCertPath)
      // Load the client's private key
      ..usePrivateKey(clientKeyPath)
      // Set trusted certificates for the server. This tells the client which CA
      // it trusts to sign the server's certificate.
      ..setTrustedCertificates(caCertPath);
      // Make sure to use TLS 1.3
      //..minimumTlsProtocolVersion = TlsProtocolVersion.tls1_3;

    // 2. Connect to the server using SecureSocket.connect
    print('Connecting to ${serverHost}:${serverPort} with mTLS...');
    socket = await SecureSocket.connect(
      serverHost,
      serverPort,
      context: securityContext,
      onBadCertificate: (X509Certificate certificate) {
        // This callback is invoked if the server's certificate is invalid
        // based on the trusted CAs in the context. Return true to accept anyway (NOT RECOMMENDED).
        // For self-signed CA, this should not be triggered if 'ca.crt' is correctly set.
        print('WARNING: Server certificate is invalid: ${certificate.subject}');
        return false; // Do not accept bad certificates
      },
      supportedProtocols: ['tls-test'], // Optional: ALPN protocol negotiation
    );

    print('Successfully connected to mTLS TLS Socket Server.');

    // Verify server certificate details (from the client's perspective)
    final serverX509 = socket.peerCertificate;
    if (serverX509 != null) {
      print('  Server Certificate Subject: ${serverX509.subject}');
      print('  Server Certificate Issuer: ${serverX509.issuer}');
    }

    // Listen for data from the server
    socket.listen(
      (List<int> data) {
        final message = utf8.decode(data).trim();
        print('  Received from server: "$message"');
      },
      onDone: () {
        print('  Server disconnected.');
        socket?.destroy();
      },
      onError: (error) {
        print('  Error on socket: $error');
        socket?.destroy();
      },
    );

    // Send messages to the server
    print('Sending a message to the server...');
    socket.write('Hello, server from Dart client!\n');
    await Future.delayed(Duration(seconds: 1)); // Give server time to respond

    print('Sending another message...');
    socket.write('How are you today?\n');
    await Future.delayed(Duration(seconds: 1));

    print('Closing client connection...');
    await socket.close(); // Close the client socket gracefully
  } catch (e) {
    print('Error connecting or communicating with server: $e');
    if (e is HandshakeException) {
      print('TLS Handshake failed. This often indicates a certificate issue (e.g., server did not present a trusted cert, or client cert was rejected by server).');
    } else if (e is TlsException) {
      print('TLS Error: ${e.message}');
    } else if (e is FileSystemException) {
      print('File System Error: Could not read certificate/key file. Check paths and permissions.');
    } else if (e is SocketException && e.osError?.errorCode == 61) { // Error code 61 is "Connection refused" on macOS/Linux
      print('Socket Error: Connection refused. Is the server running and listening on the correct port?');
    }
    exit(1);
  } finally {
    socket?.destroy(); // Ensure socket is destroyed in case of errors
  }
}

