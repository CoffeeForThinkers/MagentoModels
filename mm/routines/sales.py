import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class SalesRoutines(mm.routines.RoutinesBase):
    noun = 'sales'

    def get_sales_inventory_changes(self, start_timestamp, 
                                    stop_timestamp=None):
        records = \
            self.call(
                'get_sales_inventory_changes',
                start_timestamp, stop_timestamp)
        
        for record in records:
            record['quantity'] = float(record['quantity'])

            yield record

    def get_sales_with_items_with_start_order_id(self, start_order_id):
        records = \
            self.call(
                'get_sales_with_items_with_start_order_id',
                start_order_id)

        for record in records:
            record['quantity'] = float(record['quantity'])

            yield record
