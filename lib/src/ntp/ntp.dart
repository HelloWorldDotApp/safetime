import 'dart:io';

import 'ntp.message.dart';
import 'ntp.server.dart';
import '../safetime.error.dart';

class NTP {
  /// Get current NTP time
  static Future<DateTime> now() async {
    final localTime = DateTime.now();
    final timeout = Duration(seconds: 10);

    int offset = await Future.any(
      NTPServer.values.map(
        (e) => _getNtpOffset(
          lookUpAddress: e.url,
          localTime: localTime,
          timeout: timeout,
        ),
      ),
    );

    return localTime.add(Duration(microseconds: offset));
  }

  /// Return NTP delay in microseconds
  static Future<int> _getNtpOffset({
    required String lookUpAddress,
    int port = 123,
    DateTime? localTime,
    Duration? timeout,
  }) async {
    late final List<InternetAddress> addresses;
    try {
      addresses = await InternetAddress.lookup(lookUpAddress);
    } catch (error) {
      throw SafeTimeNtpError(
        code: 'ntp_request_failed',
        server: lookUpAddress,
        cause: error,
      );
    }

    if (addresses.isEmpty) {
      throw SafeTimeNtpError(
        code: 'ntp_address_not_resolved',
        server: lookUpAddress,
      );
    }

    final serverAddress = addresses.first;
    final clientAddress = serverAddress.type == InternetAddressType.IPv6
        ? InternetAddress.anyIPv6
        : InternetAddress.anyIPv4;

    late final RawDatagramSocket datagramSocket;
    try {
      datagramSocket = await RawDatagramSocket.bind(clientAddress, 0);
    } catch (error) {
      throw SafeTimeNtpError(
        code: 'ntp_request_failed',
        server: lookUpAddress,
        cause: error,
      );
    }

    final ntpMessage = NTPMessage();
    final buffer = ntpMessage.toByteArray();
    final time = localTime ?? DateTime.now();
    ntpMessage.encodeTimestamp(
      buffer,
      40,
      (time.microsecondsSinceEpoch / 1000000.0) + ntpMessage.timeToUtc,
    );

    datagramSocket.send(buffer, serverAddress, port);

    Datagram? packet;

    receivePacket(RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        packet = datagramSocket.receive();
      }
      return packet != null;
    }

    try {
      if (timeout != null) {
        await datagramSocket.timeout(timeout).firstWhere(receivePacket);
      } else {
        await datagramSocket.firstWhere(receivePacket);
      }
    } catch (error) {
      throw SafeTimeNtpError(
        code: 'ntp_request_failed',
        server: lookUpAddress,
        cause: error,
      );
    } finally {
      datagramSocket.close();
    }

    if (packet == null) {
      throw SafeTimeNtpError(
        code: 'ntp_empty_response',
        server: lookUpAddress,
      );
    }

    final offset = _parseData(packet!.data, DateTime.now());

    // Check if the offset is within a reasonable range
    // 12 years in micoseconds
    const maxOffset = 12 * 365 * 24 * 60 * 60 * 1000000;

    if (offset.abs() > maxOffset) {
      throw SafeTimeNtpError(
        code: 'ntp_offset_out_of_range',
        server: lookUpAddress,
      );
    }

    return offset;
  }

  /// Parse data from datagram socket.
  static int _parseData(List<int> data, DateTime time) {
    final ntpMessage = NTPMessage(data);

    // Calculate destination timestamp in seconds since NTP epoch
    final destinationTimestamp =
        (time.microsecondsSinceEpoch / 1000000.0) + ntpMessage.timeToUtc;

    // Calculate local clock offset in seconds
    final localClockOffset =
        ((ntpMessage.receiveTimestamp - ntpMessage.originateTimestamp) +
                (ntpMessage.transmitTimestamp - destinationTimestamp)) /
            2;

    // Convert offset to microseconds and return as an integer
    return (localClockOffset * 1000000).toInt();
  }
}
