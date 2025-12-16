{ ... }:
{
  # Syslogd service to collect caddy logs and forward to edgeware for justice
  services.rsyslogd = {
    enable = true;
    extraConfig = ''
      # Load the file input module
      module(load="imfile" PollingInterval="10")

      # Monitor Caddy cal.danmail.me access log
      input(type="imfile"
            File="/var/log/caddy/access-cal.danmail.me.log"
            Tag="caddy-cal"
            Severity="info"
            Facility="local6")

      # Monitor Caddy blog.danmail.me access log
      input(type="imfile"
            File="/var/log/caddy/access-blog.danmail.me.log"
            Tag="caddy-blog"
            Severity="info"
            Facility="local6")

      # Forward to remote rsyslog server
      *.* @@100.91.153.13:514
    '';
  };

}
