import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class SalesRoutines(mm.routines.RoutinesBase):
    noun = 'sales'

    def get_sales_and_customer_info_with_times(self, start_timestamp, 
                                               stop_timestamp=None):
        records = \
            self.call(
                'get_sales_and_customer_info_with_times',
                start_timestamp, stop_timestamp)
        
        for record in records:
            record['quantity'] = float(record['quantity'])

            yield record

    def get_sales_and_customer_info_with_start_order_id(self, start_order_id):
        records = \
            self.call(
                'get_sales_and_customer_info_with_start_order_id',
                start_order_id)

        for record in records:
            record['quantity'] = float(record['quantity'])

            yield record
