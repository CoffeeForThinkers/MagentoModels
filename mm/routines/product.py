import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class ProductRoutines(mm.routines.RoutinesBase):
    noun = 'product'

    def update_enum_product_attribute(self, sku, att_name, att_value):
        record = \
            self.get_one_record(
                'update_enum_product_attribute',
                sku, att_name, att_value)

        return record
