import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class CatalogInventoryStockItemRoutines(mm.routines.RoutinesBase):
    noun = 'catalog_inventory_stock_item'

    def get_stock(self, sku=None):
        record = \
            self.call(
                'get_stock',
                sku)
        
        return record

    def update_stock(self, sku, stock, force_in_stock):
        record = \
            self.get_one_record(
                'update_stock',
                sku, stock, int(force_in_stock))

        return record

    def get_stock(self, sku):
        record = \
            self.get_one_record(
                'get_stock',
                sku)

        return record
