import logging

import bm.routines

_LOGGER = logging.getLogger(__name__)


class WebsiteRoutines(bm.routines.RoutinesBase):
    noun = 'website'

    def get_default_website(self):
        record = \
            self.get_one_record(
                'get_sales_inventory_changes',
                start_timestamp, stop_timestamp)
        
        return record
