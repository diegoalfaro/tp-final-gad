EXTENSION = imagecomparer
MODULE_big = imagecomparer
DATA = imagecomparer--0.0.1.sql
OBJS = colors.o imagecomparer.o
SHLIB_LINK = -lgd
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
