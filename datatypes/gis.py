"""
GIS classes
"""

import data, logging
from galaxy.datatypes.metadata import MetadataElement
from galaxy.datatypes import metadata
from galaxy.datatypes.sniff import *
from galaxy import eggs
from xml import GenericXml
import urllib2
import subprocess

# The base class for all GIS data
class GIS( data.Data ):
    """Climate data"""

    def __init__( self, **kwd ):
        data.Data.__init__( self, **kwd )

    def set_peek( self, dataset, is_multi_byte=False ):
        """Set the peek and blurb text"""
        if not dataset.dataset.purged:
            dataset.peek = 'climate data'
            dataset.blurb = 'data'
        else:
            dataset.peek = 'file does not exist'
            dataset.blurb = 'file purged from disk'
    def get_mime( self ):
        """Returns the mime type of the datatype"""
        return 'application/octet-stream'


# The shapefile class
class Shapefile( GIS ):
    """Shapefile data"""
    #http://en.wikipedia.org/wiki/Shapefile

    MetadataElement( name="base_name", desc="base name for all transformed versions of this dataset", default="Shapefile", readonly=True, set_in_upload=True)

    composite_type = 'auto_primary_file'
    file_ext = "shp"
    allow_datatype_change = False

    def __init__( self, **kwd ):
        GIS.__init__( self, **kwd )
        self.add_composite_file( '%s.shp',  description = 'Geometry File', substitute_name_with_metadata = 'base_name',is_binary = True, optional = False )
        self.add_composite_file( '%s.shx',  description = 'Geometry index File', substitute_name_with_metadata = 'base_name',is_binary = True, optional = False )
        self.add_composite_file( '%s.dbf',  description = 'Database File', substitute_name_with_metadata = 'base_name',is_binary = True, optional = False )

    def generate_primary_file( self, dataset = None ):
        rval = ['<html><head><title>Files for Composite Dataset (%s)</title></head><p/>This composite dataset is composed of the following files:<p/><ul>' % ( self.file_ext ) ]
        for composite_name, composite_file in self.get_composite_files( dataset = dataset ).iteritems():
            opt_text = ''
            if composite_file.optional:
                opt_text = ' (optional)'
            rval.append( '<li><a href="%s">%s</a>%s' % ( composite_name, composite_name, opt_text ) )
        rval.append( '</ul></html>' )
        return "\n".join( rval )

    def sniff( self, filename ):
        # The first 4 bytes of any grib file is 'GRIB', and the file is binary.

        try:
            header = open( filename,"rb" )
            tag = header.read(4)
            if binascii.b2a_hex(tag) == "0000270a":
                return True
            return False
        except:
            return False

    def set_peek( self, dataset, is_multi_byte=False ):
        """Set the peek and blurb text"""
        if not dataset.dataset.purged:
            dataset.peek = 'shapefile data'
            dataset.blurb = 'data'
        else:
            dataset.peek = 'file does not exist'
            dataset.blurb = 'file purged from disk'
    def get_mime( self ):
        """Returns the mime type of the datatype"""
        return 'application/octet-stream'




