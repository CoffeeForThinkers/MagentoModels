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
            record['quantity'] = float(record['quantity'])

            yield record
