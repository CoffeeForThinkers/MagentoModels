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

    def upsert_category_int_attribute(self, category_id, att_name, att_value, store_id=0):
        record = \
            self.get_one_record(
                'upsert_category_int_attribute',
                category_id, att_name, att_value, store_id)

        record['affected'] = int(record['affected'])

        return record
