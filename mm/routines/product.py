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

    def get_configurable_associated_products(self, store_id=None, is_active=None, is_visible=None):
        rows = \
            self.call(
                'get_configurable_associated_products',
                store_id,
                int(is_active) if isinstance(is_active, bool) else None,
                int(is_visible) if isinstance(is_visible, bool) else None)

        return rows
