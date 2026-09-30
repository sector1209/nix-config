{
  secrets,
  ...
}:
{
  # Syslogd service to collect caddy logs and forward to edgeware for justice
  services.rsyslogd = {
    enable = true;
    extraConfig = ''
      # Load the file input module
      module(load="imfile" PollingInterval="10")

      # Monitor Caddy cal.${secrets.domainName} access log
      input(type="imfile"
            File="/var/log/caddy/access-cal.${secrets.domainName}.log"
            Tag="caddy-cal"
            Severity="info"
            Facility="local6")

      # Monitor Caddy blog.${secrets.domainName} access log
      input(type="imfile"
            File="/var/log/caddy/access-blog-backend.log"
            Tag="caddy-blog"
            Severity="info"
            Facility="local6")

      # Forward to remote rsyslog server
      *.* @@100.91.153.13:514
    '';
  };

}
