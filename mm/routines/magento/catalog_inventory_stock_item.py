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
