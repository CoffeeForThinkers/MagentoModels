import logging

import mm.routines
import mm.exceptions

_LOGGER = logging.getLogger(__name__)


class CatalogInventoryStockItemRoutines(mm.routines.RoutinesBase):
    noun = 'catalog_inventory_stock_item'

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
