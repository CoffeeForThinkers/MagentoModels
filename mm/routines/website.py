import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class WebsiteRoutines(mm.routines.RoutinesBase):
    noun = 'website'

    def get_default_website(self):
        record = \
            self.get_one_record(
                'get_default_website')
        
        return record
