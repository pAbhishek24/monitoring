select NAME, VALUE from V$SYSSTAT where NAME in ('user commits','user calls');
quit;

