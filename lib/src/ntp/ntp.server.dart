enum NTPServer {
  tencent('ntp.tencent.com'),
  aliyun('ntp.aliyun.com'),
  google('time.google.com'),
  cloudflare('time.cloudflare.com'),
  microsoft('time.windows.com'),
  apple('time.apple.com'),
  pool('pool.ntp.org'),
  timeDns('clock.isc.org'),
  ;

  final String url;
  const NTPServer(this.url);
}
