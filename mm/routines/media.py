import logging

import mm.routines

_LOGGER = logging.getLogger(__name__)


class MediaRoutines(mm.routines.RoutinesBase):
    noun = 'media'

    def get_product_from_image(self, image_file):
        rows = \
            self.call(
                'get_product_from_image',
                image_file)

        return rows
