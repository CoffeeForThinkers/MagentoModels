import logging

import mm.routines
import mm.exceptions

_LOGGER = logging.getLogger(__name__)


class CategoryRoutines(mm.routines.RoutinesBase):
    noun = 'category'

    def get_listing(self, store_id=None):
        rows = \
            self.call(
                'get_category_listing',
                store_id)

        return rows
