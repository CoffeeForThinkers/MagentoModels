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
        legal_inputs = set([None, True, False])
        message = "Not a valid input value for '{0}'. Use: {1}"

        assert type(store_id) is int or store_id is None, message.format('store_id', 'None or int')
        assert is_active in legal_inputs, message.format('is_active', 'None, True or False')
        assert is_visible in legal_inputs, message.format('is_visible', 'None, True or False')

        rows = \
            self.call(
                'get_configurable_associated_products',
                store_id,
                is_active,
                is_visible)

        return rows
