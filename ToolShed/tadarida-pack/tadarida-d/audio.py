"""
Classes for Waveform Audio File Format (.wav or .wave)
"""

from galaxy.datatypes import data
from galaxy.datatypes.metadata import MetadataElement
from galaxy.util import nice_size

import os
import logging
from galaxy.datatypes import binary

log = logging.getLogger(__name__)

class Wav( binary.Binary ):
    """
        Waveform Audio File Format 
    """
    file_ext = "wav"
    # edam_format = "format_3000"
    # edam_data = "data_0924"

    def set_peek( self, dataset, is_multi_byte=False ):
        if not dataset.dataset.purged:
            dataset.peek = "Binary wave sequence file"
            dataset.blurb = nice_size( dataset.get_size() )
        else:
            dataset.peek = 'file does not exist'
            dataset.blurb = 'file purged from disk'

    def display_peek( self, dataset ):
        try:
            return dataset.peek
        except:
            return "Binary wave sequence file (%s)" % ( nice_size( dataset.get_size() ) )

binary.Binary.register_unsniffable_binary_ext("wav")
