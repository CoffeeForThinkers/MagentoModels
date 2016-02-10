import os
import logging

_LOGGER = logging.getLogger(__name__)

DSN = os.environ['BM_DB_DSN']
_LOGGER.debug("Effective DSN: %s", DSN)

CONNECTION_RECYCLE_FREQUENCY_S = 7200
