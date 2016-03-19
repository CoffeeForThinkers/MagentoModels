import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class SalesInventoryRoutines(mm.routines.RoutinesBase):
    noun = 'sales_inventory'

    def get_sales_inventory_changes(self, start_timestamp, stop_timestamp):
        records = \
            self.call(
                'get_sales_inventory_changes',
                start_timestamp, stop_timestamp)
        
        for record in records:
            record['quantity'] = int(record['quantity'])

            yield record

    def get_sales_with_items(self, start_timestamp, stop_timestamp):
        records = \
            self.call(
                'get_sales_with_items',
                start_timestamp, stop_timestamp)

        for record in records:
            record['quantity'] = int(record['quantity'])
            record['order_number'] = int(record['order_number'])

            yield record

