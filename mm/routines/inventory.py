import logging

import mm.routines
import mm.exceptions

_LOGGER = logging.getLogger(__name__)


class InventoryRoutines(mm.routines.RoutinesBase):
    noun = 'inventory'

    def update_stock(self, sku, stock, force_in_stock):
        record = \
            self.get_one_record(
                'update_stock',
                sku, stock, int(force_in_stock))

        return record

    def get_all_stock(self):
        rows = \
            self.call(
                'get_stock',
                None)
        
        return rows

    def get_stock(self, sku):
        rows = \
            self.call(
                'get_stock',
                sku)

        rows = list(rows)
        if not rows:
            raise mm.exceptions.NoRowsError()

        return rows[0]
