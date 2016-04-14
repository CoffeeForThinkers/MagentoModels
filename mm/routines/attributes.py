import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class AttributeRoutines(mm.routines.RoutinesBase):
    noun = 'attributes'

    def get_attribute_options(self, att_name, store_id):
        rows = \
            self.call(
                'get_attribute_options',
                att_name, int(store_id))

        return rows

    def add_attribute_option(self, att_name, att_value, store_id):
        record = \
            self.get_one_record(
                'add_attribute_option',
                att_name, att_value, int(store_id))

        return record
