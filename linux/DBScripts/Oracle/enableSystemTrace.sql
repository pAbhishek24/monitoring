ALTER SYSTEM SET max_dump_file_size=UNLIMITED scope=memory;
ALTER SYSTEM SET EVENTS '10046 trace name context forever, level 1';
quit;

