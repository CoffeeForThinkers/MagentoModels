import os
import logging

import sqlalchemy
import sqlalchemy.pool

import mm.config.db

_LOGGER = logging.getLogger(__name__)

# We've had have persistent issues with persistent connections in the pool. It
# ends-up preventing us from doing DB changes. For now, we disable it.
_ENABLE_POOL = bool(int(os.environ.get('MM_USE_POOL', '1')))

def _get_engine():
    kwargs = {}
    if _ENABLE_POOL is False:
        _LOGGER.debug("Disabling DB connection-pool.")
        kwargs['poolclass'] = sqlalchemy.pool.NullPool

    engine = \
        sqlalchemy.create_engine(
            mm.config.db.DSN,
            pool_recycle=\
                mm.config.db.CONNECTION_RECYCLE_FREQUENCY_S,
            pool_size=\
                mm.config.db.CONNECTION_POOL_SIZE,
            **kwargs)

    return engine

ENGINE = _get_engine()
