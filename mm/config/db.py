import os
import logging

_LOGGER = logging.getLogger(__name__)

DSN = os.environ['MM_DB_DSN']
_LOGGER.debug("Effective DSN: %s", DSN)

CONNECTION_RECYCLE_FREQUENCY_S = 299
CONNECTION_POOL_SIZE = 20
